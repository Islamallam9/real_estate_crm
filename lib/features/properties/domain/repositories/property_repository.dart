import '../entities/property.dart';

abstract interface class PropertyRepository {
  Future<Property> createProperty({
    required String companyId,
    required Property property,
  });

  Future<Property> updateProperty({
    required String companyId,
    required Property property,
  });

  Stream<List<Property>> watchProperties({
    required String companyId,
    int limit,
  });
}
