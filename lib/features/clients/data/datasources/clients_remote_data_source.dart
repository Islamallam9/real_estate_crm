import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> archiveClient({
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
    int limit,
  });
}

class FirestoreClientsRemoteDataSource implements ClientsRemoteDataSource {
  FirestoreClientsRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
        isActive: true,
        createdAt: client.createdAt ?? now,
        updatedAt: now,
        createdBy: client.createdBy,
        updatedBy: client.updatedBy,
      );
      await document.set(clientToSave.toFirestore());
      return clientToSave;
    } on ClientException {
      rethrow;
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
      final snapshot = await document.get();
      if (!snapshot.exists) {
        throw const ClientException(AppErrorMessages.notFound);
      }

      final existingClient = ClientModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, client: existingClient);
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
      final updatedSnapshot = await document.get();
      return ClientModel.fromFirestore(updatedSnapshot);
    } on ClientException {
      rethrow;
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
  }) async {
    try {
      final document = _clientsCollection(companyId).doc(clientId);
      await document.update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
        'updatedBy': updatedBy,
      });
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
    int limit = 30,
  }) {
    Query<Map<String, dynamic>> query = _clientsCollection(companyId).where(
      'isActive',
      isEqualTo: true,
    );

    if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: assignedTo.trim());
    }

    return query.limit(limit).snapshots().map((snapshot) {
      final clients = snapshot.docs.map((document) {
        final client = ClientModel.fromFirestore(document);
        _ensureSameCompany(companyId: companyId, client: client);
        return client;
      }).toList();

      clients.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime(0);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      return clients;
    }).handleError((Object error) {
      if (error is FirebaseException) {
        throw ClientException(_mapFirestoreError(error));
      }
      throw const ClientException(AppErrorMessages.unknown);
    });
  }

  CollectionReference<Map<String, dynamic>> _clientsCollection(
    String companyId,
  ) {
    return _firestore.collection(FirebasePaths.companyClients(companyId));
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
