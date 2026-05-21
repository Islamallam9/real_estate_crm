import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_image_upload.dart';
import '../../domain/errors/property_exception.dart';
import '../models/property_model.dart';

abstract interface class PropertiesRemoteDataSource {
  Future<PropertyModel> createProperty({
    required String companyId,
    required PropertyModel property,
    List<PropertyImageUpload> newImages = const [],
  });

  Future<PropertyModel> updateProperty({
    required String companyId,
    required PropertyModel property,
    List<PropertyImageUpload> newImages = const [],
    List<String> removedImageStoragePaths = const [],
  });

  Future<void> deactivateProperty({
    required String companyId,
    required String propertyId,
    required String updatedBy,
  });

  Stream<List<PropertyModel>> watchProperties({
    required String companyId,
    int limit = 50,
  });
}

class FirestorePropertiesRemoteDataSource
    implements PropertiesRemoteDataSource {
  FirestorePropertiesRemoteDataSource({
    FirebaseFirestore? firestore,
    firebase_storage.FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? firebase_storage.FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final firebase_storage.FirebaseStorage _storage;

  static const int _maxImageBytes = 5 * 1024 * 1024;
  static const Duration _imageUploadTimeout = Duration(seconds: 90);
  static const Duration _firestoreWriteTimeout = Duration(seconds: 30);

  @override
  Future<PropertyModel> createProperty({
    required String companyId,
    required PropertyModel property,
    List<PropertyImageUpload> newImages = const [],
  }) async {
    _ensureSameCompany(companyId: companyId, property: property);
    final uploadedStoragePaths = <String>[];

    try {
      final collection = _propertiesCollection(companyId);
      final document = property.id.isEmpty
          ? collection.doc()
          : collection.doc(property.id);
      final baseProperty = PropertyModel.fromEntity(
        property.copyWith(id: document.id, companyId: companyId),
      );
      final uploadedImages = await _uploadImages(
        companyId: companyId,
        propertyId: document.id,
        images: newImages,
      );
      uploadedStoragePaths.addAll(uploadedImages.map((image) => image.path));
      final imageUrls = <String>[
        ...baseProperty.imageUrls,
        ...uploadedImages.map((image) => image.url),
      ];
      final imageStoragePaths = <String>[
        ...baseProperty.imageStoragePaths,
        ...uploadedImages.map((image) => image.path),
      ];
      final coverImageUrl = _resolveCoverImageUrl(
        preferredCoverImageUrl: baseProperty.coverImageUrl,
        imageUrls: imageUrls,
      );
      final propertyToSave = PropertyModel.fromEntity(
        baseProperty.copyWith(
          imageUrls: imageUrls,
          coverImageUrl: coverImageUrl,
          clearCoverImageUrl: coverImageUrl == null,
          imageStoragePaths: imageStoragePaths,
        ),
      );

      await document
          .set(propertyToSave.toFirestore())
          .timeout(_firestoreWriteTimeout);
      return propertyToSave;
    } on PropertyException {
      await _deleteStoragePaths(uploadedStoragePaths);
      rethrow;
    } on FirebaseException catch (error) {
      await _deleteStoragePaths(uploadedStoragePaths);
      throw PropertyException(_mapFirebaseError(error));
    } catch (_) {
      await _deleteStoragePaths(uploadedStoragePaths);
      throw const PropertyException(
        'Unable to create property. Please try again.',
      );
    }
  }

  @override
  Future<PropertyModel> updateProperty({
    required String companyId,
    required PropertyModel property,
    List<PropertyImageUpload> newImages = const [],
    List<String> removedImageStoragePaths = const [],
  }) async {
    _ensureSameCompany(companyId: companyId, property: property);
    final uploadedStoragePaths = <String>[];

    try {
      final document = _propertiesCollection(companyId).doc(property.id);
      final uploadedImages = await _uploadImages(
        companyId: companyId,
        propertyId: property.id,
        images: newImages,
      );
      uploadedStoragePaths.addAll(uploadedImages.map((image) => image.path));

      final imageUrls = <String>[
        ...property.imageUrls,
        ...uploadedImages.map((image) => image.url),
      ];
      final imageStoragePaths = <String>[
        ...property.imageStoragePaths,
        ...uploadedImages.map((image) => image.path),
      ];
      final coverImageUrl = _resolveCoverImageUrl(
        preferredCoverImageUrl: property.coverImageUrl,
        imageUrls: imageUrls,
      );
      final propertyToSave = PropertyModel.fromEntity(
        property.copyWith(
          imageUrls: imageUrls,
          coverImageUrl: coverImageUrl,
          clearCoverImageUrl: coverImageUrl == null,
          imageStoragePaths: imageStoragePaths,
        ),
      );

      await document
          .update(propertyToSave.toFirestore())
          .timeout(_firestoreWriteTimeout);
      await _deleteStoragePaths(removedImageStoragePaths);
      final snapshot = await document.get().timeout(_firestoreWriteTimeout);
      return PropertyModel.fromFirestore(snapshot);
    } on PropertyException {
      await _deleteStoragePaths(uploadedStoragePaths);
      rethrow;
    } on FirebaseException catch (error) {
      await _deleteStoragePaths(uploadedStoragePaths);
      throw PropertyException(_mapFirebaseError(error));
    } catch (_) {
      await _deleteStoragePaths(uploadedStoragePaths);
      throw const PropertyException(
        'Unable to update property. Please try again.',
      );
    }
  }

  @override
  Future<void> deactivateProperty({
    required String companyId,
    required String propertyId,
    required String updatedBy,
  }) async {
    try {
      final document = _propertiesCollection(companyId).doc(propertyId);
      await document.update({
        'status': propertyStatusToValue(PropertyStatus.inactive),
        'updatedAt': Timestamp.now(),
        'updatedBy': updatedBy,
      });
    } on FirebaseException catch (error) {
      throw PropertyException(_mapFirebaseError(error));
    } catch (_) {
      throw const PropertyException(
        'Unable to deactivate property. Please try again.',
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

  Future<List<_UploadedPropertyImage>> _uploadImages({
    required String companyId,
    required String propertyId,
    required List<PropertyImageUpload> images,
  }) async {
    final uploadedImages = <_UploadedPropertyImage>[];

    for (final image in images) {
      _validateImage(image);

      final storagePath = _propertyImageStoragePath(
        companyId: companyId,
        propertyId: propertyId,
        fileName: image.fileName,
      );

      final storageReference = _storage.ref().child(storagePath);

      try {
        await storageReference
            .putData(
          image.bytes,
          firebase_storage.SettableMetadata(
            contentType: image.contentType,
          ),
        )
            .timeout(_imageUploadTimeout);

        final downloadUrl = await storageReference
            .getDownloadURL()
            .timeout(_firestoreWriteTimeout);

        uploadedImages.add(
          _UploadedPropertyImage(url: downloadUrl, path: storagePath),
        );
      } on TimeoutException {
        throw const PropertyException(AppErrorMessages.unableToConnect);
      }
    }

    return uploadedImages;
  }

  void _validateImage(PropertyImageUpload image) {
    if (!image.contentType.toLowerCase().startsWith('image/')) {
      throw const PropertyException(AppErrorMessages.propertyImageInvalidType);
    }

    if (image.bytes.lengthInBytes > _maxImageBytes) {
      throw const PropertyException(AppErrorMessages.propertyImageTooLarge);
    }
  }

  Future<void> _deleteStoragePaths(List<String> storagePaths) async {
    final uniquePaths = storagePaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toSet();

    for (final path in uniquePaths) {
      try {
        await _storage.ref().child(path).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') {
          continue;
        }
      } catch (_) {
        continue;
      }
    }
  }
}

class _UploadedPropertyImage {
  const _UploadedPropertyImage({required this.url, required this.path});

  final String url;
  final String path;
}

void _ensureSameCompany({
  required String companyId,
  required PropertyModel property,
}) {
  if (companyId.isEmpty || property.companyId != companyId) {
    throw const PropertyException(AppErrorMessages.permissionDenied);
  }
}

String? _resolveCoverImageUrl({
  required String? preferredCoverImageUrl,
  required List<String> imageUrls,
}) {
  final trimmedCover = preferredCoverImageUrl?.trim();
  if (trimmedCover != null &&
      trimmedCover.isNotEmpty &&
      imageUrls.contains(trimmedCover)) {
    return trimmedCover;
  }

  for (final imageUrl in imageUrls) {
    final trimmedUrl = imageUrl.trim();
    if (trimmedUrl.isNotEmpty) {
      return trimmedUrl;
    }
  }

  return null;
}

String _propertyImageStoragePath({
  required String companyId,
  required String propertyId,
  required String fileName,
}) {
  final safeFileName = _safeFileName(fileName);
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  return 'companies/$companyId/properties/$propertyId/images/${timestamp}_$safeFileName';
}

String _safeFileName(String fileName) {
  final normalized = fileName.split(RegExp(r'[\\/]+')).last.trim();
  final safe = normalized.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (safe.isEmpty) {
    return 'property_image.jpg';
  }
  return safe;
}

String _mapFirebaseError(FirebaseException error) {
  switch (error.code) {
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return AppErrorMessages.unableToConnect;
    case 'permission-denied':
    case 'unauthorized':
      return AppErrorMessages.permissionDenied;
    case 'unauthenticated':
      return AppErrorMessages.unauthenticated;
    case 'not-found':
    case 'object-not-found':
      return AppErrorMessages.notFound;
    case 'cancelled':
      return AppErrorMessages.cancelled;
    default:
      return 'Unable to load properties. Please try again.';
  }
}
