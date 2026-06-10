import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/errors/client_exception.dart';
import '../models/client_model.dart';

abstract interface class ClientsRemoteDataSource {
  Future<ClientModel> createClient({
    required String companyId,
    required ClientModel client,
  });

  Future<ClientModel> updateClient({
    required String companyId,
    required ClientModel client,
  });

  Future<void> assignClient({
    required String companyId,
    required String clientId,
    required String assignedTo,
    required String assignedToName,
    required String assignedToEmail,
    required String teamId,
    required String teamName,
    required String managerId,
    required String managerName,
    required String updatedBy,
  });

  Future<void> archiveClient({
    required String companyId,
    required String clientId,
    required String updatedBy,
    String reason = '',
  });

  Future<void> restoreClient({
    required String companyId,
    required String clientId,
    required String updatedBy,
  });

  Stream<ClientModel?> watchClient({
    required String companyId,
    required String clientId,
  });

  Stream<List<ClientModel>> watchClients({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    int limit = 30,
  });
}

class FirestoreClientsRemoteDataSource implements ClientsRemoteDataSource {
  FirestoreClientsRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<ClientModel> createClient({
    required String companyId,
    required ClientModel client,
  }) async {
    _ensureSameCompany(companyId: companyId, client: client);
    try {
      final collection = _clientsCollection(companyId);
      final document = client.id.isEmpty
          ? collection.doc()
          : collection.doc(client.id);
      final now = DateTime.now();
      final clientToSave = ClientModel(
        id: document.id,
        companyId: companyId,
        fullName: client.fullName,
        phone: client.phone,
        email: client.email,
        budgetMin: client.budgetMin,
        budgetMax: client.budgetMax,
        preferredLocation: client.preferredLocation,
        preferredPropertyType: client.preferredPropertyType,
        notes: client.notes,
        assignedTo: client.assignedTo,
        assignedToName: client.assignedToName,
        assignedToEmail: client.assignedToEmail,
        teamId: client.teamId,
        teamName: client.teamName,
        managerId: client.managerId,
        managerName: client.managerName,
        isActive: true,
        createdAt: client.createdAt ?? now,
        updatedAt: now,
        createdBy: client.createdBy,
        updatedBy: client.updatedBy,
        isArchived: false,
      );
      await document.set(clientToSave.toFirestore());
      return clientToSave;
    } on ClientException {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw ClientException(_mapFunctionsError(error));
    } on FirebaseException catch (error) {
      throw ClientException(_mapFirestoreError(error));
    } catch (_) {
      throw const ClientException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<ClientModel> updateClient({
    required String companyId,
    required ClientModel client,
  }) async {
    _ensureSameCompany(companyId: companyId, client: client);
    try {
      final document = _clientsCollection(companyId).doc(client.id);
      final snapshot = await document.get(
        const GetOptions(source: Source.server),
      );
      if (!snapshot.exists) {
        throw const ClientException(AppErrorMessages.notFound);
      }

      final existingClient = ClientModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, client: existingClient);
      if (kDebugMode) {
        debugPrint(
          'MasarDebug feature=clients operation=updateClient '
          'scope=${_safeClientScopeLabel(existingClient)} '
          'fields=fullName,phone,email,budgetMin,budgetMax,'
          'preferredLocation,preferredPropertyType,notes,updatedAt,updatedBy',
        );
      }
      await document.update({
        'fullName': client.fullName,
        'phone': client.phone,
        'email': client.email,
        'budgetMin': client.budgetMin,
        'budgetMax': client.budgetMax,
        'preferredLocation': client.preferredLocation,
        'preferredPropertyType': client.preferredPropertyType,
        'notes': client.notes,
        'updatedAt': Timestamp.now(),
        'updatedBy': client.updatedBy,
      });
      final updatedSnapshot = await document.get(
        const GetOptions(source: Source.server),
      );
      return ClientModel.fromFirestore(updatedSnapshot);
    } on ClientException {
      rethrow;
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'MasarDebug feature=clients operation=updateClient '
          'firebaseException code=${error.code} '
          'message=${error.message ?? ''}',
        );
      }
      throw ClientException(_mapFirestoreError(error));
    } catch (_) {
      throw const ClientException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<void> assignClient({
    required String companyId,
    required String clientId,
    required String assignedTo,
    required String assignedToName,
    required String assignedToEmail,
    required String teamId,
    required String teamName,
    required String managerId,
    required String managerName,
    required String updatedBy,
  }) async {
    try {
      final callable = _functions.httpsCallable('assignClientRecord');
      await callable.call(<String, Object?>{
        'companyId': companyId,
        'clientId': clientId,
        'assignedTo': assignedTo.trim(),
      });
    } on ClientException {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw ClientException(_mapFunctionsError(error));
    } on FirebaseException catch (error) {
      throw ClientException(_mapFirestoreError(error));
    } catch (_) {
      throw const ClientException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<void> archiveClient({
    required String companyId,
    required String clientId,
    required String updatedBy,
    String reason = '',
  }) async {
    try {
      await _functions.httpsCallable('archiveCrmRecord').call(<String, Object?>{
        'companyId': companyId,
        'module': 'clients',
        'recordId': clientId,
        'reason': reason,
      });
    } on FirebaseFunctionsException catch (error) {
      throw ClientException(_mapFunctionsError(error));
    } on FirebaseException catch (error) {
      throw ClientException(_mapFirestoreError(error));
    } catch (_) {
      throw const ClientException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<void> restoreClient({
    required String companyId,
    required String clientId,
    required String updatedBy,
  }) async {
    try {
      await _functions.httpsCallable('restoreCrmRecord').call(<String, Object?>{
        'companyId': companyId,
        'module': 'clients',
        'recordId': clientId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw ClientException(_mapFunctionsError(error));
    } on FirebaseException catch (error) {
      throw ClientException(_mapFirestoreError(error));
    } catch (_) {
      throw const ClientException(AppErrorMessages.unknown);
    }
  }

  @override
  Stream<ClientModel?> watchClient({
    required String companyId,
    required String clientId,
  }) {
    return _clientsCollection(companyId).doc(clientId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        return null;
      }
      final client = ClientModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, client: client);
      return client;
    }).handleError((Object error) {
      if (error is FirebaseException) {
        throw ClientException(_mapFirestoreError(error));
      }
      throw const ClientException(AppErrorMessages.unknown);
    });
  }

  @override
  Stream<List<ClientModel>> watchClients({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    int limit = 30,
  }) {
    Query<Map<String, dynamic>> query = _clientsCollection(companyId);
    if (archiveFilter == ArchiveFilter.archived) {
      query = query.where('isArchived', isEqualTo: true);
    } else if (archiveFilter == ArchiveFilter.active) {
      query = query
          .where('isActive', isEqualTo: true)
          .where('isArchived', isEqualTo: false);
    }

    if (teamId != null && teamId.trim().isNotEmpty) {
      query = query.where('teamId', isEqualTo: teamId.trim());
    } else if (managerId != null && managerId.trim().isNotEmpty) {
      query = query.where('managerId', isEqualTo: managerId.trim());
    } else if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: assignedTo.trim());
    }

    final fallbackQuery = query;
    final orderedQuery = query
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);

    return _watchClientModels(
      companyId: companyId,
      archiveFilter: archiveFilter,
      primaryQuery: orderedQuery,
      fallbackQuery: fallbackQuery,
      limit: limit,
    );
  }

  Stream<List<ClientModel>> _watchClientModels({
    required String companyId,
    required ArchiveFilter archiveFilter,
    required Query<Map<String, dynamic>> primaryQuery,
    required Query<Map<String, dynamic>> fallbackQuery,
    required int limit,
  }) async* {
    try {
      await for (final snapshot in primaryQuery.limit(limit).snapshots()) {
        yield _clientsFromSnapshot(
          snapshot,
          companyId: companyId,
          archiveFilter: archiveFilter,
          sortLocally: false,
        );
      }
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') {
        throw ClientException(_mapFirestoreError(error));
      }
      if (kDebugMode) {
        debugPrint(
          'MasarClientsQueryFallback: code=${error.code} '
          'message=${error.message ?? ""}',
        );
      }
      try {
        await for (final snapshot in fallbackQuery.limit(limit).snapshots()) {
          yield _clientsFromSnapshot(
            snapshot,
            companyId: companyId,
            archiveFilter: archiveFilter,
            sortLocally: true,
          );
        }
      } on FirebaseException catch (fallbackError) {
        throw ClientException(_mapFirestoreError(fallbackError));
      } catch (_) {
        throw const ClientException(AppErrorMessages.unknown);
      }
    } catch (_) {
      throw const ClientException(AppErrorMessages.unknown);
    }
  }

  List<ClientModel> _clientsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    required String companyId,
    required ArchiveFilter archiveFilter,
    required bool sortLocally,
  }) {
    final clients = snapshot.docs.map((document) {
      final client = ClientModel.fromFirestore(document);
      _ensureSameCompany(companyId: companyId, client: client);
      return client;
    }).where((client) {
      if (archiveFilter == ArchiveFilter.archived) {
        return client.isArchived || !client.isActive;
      }
      if (archiveFilter == ArchiveFilter.active) {
        return !client.isArchived && client.isActive;
      }
      return true;
    }).toList();

    if (sortLocally) {
      clients.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime(0);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
    }
    return clients;
  }

  CollectionReference<Map<String, dynamic>> _clientsCollection(
    String companyId,
  ) {
    return _firestore.collection(FirebasePaths.companyClients(companyId));
  }
}

String _mapFunctionsError(FirebaseFunctionsException error) {
  switch (error.code) {
    case 'unavailable':
    case 'deadline-exceeded':
      return AppErrorMessages.unableToConnect;
    case 'permission-denied':
      return AppErrorMessages.permissionDenied;
    case 'unauthenticated':
      return AppErrorMessages.unauthenticated;
    case 'not-found':
      return AppErrorMessages.notFound;
    default:
      return error.message ?? AppErrorMessages.unknown;
  }
}

void _ensureSameCompany({
  required String companyId,
  required ClientModel client,
}) {
  if (companyId.isEmpty || client.companyId != companyId) {
    throw const ClientException(AppErrorMessages.permissionDenied);
  }
}

String _mapFirestoreError(FirebaseException error) {
  switch (error.code) {
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return AppErrorMessages.unableToConnect;
    case 'permission-denied':
      return AppErrorMessages.permissionDenied;
    case 'unauthenticated':
      return AppErrorMessages.unauthenticated;
    case 'not-found':
      return AppErrorMessages.notFound;
    case 'cancelled':
      return AppErrorMessages.cancelled;
    default:
      return AppErrorMessages.unknown;
  }
}

String _safeClientScopeLabel(ClientModel client) {
  final hasAssignedUser = client.assignedTo.trim().isNotEmpty;
  final hasManager = client.managerId.trim().isNotEmpty;
  final hasTeam = client.teamId.trim().isNotEmpty;
  if (hasAssignedUser && hasManager && hasTeam) {
    return 'assigned-manager-team';
  }
  if (hasTeam) {
    return 'team';
  }
  if (hasManager) {
    return 'manager';
  }
  if (hasAssignedUser) {
    return 'assigned';
  }
  return 'unscoped';
}
