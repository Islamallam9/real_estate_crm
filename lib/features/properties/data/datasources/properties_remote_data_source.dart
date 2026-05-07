import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/errors/property_exception.dart';
import '../models/property_model.dart';

abstract interface class PropertiesRemoteDataSource {
  Future<PropertyModel> createProperty({
    required String companyId,
    required PropertyModel property,
  });

  Future<PropertyModel> updateProperty({
    required String companyId,
    required PropertyModel property,
  });

  Stream<List<PropertyModel>> watchProperties({
    required String companyId,
    int limit,
  });
}

class FirestorePropertiesRemoteDataSource
    implements PropertiesRemoteDataSource {
  FirestorePropertiesRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<PropertyModel> createProperty({
    required String companyId,
    required PropertyModel property,
  }) async {
    _ensureSameCompany(companyId: companyId, property: property);
    try {
      final collection = _propertiesCollection(companyId);
      final document = property.id.isEmpty
          ? collection.doc()
          : collection.doc(property.id);
      final propertyToSave = PropertyModel.fromEntity(
        property.copyWith(id: document.id, companyId: companyId),
      );
      await document.set(propertyToSave.toFirestore());
      return propertyToSave;
    } on PropertyException {
      rethrow;
    } on FirebaseException catch (error) {
      throw PropertyException(_mapFirestoreError(error));
    } catch (_) {
      throw const PropertyException(
        'Unable to create property. Please try again.',
      );
    }
  }

  @override
  Future<PropertyModel> updateProperty({
    required String companyId,
    required PropertyModel property,
  }) async {
    _ensureSameCompany(companyId: companyId, property: property);
    try {
      final document = _propertiesCollection(companyId).doc(property.id);
      await document.update(property.toFirestore());
      final snapshot = await document.get();
      return PropertyModel.fromFirestore(snapshot);
    } on PropertyException {
      rethrow;
    } on FirebaseException catch (error) {
      throw PropertyException(_mapFirestoreError(error));
    } catch (_) {
      throw const PropertyException(
        'Unable to update property. Please try again.',
      );
    }
  }

  @override
  Stream<List<PropertyModel>> watchProperties({
    required String companyId,
    int limit = 30,
  }) {
    return _propertiesCollection(companyId).limit(limit).snapshots().map((
      snapshot,
    ) {
      final properties = snapshot.docs.map((document) {
        final property = PropertyModel.fromFirestore(document);
        _ensureSameCompany(companyId: companyId, property: property);
        return property;
      }).toList();

      properties.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return properties;
    });
  }

  CollectionReference<Map<String, dynamic>> _propertiesCollection(
    String companyId,
  ) {
    return _firestore.collection(FirebasePaths.companyProperties(companyId));
  }
}

void _ensureSameCompany({
  required String companyId,
  required PropertyModel property,
}) {
  if (companyId.isEmpty || property.companyId != companyId) {
    throw const PropertyException(AppErrorMessages.permissionDenied);
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
      return 'Unable to load properties. Please try again.';
  }
}
