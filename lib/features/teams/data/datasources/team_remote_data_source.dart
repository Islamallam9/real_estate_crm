import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../users/data/models/user_profile_model.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/entities/team.dart';
import '../../domain/errors/team_exception.dart';
import '../models/team_model.dart';

abstract interface class TeamRemoteDataSource {
  Stream<List<TeamModel>> watchTeams({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  });

  Stream<List<UserProfileModel>> watchTeamUsers({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  });

  Future<void> createTeam({
    required String companyId,
    required String name,
    required String description,
    required UserProfile manager,
    required String actorUid,
  });

  Future<void> updateTeam({
    required Team team,
    required String name,
    required String description,
    required UserProfile manager,
    required bool isActive,
    required String actorUid,
  });

  Future<void> setTeamActiveStatus({
    required Team team,
    required bool isActive,
    required String actorUid,
  });

  Future<void> addUserToTeam({
    required Team team,
    required UserProfile user,
    required String actorUid,
  });

  Future<void> removeUserFromTeam({
    required UserProfile user,
    required String actorUid,
  });

  Future<void> backfillTeamAssignedRecordSnapshots({
    required Team team,
    required String actorUid,
  });
}

class FirestoreTeamRemoteDataSource implements TeamRemoteDataSource {
  FirestoreTeamRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<TeamModel>> watchTeams({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(
      FirebasePaths.companyTeams(companyId),
    );

    if (role == UserRole.manager) {
      query = query.where('managerId', isEqualTo: currentUserId);
    }

    return query.snapshots().map((snapshot) {
      final teams = snapshot.docs.map(TeamModel.fromFirestore).where((team) {
        return team.companyId == companyId;
      }).toList()
        ..sort((a, b) {
          final activeCompare = b.isActive.toString().compareTo(
            a.isActive.toString(),
          );
          if (activeCompare != 0) {
            return activeCompare;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return teams;
    });
  }

  @override
  Stream<List<UserProfileModel>> watchTeamUsers({
    required String companyId,
    required UserRole role,
    required String currentUserId,
  }) {
    final usersCollection = _firestore
        .collection(FirebasePaths.companyUsers(companyId))
        .where('isActive', isEqualTo: true);

    if (role == UserRole.manager) {
      return _watchManagerTeamUsers(
        companyId: companyId,
        currentUserId: currentUserId,
      );
    }

    return _watchUsersQuery(usersCollection, companyId);
  }

  Stream<List<UserProfileModel>> _watchManagerTeamUsers({
    required String companyId,
    required String currentUserId,
  }) async* {
    final teamsSnapshot = await _firestore
        .collection(FirebasePaths.companyTeams(companyId))
        .where('managerId', isEqualTo: currentUserId)
        .where('isActive', isEqualTo: true)
        .get();

    final teamIds = teamsSnapshot.docs
        .map((doc) {
          final id = (doc.data()['id'] as String?)?.trim();
          return id != null && id.isNotEmpty ? id : doc.id;
        })
        .where((id) => id.trim().isNotEmpty)
        .take(10)
        .toList(growable: false);

    final usersCollection = _firestore
        .collection(FirebasePaths.companyUsers(companyId))
        .where('isActive', isEqualTo: true);

    final streams = <Stream<List<UserProfileModel>>>[
      _watchUsersQuery(
        usersCollection.where('managerId', isEqualTo: currentUserId),
        companyId,
      ),
    ];

    for (final teamId in teamIds) {
      streams.add(
        _watchUsersQuery(
          usersCollection.where('teamId', isEqualTo: teamId),
          companyId,
        ),
      );
    }

    yield* _combineUserStreams(streams);
  }

  Stream<List<UserProfileModel>> _combineUserStreams(
    List<Stream<List<UserProfileModel>>> streams,
  ) {
    final controller = StreamController<List<UserProfileModel>>();
    final latest = List<List<UserProfileModel>>.filled(
      streams.length,
      const <UserProfileModel>[],
    );
    final subscriptions = <StreamSubscription<List<UserProfileModel>>>[];

    void emitCombined() {
      if (controller.isClosed) {
        return;
      }
      final byUid = <String, UserProfileModel>{};
      for (final users in latest) {
        for (final user in users) {
          byUid[user.uid] = user;
        }
      }
      final merged = byUid.values.toList()
        ..sort((a, b) {
          final roleCompare = RoleConstants.toValue(a.role).compareTo(
            RoleConstants.toValue(b.role),
          );
          if (roleCompare != 0) {
            return roleCompare;
          }
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        });
      controller.add(merged);
    }

    controller.onListen = () {
      if (streams.isEmpty) {
        controller.add(const <UserProfileModel>[]);
        return;
      }
      for (var index = 0; index < streams.length; index += 1) {
        final streamIndex = index;
        subscriptions.add(
          streams[streamIndex].listen(
            (users) {
              latest[streamIndex] = users;
              emitCombined();
            },
            onError: controller.addError,
          ),
        );
      }
    };

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  Stream<List<UserProfileModel>> _watchUsersQuery(
    Query<Map<String, dynamic>> query,
    String companyId,
  ) async* {
    try {
      await for (final snapshot in query.snapshots()) {
        final users = snapshot.docs.map(UserProfileModel.fromFirestore).where((
          user,
        ) {
          return user.companyId == companyId;
        }).toList()
          ..sort((a, b) {
            final roleCompare = RoleConstants.toValue(a.role).compareTo(
              RoleConstants.toValue(b.role),
            );
            if (roleCompare != 0) {
              return roleCompare;
            }
            return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
          });
        yield users;
      }
    } on FirebaseException catch (error) {
      throw TeamException(_mapFirebaseTeamError(error));
    }
  }

  @override
  Future<void> createTeam({
    required String companyId,
    required String name,
    required String description,
    required UserProfile manager,
    required String actorUid,
  }) async {
    await _ensureManagerAvailable(
      companyId: companyId,
      managerId: manager.uid,
      excludeTeamId: null,
    );

    final now = Timestamp.now();
    final teamRef = _firestore.collection(FirebasePaths.companyTeams(companyId)).doc();
    await teamRef.set({
      'id': teamRef.id,
      'companyId': companyId,
      'name': name,
      'description': description,
      'managerId': manager.uid,
      'managerName': manager.fullName,
      'managerEmail': manager.email,
      'isActive': true,
      'memberCount': 0,
      'createdAt': now,
      'createdBy': actorUid,
      'updatedAt': now,
      'updatedBy': actorUid,
    });
  }

  @override
  Future<void> updateTeam({
    required Team team,
    required String name,
    required String description,
    required UserProfile manager,
    required bool isActive,
    required String actorUid,
  }) async {
    if (isActive) {
      await _ensureManagerAvailable(
        companyId: team.companyId,
        managerId: manager.uid,
        excludeTeamId: team.id,
      );
    }

    final now = Timestamp.now();
    final teamRef = _firestore
        .collection(FirebasePaths.companyTeams(team.companyId))
        .doc(team.id);
    final update = {
      'name': name,
      'description': description,
      'managerId': manager.uid,
      'managerName': manager.fullName,
      'managerEmail': manager.email,
      'isActive': isActive,
      'updatedAt': now,
      'updatedBy': actorUid,
    };
    await teamRef.update(update);

    if (team.managerId != manager.uid ||
        team.managerName != manager.fullName ||
        team.name != name) {
      await _updateTeamMemberSnapshots(
        companyId: team.companyId,
        teamId: team.id,
        teamName: name,
        managerId: manager.uid,
        managerName: manager.fullName,
        actorUid: actorUid,
      );
      await backfillTeamAssignedRecordSnapshots(
        team: team,
        actorUid: actorUid,
      );
    }
  }

  @override
  Future<void> setTeamActiveStatus({
    required Team team,
    required bool isActive,
    required String actorUid,
  }) {
    return _firestore
        .collection(FirebasePaths.companyTeams(team.companyId))
        .doc(team.id)
        .update({
          'isActive': isActive,
          'updatedAt': Timestamp.now(),
          'updatedBy': actorUid,
        });
  }

  @override
  Future<void> addUserToTeam({
    required Team team,
    required UserProfile user,
    required String actorUid,
  }) async {
    if (user.role != UserRole.salesAgent && user.role != UserRole.marketing) {
      throw const TeamException(TeamErrorMessages.ineligibleMember);
    }
    if (!user.isActive) {
      throw const TeamException(TeamErrorMessages.inactiveUser);
    }
    if (user.companyId != team.companyId) {
      throw const TeamException(TeamErrorMessages.companyMismatch);
    }
    if (!team.isActive) {
      throw const TeamException(TeamErrorMessages.inactiveTeam);
    }

    try {
      await _functions.httpsCallable('assignUserToTeam').call({
        'companyId': team.companyId,
        'teamId': team.id,
        'uid': user.uid,
      });
    } on FirebaseFunctionsException catch (error) {
      throw TeamException(_mapTeamFunctionError(error));
    } on FirebaseException catch (error) {
      throw TeamException(_mapFirebaseTeamError(error));
    }
  }

  @override
  Future<void> removeUserFromTeam({
    required UserProfile user,
    required String actorUid,
  }) async {
    try {
      await _functions.httpsCallable('removeUserFromTeam').call({
        'companyId': user.companyId,
        'uid': user.uid,
      });
    } on FirebaseFunctionsException catch (error) {
      throw TeamException(_mapTeamFunctionError(error));
    } on FirebaseException catch (error) {
      throw TeamException(_mapFirebaseTeamError(error));
    }
  }

  @override
  Future<void> backfillTeamAssignedRecordSnapshots({
    required Team team,
    required String actorUid,
  }) async {
    try {
      await _functions.httpsCallable('backfillTeamAssignedRecordSnapshots').call({
        'companyId': team.companyId,
        'teamId': team.id,
      });
    } on FirebaseFunctionsException catch (error) {
      throw TeamException(_mapTeamFunctionError(error));
    } on FirebaseException catch (error) {
      throw TeamException(_mapFirebaseTeamError(error));
    }
  }

  Future<void> _ensureManagerAvailable({
    required String companyId,
    required String managerId,
    required String? excludeTeamId,
  }) async {
    final managerDoc = await _firestore
        .doc(FirebasePaths.companyUser(companyId: companyId, uid: managerId))
        .get();
    final manager = managerDoc.data();
    if (manager == null ||
        manager['role'] != RoleConstants.manager ||
        manager['isActive'] != true) {
      throw const TeamException(TeamErrorMessages.managerUnavailable);
    }

    final existing = await _firestore
        .collection(FirebasePaths.companyTeams(companyId))
        .where('managerId', isEqualTo: managerId)
        .where('isActive', isEqualTo: true)
        .get();
    final hasOtherTeam = existing.docs.any((doc) => doc.id != excludeTeamId);
    if (hasOtherTeam) {
      throw const TeamException(TeamErrorMessages.managerAlreadyHasTeam);
    }
  }

  Future<void> _updateTeamMemberSnapshots({
    required String companyId,
    required String teamId,
    required String teamName,
    required String managerId,
    required String managerName,
    required String actorUid,
  }) async {
    final users = await _firestore
        .collection(FirebasePaths.companyUsers(companyId))
        .where('teamId', isEqualTo: teamId)
        .get();
    var batch = _firestore.batch();
    var count = 0;
    for (final doc in users.docs) {
      batch.update(doc.reference, {
        'teamName': teamName,
        'managerId': managerId,
        'managerName': managerName,
        'updatedAt': Timestamp.now(),
        'updatedBy': actorUid,
      });
      count += 1;
      if (count == 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }

}

String _mapTeamFunctionError(FirebaseFunctionsException error) {
  final message = (error.message ?? '').toLowerCase();
  switch (error.code) {
    case 'permission-denied':
      return TeamErrorMessages.permissionDenied;
    case 'unauthenticated':
      return TeamErrorMessages.unauthenticated;
    case 'not-found':
      if (message.contains('team')) {
        return TeamErrorMessages.teamNotFound;
      }
      if (message.contains('user')) {
        return TeamErrorMessages.userNotFound;
      }
      return TeamErrorMessages.unknown;
    case 'failed-precondition':
      if (message.contains('team')) {
        return TeamErrorMessages.inactiveTeam;
      }
      if (message.contains('user')) {
        return TeamErrorMessages.inactiveUser;
      }
      if (message.contains('company')) {
        return TeamErrorMessages.companyInactive;
      }
      return TeamErrorMessages.invalidInput;
    case 'invalid-argument':
      if (message.contains('sales') || message.contains('marketing')) {
        return TeamErrorMessages.ineligibleMember;
      }
      return TeamErrorMessages.invalidInput;
    case 'unavailable':
    case 'deadline-exceeded':
      return TeamErrorMessages.connection;
    case 'aborted':
      return TeamErrorMessages.changed;
    default:
      return TeamErrorMessages.unknown;
  }
}

String _mapFirebaseTeamError(FirebaseException error) {
  switch (error.code) {
    case 'permission-denied':
      return TeamErrorMessages.permissionDenied;
    case 'unauthenticated':
      return TeamErrorMessages.unauthenticated;
    case 'not-found':
      return TeamErrorMessages.userNotFound;
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return TeamErrorMessages.connection;
    case 'aborted':
      return TeamErrorMessages.changed;
    default:
      return TeamErrorMessages.unknown;
  }
}
