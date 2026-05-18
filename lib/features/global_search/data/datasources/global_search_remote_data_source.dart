import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/routing/route_names.dart';
import '../../domain/entities/global_search_result.dart';

abstract interface class GlobalSearchRemoteDataSource {
  Future<List<GlobalSearchResult>> search({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    required String query,
    required bool includeUsers,
    int limitPerModule,
  });
}

class FirestoreGlobalSearchRemoteDataSource
    implements GlobalSearchRemoteDataSource {
  FirestoreGlobalSearchRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<GlobalSearchResult>> search({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    required String query,
    required bool includeUsers,
    int limitPerModule = 40,
  }) async {
    final cleanQuery = _normalize(query);
    if (companyId.trim().isEmpty ||
        currentUserId.trim().isEmpty ||
        cleanQuery.length < 2) {
      return const [];
    }

    final searches = <Future<List<GlobalSearchResult>>>[
      _searchLeads(companyId, currentUserId, role, cleanQuery, limitPerModule),
      _searchClients(companyId, currentUserId, role, cleanQuery, limitPerModule),
      _searchProperties(
        companyId,
        currentUserId,
        role,
        cleanQuery,
        limitPerModule,
      ),
      _searchDeals(companyId, currentUserId, role, cleanQuery, limitPerModule),
      _searchTasks(companyId, currentUserId, role, cleanQuery, limitPerModule),
      if (includeUsers)
        _searchUsers(companyId, currentUserId, role, cleanQuery, limitPerModule),
    ];

    final groups = await Future.wait(
      searches.map((search) async {
        try {
          return await search;
        } catch (_) {
          return const <GlobalSearchResult>[];
        }
      }),
    );
    final results = groups.expand((group) => group).toList()
      ..sort((a, b) => a.module.index.compareTo(b.module.index));
    return results;
  }

  Future<List<GlobalSearchResult>> _searchLeads(
    String companyId,
    String currentUserId,
    UserRole role,
    String query,
    int limit,
  ) async {
    Query<Map<String, dynamic>> firestoreQuery = _scopedQuery(
      _companyCollection(companyId, 'leads'),
      role: role,
      currentUserId: currentUserId,
    );
    final snapshot = await firestoreQuery.limit(limit).get();
    return snapshot.docs
        .where((doc) => doc.data()['isArchived'] != true)
        .where((doc) => _matches(doc.data(), query, const [
              'fullName',
              'phone',
              'email',
              'assignedToName',
              'source',
              'status',
            ]))
        .take(8)
        .map((doc) {
      final data = doc.data();
      final title = _field(data, 'fullName', fallback: doc.id);
      return GlobalSearchResult(
        id: doc.id,
        module: GlobalSearchModule.leads,
        title: title,
        subtitle: _joinParts([
          _field(data, 'phone'),
          _field(data, 'email'),
        ]),
        status: _field(data, 'status'),
        owner: _field(data, 'assignedToName'),
        route: RouteNames.leadDetails(doc.id),
      );
    }).toList();
  }

  Future<List<GlobalSearchResult>> _searchClients(
    String companyId,
    String currentUserId,
    UserRole role,
    String query,
    int limit,
  ) async {
    Query<Map<String, dynamic>> firestoreQuery = _scopedQuery(
      _companyCollection(companyId, 'clients')
          .where('isActive', isEqualTo: true),
      role: role,
      currentUserId: currentUserId,
    );
    final snapshot = await firestoreQuery.limit(limit).get();
    return snapshot.docs
        .where((doc) => _matches(doc.data(), query, const [
              'fullName',
              'phone',
              'email',
              'assignedToName',
            ]))
        .take(8)
        .map((doc) {
      final data = doc.data();
      return GlobalSearchResult(
        id: doc.id,
        module: GlobalSearchModule.clients,
        title: _field(data, 'fullName', fallback: doc.id),
        subtitle: _joinParts([
          _field(data, 'phone'),
          _field(data, 'email'),
        ]),
        owner: _field(data, 'assignedToName'),
        route: RouteNames.clientDetails(doc.id),
      );
    }).toList();
  }

  Future<List<GlobalSearchResult>> _searchProperties(
    String companyId,
    String currentUserId,
    UserRole role,
    String query,
    int limit,
  ) async {
    Query<Map<String, dynamic>> firestoreQuery = _scopedQuery(
      _companyCollection(companyId, 'properties'),
      role: role,
      currentUserId: currentUserId,
    );
    final snapshot = await firestoreQuery.limit(limit).get();
    return snapshot.docs
        .where((doc) => _field(doc.data(), 'status') != 'inactive')
        .where((doc) => _matches(doc.data(), query, const [
              'title',
              'location',
              'compound',
              'ownerName',
              'ownerPhone',
              'assignedToName',
              'status',
            ]))
        .take(8)
        .map((doc) {
      final data = doc.data();
      return GlobalSearchResult(
        id: doc.id,
        module: GlobalSearchModule.properties,
        title: _field(data, 'title', fallback: doc.id),
        subtitle: _joinParts([
          _field(data, 'location'),
          _field(data, 'compound'),
        ]),
        status: _field(data, 'status'),
        owner: _field(data, 'assignedToName'),
        route: RouteNames.propertyDetails(doc.id),
      );
    }).toList();
  }

  Future<List<GlobalSearchResult>> _searchDeals(
    String companyId,
    String currentUserId,
    UserRole role,
    String query,
    int limit,
  ) async {
    Query<Map<String, dynamic>> firestoreQuery = _scopedQuery(
      _companyCollection(companyId, 'deals').where('isActive', isEqualTo: true),
      role: role,
      currentUserId: currentUserId,
    );
    final snapshot = await firestoreQuery.limit(limit).get();
    return snapshot.docs
        .where((doc) => _matches(doc.data(), query, const [
              'clientName',
              'clientPhone',
              'leadName',
              'propertyTitle',
              'propertyLocation',
              'assignedToName',
              'stage',
            ]))
        .take(8)
        .map((doc) {
      final data = doc.data();
      return GlobalSearchResult(
        id: doc.id,
        module: GlobalSearchModule.deals,
        title: _joinParts([
          _field(data, 'clientName'),
          _field(data, 'propertyTitle'),
        ], fallback: doc.id),
        subtitle: _joinParts([
          _field(data, 'clientPhone'),
          _field(data, 'propertyLocation'),
        ]),
        status: _field(data, 'stage'),
        owner: _field(data, 'assignedToName'),
        route: RouteNames.dealDetails(doc.id),
      );
    }).toList();
  }

  Future<List<GlobalSearchResult>> _searchTasks(
    String companyId,
    String currentUserId,
    UserRole role,
    String query,
    int limit,
  ) async {
    Query<Map<String, dynamic>> firestoreQuery = _scopedQuery(
      _companyCollection(companyId, 'tasks').where('isActive', isEqualTo: true),
      role: role,
      currentUserId: currentUserId,
    );
    final snapshot = await firestoreQuery.limit(limit).get();
    return snapshot.docs
        .where((doc) => _matches(doc.data(), query, const [
              'title',
              'description',
              'relatedTitle',
              'relatedSubtitle',
              'assignedToName',
              'status',
              'priority',
            ]))
        .take(8)
        .map((doc) {
      final data = doc.data();
      return GlobalSearchResult(
        id: doc.id,
        module: GlobalSearchModule.tasks,
        title: _field(data, 'title', fallback: doc.id),
        subtitle: _joinParts([
          _field(data, 'relatedTitle'),
          _field(data, 'relatedSubtitle'),
        ]),
        status: _field(data, 'status'),
        owner: _field(data, 'assignedToName'),
        route: RouteNames.taskEdit(doc.id),
      );
    }).toList();
  }

  Future<List<GlobalSearchResult>> _searchUsers(
    String companyId,
    String currentUserId,
    UserRole role,
    String query,
    int limit,
  ) async {
    Query<Map<String, dynamic>> firestoreQuery = _companyCollection(
      companyId,
      'users',
    ).where('isActive', isEqualTo: true);
    if (role == UserRole.manager) {
      firestoreQuery = firestoreQuery.where('managerId', isEqualTo: currentUserId);
    } else if (role != UserRole.admin) {
      firestoreQuery = firestoreQuery.where('uid', isEqualTo: currentUserId);
    }
    final snapshot = await firestoreQuery.limit(limit).get();
    return snapshot.docs
        .where((doc) => _matches(doc.data(), query, const [
              'fullName',
              'email',
              'phone',
              'role',
              'teamName',
            ]))
        .take(8)
        .map((doc) {
      final data = doc.data();
      return GlobalSearchResult(
        id: doc.id,
        module: GlobalSearchModule.users,
        title: _field(data, 'fullName', fallback: doc.id),
        subtitle: _joinParts([
          _field(data, 'email'),
          _field(data, 'teamName'),
        ]),
        status: _field(data, 'role'),
        route: RouteNames.teams,
      );
    }).toList();
  }

  CollectionReference<Map<String, dynamic>> _companyCollection(
    String companyId,
    String collection,
  ) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection(collection);
  }
}

Query<Map<String, dynamic>> _scopedQuery(
  Query<Map<String, dynamic>> query, {
  required UserRole role,
  required String currentUserId,
}) {
  if (role == UserRole.manager) {
    return query.where('managerId', isEqualTo: currentUserId);
  }
  if (role == UserRole.salesAgent ||
      role == UserRole.marketing ||
      role == UserRole.viewer) {
    return query.where('assignedTo', isEqualTo: currentUserId);
  }
  return query;
}

bool _matches(
  Map<String, dynamic> data,
  String query,
  List<String> fields,
) {
  for (final field in fields) {
    if (_normalize(_field(data, field)).contains(query)) {
      return true;
    }
  }
  return false;
}

String _field(
  Map<String, dynamic> data,
  String field, {
  String fallback = '',
}) {
  final value = data[field];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return fallback;
}

String _joinParts(List<String> parts, {String fallback = ''}) {
  final joined = parts.where((part) => part.trim().isNotEmpty).join(' - ');
  return joined.isEmpty ? fallback : joined;
}

String _normalize(String value) {
  return value.trim().toLowerCase();
}
