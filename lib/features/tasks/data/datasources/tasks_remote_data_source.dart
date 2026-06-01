import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/crm_task.dart';
import '../../domain/errors/task_exception.dart';
import '../../domain/entities/task_related_record_option.dart';
import '../models/crm_task_model.dart';

abstract interface class TasksRemoteDataSource {
  Future<CrmTaskModel> createTask({
    required String companyId,
    required CrmTaskModel task,
  });

  Future<CrmTaskModel> updateTask({
    required String companyId,
    required CrmTaskModel task,
  });

  Stream<CrmTaskModel?> watchTask({
    required String companyId,
    required String taskId,
  });

  Stream<List<CrmTaskModel>> watchTasks({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    int limit = 40,
  });

  Future<List<TaskRelatedRecordOption>> getRelatedRecordOptions({
    required String companyId,
    required TaskRelatedType type,
    String? assignedTo,
    String? managerId,
    String? teamId,
    int limit = 30,
  });
}

class FirestoreTasksRemoteDataSource implements TasksRemoteDataSource {
  FirestoreTasksRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<CrmTaskModel> createTask({
    required String companyId,
    required CrmTaskModel task,
  }) async {
    _ensureSameCompany(companyId: companyId, task: task);
    try {
      final collection = _tasksCollection(companyId);
      final document = task.id.isEmpty ? collection.doc() : collection.doc(task.id);
      final now = DateTime.now();
      final taskToSave = CrmTaskModel(
        id: document.id,
        companyId: companyId,
        title: task.title,
        description: task.description,
        assignedTo: task.assignedTo,
        assignedToName: task.assignedToName,
        assignedToEmail: task.assignedToEmail,
        teamId: task.teamId,
        teamName: task.teamName,
        managerId: task.managerId,
        managerName: task.managerName,
        relatedType: task.relatedType,
        relatedId: task.relatedId,
        relatedTitle: task.relatedTitle,
        relatedSubtitle: task.relatedSubtitle,
        dueDate: task.dueDate,
        status: task.status,
        priority: task.priority,
        createdAt: task.createdAt ?? now,
        updatedAt: now,
        createdBy: task.createdBy,
        updatedBy: task.updatedBy,
        isActive: true,
      );
      await document.set(taskToSave.toFirestore());
      return taskToSave;
    } on TaskException {
      rethrow;
    } on FirebaseException catch (error) {
      throw TaskException(_mapFirestoreError(error));
    } catch (_) {
      throw const TaskException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<CrmTaskModel> updateTask({
    required String companyId,
    required CrmTaskModel task,
  }) async {
    _ensureSameCompany(companyId: companyId, task: task);
    try {
      final document = _tasksCollection(companyId).doc(task.id);
      final snapshot = await document.get();
      if (!snapshot.exists) {
        throw const TaskException(AppErrorMessages.notFound);
      }

      final existingTask = CrmTaskModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, task: existingTask);
      await document.update({
        'title': task.title,
        'description': task.description,
        'assignedTo': task.assignedTo,
        'assignedToName': task.assignedToName,
        'assignedToEmail': task.assignedToEmail,
        'teamId': task.teamId,
        'teamName': task.teamName,
        'managerId': task.managerId,
        'managerName': task.managerName,
        'relatedType': task.relatedType.name,
        'relatedId': task.relatedId,
        'relatedTitle': task.relatedTitle,
        'relatedSubtitle': task.relatedSubtitle,
        'dueDate': task.dueDate == null ? null : Timestamp.fromDate(task.dueDate!),
        'status': task.status.name,
        'priority': task.priority.name,
        'updatedAt': Timestamp.now(),
        'updatedBy': task.updatedBy,
      });
      final updatedSnapshot = await document.get();
      return CrmTaskModel.fromFirestore(updatedSnapshot);
    } on TaskException {
      rethrow;
    } on FirebaseException catch (error) {
      throw TaskException(_mapFirestoreError(error));
    } catch (_) {
      throw const TaskException(AppErrorMessages.unknown);
    }
  }

  @override
  Stream<CrmTaskModel?> watchTask({
    required String companyId,
    required String taskId,
  }) {
    return _tasksCollection(companyId).doc(taskId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      final task = CrmTaskModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, task: task);
      return task;
    }).handleError((Object error) {
      if (error is FirebaseException) {
        throw TaskException(_mapFirestoreError(error));
      }
      throw const TaskException(AppErrorMessages.unknown);
    });
  }

  @override
  Stream<List<CrmTaskModel>> watchTasks({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    int limit = 40,
  }) {
    Query<Map<String, dynamic>> query = _tasksCollection(companyId).where(
      'isActive',
      isEqualTo: true,
    );

    if (teamId != null && teamId.trim().isNotEmpty) {
      query = query.where('teamId', isEqualTo: teamId.trim());
    } else if (managerId != null && managerId.trim().isNotEmpty) {
      query = query.where('managerId', isEqualTo: managerId.trim());
    } else if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: assignedTo.trim());
    }

    return query.limit(limit).snapshots().map((snapshot) {
      final tasks = snapshot.docs.map((document) {
        final task = CrmTaskModel.fromFirestore(document);
        _ensureSameCompany(companyId: companyId, task: task);
        return task;
      }).toList();
      tasks.sort((a, b) {
        final aDate = a.dueDate ?? a.updatedAt ?? a.createdAt ?? DateTime(9999);
        final bDate = b.dueDate ?? b.updatedAt ?? b.createdAt ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
      return tasks;
    }).handleError((Object error) {
      if (error is FirebaseException) {
        throw TaskException(_mapFirestoreError(error));
      }
      throw const TaskException(AppErrorMessages.unknown);
    });
  }

  @override
  Future<List<TaskRelatedRecordOption>> getRelatedRecordOptions({
    required String companyId,
    required TaskRelatedType type,
    String? assignedTo,
    String? managerId,
    String? teamId,
    int limit = 30,
  }) async {
    try {
      switch (type) {
        case TaskRelatedType.lead:
          return _getLeadOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            teamId: teamId,
            limit: limit,
          );
        case TaskRelatedType.client:
          return _getClientOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            teamId: teamId,
            limit: limit,
          );
        case TaskRelatedType.property:
          return _getPropertyOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            teamId: teamId,
            limit: limit,
          );
        case TaskRelatedType.deal:
          return _getDealOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            teamId: teamId,
            limit: limit,
          );
        case TaskRelatedType.general:
          return const [];
      }
    } on FirebaseException catch (error) {
      throw TaskException(_mapFirestoreError(error));
    } catch (_) {
      throw const TaskException(AppErrorMessages.unknown);
    }
  }

  Future<List<TaskRelatedRecordOption>> _getLeadOptions({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyLeads(companyId))
        .where('isArchived', isEqualTo: false);
    if (teamId != null && teamId.trim().isNotEmpty) {
      query = query.where('teamId', isEqualTo: teamId.trim());
    } else if (managerId != null && managerId.trim().isNotEmpty) {
      query = query.where('managerId', isEqualTo: managerId.trim());
    } else if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: assignedTo.trim());
    }

    final snapshot = await query.limit(limit).get();
    final options = <TaskRelatedRecordOption>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      if ((data['companyId'] as String? ?? '') != companyId) {
        throw const TaskException(AppErrorMessages.permissionDenied);
      }
      if (data['isArchived'] as bool? ?? false) {
        continue;
      }
      options.add(
        TaskRelatedRecordOption(
          id: document.id,
          type: TaskRelatedType.lead,
          title: data['fullName'] as String? ?? '',
          subtitle:
              (data['phone'] as String?) ?? (data['status'] as String?) ?? '',
        ),
      );
    }
    options.sort((a, b) => a.title.compareTo(b.title));
    return options;
  }

  Future<List<TaskRelatedRecordOption>> _getClientOptions({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyClients(companyId))
        .where('isActive', isEqualTo: true)
        .where('isArchived', isEqualTo: false);
    if (teamId != null && teamId.trim().isNotEmpty) {
      query = query.where('teamId', isEqualTo: teamId.trim());
    } else if (managerId != null && managerId.trim().isNotEmpty) {
      query = query.where('managerId', isEqualTo: managerId.trim());
    } else if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: assignedTo.trim());
    }

    final snapshot = await query.limit(limit).get();
    final options = <TaskRelatedRecordOption>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      if ((data['companyId'] as String? ?? '') != companyId) {
        throw const TaskException(AppErrorMessages.permissionDenied);
      }
      if ((data['isActive'] as bool? ?? true) == false ||
          (data['isArchived'] as bool? ?? false)) {
        continue;
      }
      options.add(
        TaskRelatedRecordOption(
          id: document.id,
          type: TaskRelatedType.client,
          title: data['fullName'] as String? ?? '',
          subtitle:
              (data['phone'] as String?) ??
              (data['preferredLocation'] as String?) ??
              '',
        ),
      );
    }
    options.sort((a, b) => a.title.compareTo(b.title));
    return options;
  }

  Future<List<TaskRelatedRecordOption>> _getPropertyOptions({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(
      FirebasePaths.companyProperties(companyId),
    );
    final snapshot = await query.limit(limit).get();
    final options = <TaskRelatedRecordOption>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      if ((data['companyId'] as String? ?? '') != companyId) {
        throw const TaskException(AppErrorMessages.permissionDenied);
      }
      if ((data['status'] as String? ?? '') == 'inactive' ||
          (data['isArchived'] as bool? ?? false)) {
        continue;
      }
      final location = data['location'] as String? ?? '';
      final price = data['price'];
      options.add(
        TaskRelatedRecordOption(
          id: document.id,
          type: TaskRelatedType.property,
          title: data['title'] as String? ?? '',
          subtitle: location.isNotEmpty ? location : price?.toString() ?? '',
        ),
      );
    }
    options.sort((a, b) => a.title.compareTo(b.title));
    return options;
  }

  Future<List<TaskRelatedRecordOption>> _getDealOptions({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyDeals(companyId))
        .where('isActive', isEqualTo: true)
        .where('isArchived', isEqualTo: false);
    if (teamId != null && teamId.trim().isNotEmpty) {
      query = query.where('teamId', isEqualTo: teamId.trim());
    } else if (managerId != null && managerId.trim().isNotEmpty) {
      query = query.where('managerId', isEqualTo: managerId.trim());
    } else if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: assignedTo.trim());
    }
    final snapshot = await query.limit(limit).get();
    final options = <TaskRelatedRecordOption>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      if ((data['companyId'] as String? ?? '') != companyId) {
        throw const TaskException(AppErrorMessages.permissionDenied);
      }
      if ((data['isActive'] as bool? ?? true) == false ||
          (data['isArchived'] as bool? ?? false)) {
        continue;
      }
      final clientName = data['clientName'] as String? ?? '';
      final propertyTitle = data['propertyTitle'] as String? ?? '';
      final stage = data['stage'] as String? ?? '';
      final location = data['propertyLocation'] as String? ?? '';
      final title = clientName.trim().isEmpty
          ? propertyTitle
          : propertyTitle.trim().isEmpty
              ? clientName
              : '$clientName - $propertyTitle';
      final subtitle = [
        if (stage.trim().isNotEmpty) stage,
        if (location.trim().isNotEmpty) location,
      ].join(' - ');
      options.add(
        TaskRelatedRecordOption(
          id: document.id,
          type: TaskRelatedType.deal,
          title: title,
          subtitle: subtitle,
        ),
      );
    }
    options.sort((a, b) => a.title.compareTo(b.title));
    return options;
  }

  CollectionReference<Map<String, dynamic>> _tasksCollection(String companyId) {
    return _firestore.collection(FirebasePaths.companyTasks(companyId));
  }
}

void _ensureSameCompany({
  required String companyId,
  required CrmTaskModel task,
}) {
  if (companyId.isEmpty || task.companyId != companyId) {
    throw const TaskException(AppErrorMessages.permissionDenied);
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
