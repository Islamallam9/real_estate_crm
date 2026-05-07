import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/errors/task_exception.dart';
import '../models/crm_task_model.dart';

abstract interface class TasksRemoteDataSource {
  Future<CrmTaskModel> createTask({
    required String companyId,
    required CrmTaskModel task,
  });

  Stream<List<CrmTaskModel>> watchTasks({
    required String companyId,
    String? assignedTo,
    int limit,
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
        relatedType: task.relatedType,
        relatedId: task.relatedId,
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
  Stream<List<CrmTaskModel>> watchTasks({
    required String companyId,
    String? assignedTo,
    int limit = 40,
  }) {
    Query<Map<String, dynamic>> query = _tasksCollection(companyId).where(
      'isActive',
      isEqualTo: true,
    );

    if (assignedTo != null && assignedTo.trim().isNotEmpty) {
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
