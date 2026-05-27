import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../audit_logs/data/models/audit_log_model.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../clients/data/models/client_model.dart';
import '../../../deals/data/models/deal_model.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../leads/data/models/lead_model.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../properties/data/models/property_model.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../tasks/data/models/crm_task_model.dart';
import '../../../tasks/domain/entities/crm_task.dart';
import '../../domain/entities/export_assignee.dart';
import '../../domain/entities/export_column.dart';
import '../../domain/entities/export_request.dart';
import '../models/export_dataset.dart';

abstract interface class ExportRemoteDataSource {
  Future<ExportDataset> buildDataset(ExportRequest request);

  Future<List<ExportAssignee>> getEligibleAssignees(ExportActor actor);

  Future<void> logExportGenerated({
    required ExportRequest request,
    required ExportDataset dataset,
  });
}

class FirestoreExportRemoteDataSource implements ExportRemoteDataSource {
  FirestoreExportRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int exportLimit = 2000;

  @override
  Future<ExportDataset> buildDataset(ExportRequest request) async {
    _ensureAllowed(request);

    return switch (request.module) {
      ExportModule.leads => _leadsDataset(request),
      ExportModule.clients => _clientsDataset(request),
      ExportModule.deals => _dealsDataset(request),
      ExportModule.tasks => _tasksDataset(request),
      ExportModule.appointments => _appointmentsDataset(request),
      ExportModule.properties => _propertiesDataset(request),
      ExportModule.teamPerformance => _teamPerformanceDataset(request),
      ExportModule.pipeline => _pipelineDataset(request),
      ExportModule.followUps => _followUpsDataset(request),
      ExportModule.auditSummary => _auditSummaryDataset(request),
    };
  }

  @override
  Future<List<ExportAssignee>> getEligibleAssignees(ExportActor actor) async {
    final users = _firestore.collection(FirebasePaths.companyUsers(actor.companyId));
    final byId = <String, ExportAssignee>{};

    void addUser(DocumentSnapshot<Map<String, dynamic>> doc) {
      final data = doc.data();
      if (data == null || data['isActive'] == false) {
        return;
      }
      final uid = data['uid'] as String? ?? doc.id;
      if (uid.trim().isEmpty) {
        return;
      }
      final role = data['role'] as String? ?? '';
      if (role != RoleConstants.salesAgent && role != RoleConstants.marketing) {
        return;
      }
      byId[uid] = ExportAssignee(
        uid: uid,
        name: data['fullName'] as String? ?? '',
        email: data['email'] as String? ?? '',
      );
    }

    switch (actor.role) {
      case UserRole.admin:
        final snapshot = await users
            .where('isActive', isEqualTo: true)
            .limit(200)
            .get();
        for (final doc in snapshot.docs) {
          addUser(doc);
        }
        break;
      case UserRole.manager:
        final managerScoped = await users
            .where('isActive', isEqualTo: true)
            .where('managerId', isEqualTo: actor.uid)
            .limit(100)
            .get();
        for (final doc in managerScoped.docs) {
          addUser(doc);
        }
        if (actor.teamId.trim().isNotEmpty) {
          final teamScoped = await users
              .where('isActive', isEqualTo: true)
              .where('teamId', isEqualTo: actor.teamId.trim())
              .limit(100)
              .get();
          for (final doc in teamScoped.docs) {
            addUser(doc);
          }
        }
        break;
      case UserRole.salesAgent:
      case UserRole.marketing:
        byId[actor.uid] = ExportAssignee(
          uid: actor.uid,
          name: actor.name,
          email: actor.email,
        );
        break;
      case UserRole.viewer:
        break;
    }

    final assignees = byId.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return assignees;
  }

  @override
  Future<void> logExportGenerated({
    required ExportRequest request,
    required ExportDataset dataset,
  }) async {
    try {
      final logs = _firestore.collection(
        FirebasePaths.companyAuditLogs(request.actor.companyId),
      );
      final id = logs.doc().id;
      await logs.doc(id).set({
        'id': id,
        'companyId': request.actor.companyId,
        'actorId': request.actor.uid,
        'actorName': request.actor.name,
        'actorEmail': request.actor.email,
        'actorRole': RoleConstants.toValue(request.actor.role),
        'action': 'exportGenerated',
        'module': 'reports',
        'recordId': request.module.name,
        'recordTitle': _moduleLabel(request),
        'recordSubtitle': _label(request, 'excel'),
        'assignedTo': request.filters.assigneeId,
        'teamId': request.actor.teamId,
        'teamName': request.actor.teamName,
        'managerId': request.actor.role == UserRole.manager ? request.actor.uid : '',
        'managerName': request.actor.role == UserRole.manager ? request.actor.name : '',
        'createdAt': Timestamp.now(),
        'metadata': {
          'format': 'excel',
          'recordCount': dataset.recordCount,
          'dateRange': request.filters.dateRange.name,
          'scope': _scopeLabel(request),
          'filters': _filtersSummary(request),
          'limitedByCap': dataset.limitedByCap,
        },
      });
    } catch (_) {
      // Export should stay available even if audit logging is temporarily blocked.
    }
  }

  Future<ExportDataset> _leadsDataset(ExportRequest request) async {
    final leads = await _fetchLeads(request);
    final columns = _selectedColumns(request, [
      _column(request, 'leadName'),
      _column(request, 'phone'),
      _column(request, 'email'),
      _column(request, 'status'),
      _column(request, 'priority'),
      _column(request, 'source'),
      _column(request, 'sourceDetails', recommended: false),
      _column(request, 'assignedTo'),
      _column(request, 'team'),
      _column(request, 'manager'),
      _column(request, 'budget'),
      _column(request, 'preferredLocation'),
      _column(request, 'preferredPropertyType'),
      _column(request, 'lastContactAt', recommended: false),
      _column(request, 'nextFollowUpAt'),
      _column(request, 'createdAt'),
      _column(request, 'updatedAt', recommended: false),
      _column(request, 'archived'),
    ]);
    return _dataset(
      request: request,
      columns: columns,
      rows: leads.map((lead) {
        return _row(columns, {
          'leadName': lead.fullName,
          'phone': lead.phone,
          'email': lead.email,
          'status': _enumLabel(request, 'leadStatus.${lead.status.name}', lead.status.name),
          'priority': _enumLabel(request, 'priority.${lead.priority.name}', lead.priority.name),
          'source': _enumLabel(request, 'leadSource.${lead.source.name}', lead.source.name),
          'sourceDetails': lead.sourceDetails,
          'assignedTo': lead.assignedToName,
          'team': lead.teamName,
          'manager': lead.managerName,
          'budget': _moneyRange(lead.budgetMin, lead.budgetMax),
          'preferredLocation': lead.preferredLocation,
          'preferredPropertyType': lead.preferredPropertyType,
          'lastContactAt': _date(lead.lastContactAt),
          'nextFollowUpAt': _date(lead.nextFollowUpAt),
          'createdAt': _dateTime(lead.createdAt),
          'updatedAt': _dateTime(lead.updatedAt),
          'archived': _bool(request, lead.isArchived),
        });
      }).toList(),
      limitedByCap: leads.length >= exportLimit,
    );
  }

  Future<ExportDataset> _clientsDataset(ExportRequest request) async {
    final clients = await _fetchClients(request);
    final columns = _selectedColumns(request, [
      _column(request, 'clientName'),
      _column(request, 'phone'),
      _column(request, 'email'),
      _column(request, 'assignedTo'),
      _column(request, 'team'),
      _column(request, 'manager'),
      _column(request, 'budget'),
      _column(request, 'preferredLocation'),
      _column(request, 'preferredPropertyType', recommended: false),
      _column(request, 'createdAt'),
      _column(request, 'updatedAt', recommended: false),
      _column(request, 'archived'),
    ]);
    return _dataset(
      request: request,
      columns: columns,
      rows: clients.map((client) {
        return _row(columns, {
          'clientName': client.fullName,
          'phone': client.phone,
          'email': client.email,
          'assignedTo': client.assignedToName,
          'team': client.teamName,
          'manager': client.managerName,
          'budget': _moneyRange(client.budgetMin, client.budgetMax),
          'preferredLocation': client.preferredLocation,
          'preferredPropertyType': client.preferredPropertyType,
          'createdAt': _dateTime(client.createdAt),
          'updatedAt': _dateTime(client.updatedAt),
          'archived': _bool(request, client.isArchived),
        });
      }).toList(),
      limitedByCap: clients.length >= exportLimit,
    );
  }

  Future<ExportDataset> _dealsDataset(ExportRequest request) async {
    final deals = await _fetchDeals(request);
    final columns = _selectedColumns(request, [
      _column(request, 'dealTitle'),
      _column(request, 'client'),
      _column(request, 'property'),
      _column(request, 'stage'),
      _column(request, 'value'),
      _column(request, 'commission', recommended: false),
      _column(request, 'expectedCloseDate'),
      _column(request, 'assignedTo'),
      _column(request, 'team'),
      _column(request, 'manager'),
      _column(request, 'createdAt'),
      _column(request, 'updatedAt', recommended: false),
      _column(request, 'lostReason', recommended: false),
      _column(request, 'archived'),
    ]);
    return _dataset(
      request: request,
      columns: columns,
      rows: deals.map((deal) {
        return _row(columns, {
          'dealTitle': _firstNonEmpty([deal.clientName, deal.propertyTitle, deal.leadName]),
          'client': deal.clientName,
          'property': deal.propertyTitle,
          'stage': _enumLabel(request, 'dealStage.${deal.stage.name}', deal.stage.name),
          'value': _number(deal.expectedValue),
          'commission': _number(deal.commission),
          'expectedCloseDate': _date(deal.closingDate),
          'assignedTo': deal.assignedToName,
          'team': deal.teamName,
          'manager': deal.managerName,
          'createdAt': _dateTime(deal.createdAt),
          'updatedAt': _dateTime(deal.updatedAt),
          'lostReason': deal.lostReason,
          'archived': _bool(request, deal.isArchived),
        });
      }).toList(),
      limitedByCap: deals.length >= exportLimit,
    );
  }

  Future<ExportDataset> _tasksDataset(ExportRequest request) async {
    final tasks = await _fetchTasks(request);
    final columns = _selectedColumns(request, [
      _column(request, 'title'),
      _column(request, 'status'),
      _column(request, 'priority'),
      _column(request, 'dueDate'),
      _column(request, 'assignedTo'),
      _column(request, 'team'),
      _column(request, 'manager'),
      _column(request, 'relatedType'),
      _column(request, 'relatedTitle'),
      _column(request, 'createdAt'),
      _column(request, 'updatedAt', recommended: false),
    ]);
    return _dataset(
      request: request,
      columns: columns,
      rows: tasks.map((task) {
        return _row(columns, {
          'title': task.title,
          'status': _enumLabel(request, 'taskStatus.${task.status.name}', task.status.name),
          'priority': _enumLabel(request, 'priority.${task.priority.name}', task.priority.name),
          'dueDate': _dateTime(task.dueDate),
          'assignedTo': task.assignedToName,
          'team': task.teamName,
          'manager': task.managerName,
          'relatedType': _enumLabel(request, 'taskRelated.${task.relatedType.name}', task.relatedType.name),
          'relatedTitle': task.relatedTitle,
          'createdAt': _dateTime(task.createdAt),
          'updatedAt': _dateTime(task.updatedAt),
        });
      }).toList(),
      limitedByCap: tasks.length >= exportLimit,
    );
  }

  Future<ExportDataset> _appointmentsDataset(ExportRequest request) async {
    final appointments = await _fetchAppointments(request);
    final columns = _selectedColumns(request, [
      _column(request, 'title'),
      _column(request, 'scheduledAt'),
      _column(request, 'status'),
      _column(request, 'appointmentType'),
      _column(request, 'assignedTo'),
      _column(request, 'team'),
      _column(request, 'manager'),
      _column(request, 'relatedType'),
      _column(request, 'relatedTitle'),
      _column(request, 'location'),
      _column(request, 'createdAt'),
      _column(request, 'updatedAt', recommended: false),
    ]);
    return _dataset(
      request: request,
      columns: columns,
      rows: appointments.map((appointment) {
        return _row(columns, {
          'title': appointment.title,
          'scheduledAt': _dateTime(appointment.scheduledAt),
          'status': _enumLabel(request, 'appointmentStatus.${appointment.status.name}', appointment.status.name),
          'appointmentType': _enumLabel(request, 'appointmentType.${appointment.type.name}', appointment.type.name),
          'assignedTo': appointment.assignedToName,
          'team': appointment.teamName,
          'manager': appointment.managerName,
          'relatedType': _enumLabel(request, 'appointmentRelated.${appointment.relatedType.name}', appointment.relatedType.name),
          'relatedTitle': appointment.relatedTitle,
          'location': appointment.location,
          'createdAt': _dateTime(appointment.createdAt),
          'updatedAt': _dateTime(appointment.updatedAt),
        });
      }).toList(),
      limitedByCap: appointments.length >= exportLimit,
    );
  }

  Future<ExportDataset> _propertiesDataset(ExportRequest request) async {
    final properties = await _fetchProperties(request);
    final columns = _selectedColumns(request, [
      _column(request, 'propertyTitle'),
      _column(request, 'propertyType'),
      _column(request, 'listingType'),
      _column(request, 'status'),
      _column(request, 'price'),
      _column(request, 'location'),
      _column(request, 'bedrooms'),
      _column(request, 'bathrooms'),
      _column(request, 'area'),
      _column(request, 'assignedTo', recommended: false),
      _column(request, 'createdAt'),
      _column(request, 'updatedAt', recommended: false),
      _column(request, 'imageCount', recommended: false),
      _column(request, 'archived'),
    ]);
    return _dataset(
      request: request,
      columns: columns,
      rows: properties.map((property) {
        return _row(columns, {
          'propertyTitle': property.title,
          'propertyType': _enumLabel(request, 'propertyType.${property.propertyType.name}', property.propertyType.name),
          'listingType': _enumLabel(request, 'listingType.${property.listingType.name}', property.listingType.name),
          'status': _enumLabel(request, 'propertyStatus.${property.status.name}', property.status.name),
          'price': _number(property.price),
          'location': _firstNonEmpty([property.location, property.compound]),
          'bedrooms': property.bedrooms.toString(),
          'bathrooms': property.bathrooms.toString(),
          'area': _number(property.area),
          'assignedTo': '',
          'createdAt': _dateTime(property.createdAt),
          'updatedAt': _dateTime(property.updatedAt),
          'imageCount': property.imageUrls.length.toString(),
          'archived': _bool(request, property.isArchived),
        });
      }).toList(),
      limitedByCap: properties.length >= exportLimit,
    );
  }

  Future<ExportDataset> _pipelineDataset(ExportRequest request) async {
    final deals = await _fetchDeals(request);
    final columns = [
      _column(request, 'stage'),
      _column(request, 'dealCount'),
      _column(request, 'totalValue'),
      _column(request, 'averageDealValue'),
    ];
    final rows = <List<String>>[];
    for (final stage in DealStage.values) {
      final stageDeals = deals.where((deal) => deal.stage == stage).toList();
      final value = stageDeals.fold<num>(0, (sum, deal) => sum + deal.expectedValue);
      rows.add(_row(columns, {
        'stage': _enumLabel(request, 'dealStage.${stage.name}', stage.name),
        'dealCount': stageDeals.length.toString(),
        'totalValue': _number(value),
        'averageDealValue': _number(stageDeals.isEmpty ? 0 : value / stageDeals.length),
      }));
    }
    return _dataset(
      request: request,
      columns: columns,
      rows: rows,
      limitedByCap: deals.length >= exportLimit,
    );
  }

  Future<ExportDataset> _followUpsDataset(ExportRequest request) async {
    final tasks = await _fetchTasks(request);
    final appointments = await _fetchAppointments(request);
    final columns = [
      _column(request, 'type'),
      _column(request, 'title'),
      _column(request, 'status'),
      _column(request, 'dueDate'),
      _column(request, 'assignedTo'),
      _column(request, 'team'),
      _column(request, 'relatedTitle'),
    ];
    final rows = <List<String>>[
      for (final task in tasks.where((task) => task.dueDate != null))
        _row(columns, {
          'type': _label(request, 'tasks'),
          'title': task.title,
          'status': _enumLabel(request, 'taskStatus.${task.status.name}', task.status.name),
          'dueDate': _dateTime(task.dueDate),
          'assignedTo': task.assignedToName,
          'team': task.teamName,
          'relatedTitle': task.relatedTitle,
        }),
      for (final appointment in appointments)
        _row(columns, {
          'type': _label(request, 'appointments'),
          'title': appointment.title,
          'status': _enumLabel(request, 'appointmentStatus.${appointment.status.name}', appointment.status.name),
          'dueDate': _dateTime(appointment.scheduledAt),
          'assignedTo': appointment.assignedToName,
          'team': appointment.teamName,
          'relatedTitle': appointment.relatedTitle,
        }),
    ];
    return _dataset(
      request: request,
      columns: columns,
      rows: rows,
      limitedByCap: tasks.length >= exportLimit || appointments.length >= exportLimit,
    );
  }

  Future<ExportDataset> _teamPerformanceDataset(ExportRequest request) async {
    final assignees = await getEligibleAssignees(request.actor);
    final assigneeIds = assignees.map((item) => item.uid).toSet();
    final leads = await _fetchLeads(request);
    final deals = await _fetchDeals(request);
    final tasks = await _fetchTasks(request);
    final appointments = await _fetchAppointments(request);
    final columns = [
      _column(request, 'team'),
      _column(request, 'manager'),
      _column(request, 'assignedTo'),
      _column(request, 'leadsAssigned'),
      _column(request, 'newLeads'),
      _column(request, 'convertedLeads'),
      _column(request, 'openDeals'),
      _column(request, 'wonDeals'),
      _column(request, 'pipelineValue'),
      _column(request, 'tasksDue'),
      _column(request, 'tasksOverdue'),
      _column(request, 'tasksCompleted'),
      _column(request, 'appointmentsUpcoming'),
      _column(request, 'appointmentsCompleted'),
    ];
    final now = DateTime.now();
    final rows = <List<String>>[];
    for (final assignee in assignees) {
      final id = assignee.uid;
      if (id.trim().isEmpty || !assigneeIds.contains(id)) {
        continue;
      }
      final userLeads = leads.where((lead) => lead.assignedTo == id).toList();
      final userDeals = deals.where((deal) => deal.assignedTo == id).toList();
      final userTasks = tasks.where((task) => task.assignedTo == id).toList();
      final userAppointments = appointments
          .where((appointment) => appointment.assignedTo == id)
          .toList();
      final pipelineValue = userDeals
          .where((deal) => deal.stage != DealStage.won && deal.stage != DealStage.lost)
          .fold<num>(0, (sum, deal) => sum + deal.expectedValue);
      rows.add(_row(columns, {
        'team': request.actor.role == UserRole.manager ? request.actor.teamName : _firstNonEmpty(userLeads.map((lead) => lead.teamName).toList()),
        'manager': request.actor.role == UserRole.manager ? request.actor.name : _firstNonEmpty(userLeads.map((lead) => lead.managerName).toList()),
        'assignedTo': assignee.displayName,
        'leadsAssigned': userLeads.length.toString(),
        'newLeads': userLeads.where((lead) => lead.status == LeadStatus.newLead).length.toString(),
        'convertedLeads': userLeads.where((lead) => lead.status == LeadStatus.won).length.toString(),
        'openDeals': userDeals.where((deal) => deal.stage != DealStage.won && deal.stage != DealStage.lost).length.toString(),
        'wonDeals': userDeals.where((deal) => deal.stage == DealStage.won).length.toString(),
        'pipelineValue': _number(pipelineValue),
        'tasksDue': userTasks.where((task) => task.dueDate != null).length.toString(),
        'tasksOverdue': userTasks.where((task) {
          final due = task.dueDate;
          return due != null &&
              due.isBefore(now) &&
              task.status != TaskStatus.completed &&
              task.status != TaskStatus.cancelled;
        }).length.toString(),
        'tasksCompleted': userTasks.where((task) => task.status == TaskStatus.completed).length.toString(),
        'appointmentsUpcoming': userAppointments.where((item) {
          final scheduledAt = item.scheduledAt;
          return scheduledAt != null &&
              scheduledAt.isAfter(now) &&
              item.status == AppointmentStatus.scheduled;
        }).length.toString(),
        'appointmentsCompleted': userAppointments.where((item) => item.status == AppointmentStatus.completed).length.toString(),
      }));
    }
    return _dataset(
      request: request,
      columns: columns,
      rows: rows,
      limitedByCap: leads.length >= exportLimit ||
          deals.length >= exportLimit ||
          tasks.length >= exportLimit ||
          appointments.length >= exportLimit,
    );
  }

  Future<ExportDataset> _auditSummaryDataset(ExportRequest request) async {
    final logs = await _fetchAuditLogs(request);
    final columns = _selectedColumns(request, [
      _column(request, 'createdAt'),
      _column(request, 'module'),
      _column(request, 'action'),
      _column(request, 'recordTitle'),
      _column(request, 'actor'),
      _column(request, 'assignedTo', recommended: false),
      _column(request, 'team', recommended: false),
    ]);
    return _dataset(
      request: request,
      columns: columns,
      rows: logs.map((log) {
        return _row(columns, {
          'createdAt': _dateTime(log.createdAt),
          'module': _enumLabel(request, 'auditModule.${log.module.name}', log.module.name),
          'action': _enumLabel(request, 'auditAction.${log.action.name}', log.action.name),
          'recordTitle': log.recordTitle,
          'actor': _firstNonEmpty([log.actorName, log.actorEmail]),
          'assignedTo': log.assignedTo,
          'team': log.teamName,
        });
      }).toList(),
      limitedByCap: logs.length >= exportLimit,
    );
  }

  Future<List<LeadModel>> _fetchLeads(ExportRequest request) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyLeads(request.actor.companyId));
    if (request.filters.includeArchived) {
      // No archive clause keeps admin/manager historical exports possible.
    } else {
      query = query.where('isArchived', isEqualTo: false);
    }
    query = _applyAssignmentScope(query, request);
    final snapshot = await query.limit(exportLimit + 1).get();
    final items = snapshot.docs.map(LeadModel.fromFirestore).where((item) {
      return item.companyId == request.actor.companyId &&
          _matchesDate(request, item.createdAt) &&
          _matchesAssignee(request, item.assignedTo) &&
          _matchesStatus(request, leadStatusToValue(item.status));
    }).take(exportLimit).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<List<ClientModel>> _fetchClients(ExportRequest request) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyClients(request.actor.companyId));
    if (request.filters.includeArchived) {
      query = query.where('isActive', isEqualTo: true);
    } else {
      query = query.where('isActive', isEqualTo: true).where('isArchived', isEqualTo: false);
    }
    query = _applyAssignmentScope(query, request);
    final snapshot = await query.limit(exportLimit + 1).get();
    final items = snapshot.docs.map(ClientModel.fromFirestore).where((item) {
      return item.companyId == request.actor.companyId &&
          _matchesDate(request, item.createdAt) &&
          _matchesAssignee(request, item.assignedTo);
    }).take(exportLimit).toList();
    items.sort(
      (a, b) => (b.createdAt ?? _epoch).compareTo(a.createdAt ?? _epoch),
    );
    return items;
  }

  Future<List<DealModel>> _fetchDeals(ExportRequest request) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyDeals(request.actor.companyId));
    if (request.filters.includeArchived) {
      query = query.where('isActive', isEqualTo: true);
    } else {
      query = query.where('isActive', isEqualTo: true).where('isArchived', isEqualTo: false);
    }
    query = _applyAssignmentScope(query, request);
    final snapshot = await query.limit(exportLimit + 1).get();
    final items = snapshot.docs.map(DealModel.fromFirestore).where((item) {
      return item.companyId == request.actor.companyId &&
          _matchesDate(request, item.createdAt) &&
          _matchesAssignee(request, item.assignedTo) &&
          _matchesStatus(request, dealStageToValue(item.stage));
    }).take(exportLimit).toList();
    items.sort(
      (a, b) => (b.createdAt ?? _epoch).compareTo(a.createdAt ?? _epoch),
    );
    return items;
  }

  Future<List<CrmTaskModel>> _fetchTasks(ExportRequest request) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyTasks(request.actor.companyId))
        .where('isActive', isEqualTo: true);
    query = _applyAssignmentScope(query, request);
    final snapshot = await query.limit(exportLimit + 1).get();
    final items = snapshot.docs.map(CrmTaskModel.fromFirestore).where((item) {
      final date = request.module == ExportModule.followUps
          ? item.dueDate
          : item.createdAt ?? item.updatedAt;
      return item.companyId == request.actor.companyId &&
          _matchesDate(request, date) &&
          _matchesAssignee(request, item.assignedTo) &&
          _matchesStatus(request, item.status.name);
    }).take(exportLimit).toList();
    items.sort((a, b) {
      final bDate = b.dueDate ?? b.createdAt ?? _epoch;
      final aDate = a.dueDate ?? a.createdAt ?? _epoch;
      return bDate.compareTo(aDate);
    });
    return items;
  }

  Future<List<AppointmentModel>> _fetchAppointments(ExportRequest request) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyAppointments(request.actor.companyId));
    query = _applyAssignmentScope(query, request);
    final snapshot = await query.limit(exportLimit + 1).get();
    final items = snapshot.docs.map(AppointmentModel.fromFirestore).where((item) {
      final date = request.module == ExportModule.appointments ||
              request.module == ExportModule.followUps
          ? item.scheduledAt
          : item.createdAt ?? item.updatedAt;
      return item.companyId == request.actor.companyId &&
          _matchesDate(request, date) &&
          _matchesAssignee(request, item.assignedTo) &&
          _matchesStatus(request, item.status.name);
    }).take(exportLimit).toList();
    items.sort((a, b) {
      final bDate = b.scheduledAt ?? b.createdAt ?? _epoch;
      final aDate = a.scheduledAt ?? a.createdAt ?? _epoch;
      return bDate.compareTo(aDate);
    });
    return items;
  }

  Future<List<PropertyModel>> _fetchProperties(ExportRequest request) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyProperties(request.actor.companyId));
    final selectedAssignee = request.filters.assigneeId.trim();
    if (request.actor.role == UserRole.admin && selectedAssignee.isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: selectedAssignee);
    }
    final snapshot = await query.limit(exportLimit + 1).get();
    final items = snapshot.docs.map(PropertyModel.fromFirestore).where((item) {
      return item.companyId == request.actor.companyId &&
          (request.filters.includeArchived || !item.isArchived) &&
          _matchesDate(request, item.createdAt) &&
          _matchesStatus(request, propertyStatusToValue(item.status));
    }).take(exportLimit).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<List<AuditLogModel>> _fetchAuditLogs(ExportRequest request) async {
    final collection = _firestore.collection(
      FirebasePaths.companyAuditLogs(request.actor.companyId),
    );
    final snapshots = <QuerySnapshot<Map<String, dynamic>>>[];
    if (request.actor.role == UserRole.admin) {
      snapshots.add(await collection.limit(exportLimit + 1).get());
    } else if (request.actor.role == UserRole.manager) {
      snapshots.add(
        await collection
            .where('managerId', isEqualTo: request.actor.uid)
            .limit(800)
            .get(),
      );
      snapshots.add(
        await collection
            .where('actorId', isEqualTo: request.actor.uid)
            .limit(800)
            .get(),
      );
      if (request.actor.teamId.trim().isNotEmpty) {
        snapshots.add(
          await collection
              .where('teamId', isEqualTo: request.actor.teamId.trim())
              .limit(800)
              .get(),
        );
      }
    }

    final byId = <String, AuditLogModel>{};
    for (final snapshot in snapshots) {
      for (final document in snapshot.docs) {
        final log = AuditLogModel.fromFirestore(document);
        if (log.companyId == request.actor.companyId &&
            _matchesDate(request, log.createdAt)) {
          byId[log.id] = log;
        }
      }
    }
    final logs = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return logs.take(exportLimit).toList();
  }

  Query<Map<String, dynamic>> _applyAssignmentScope(
    Query<Map<String, dynamic>> query,
    ExportRequest request,
  ) {
    switch (request.actor.role) {
      case UserRole.admin:
        final selected = request.filters.assigneeId.trim();
        return selected.isEmpty ? query : query.where('assignedTo', isEqualTo: selected);
      case UserRole.manager:
        return query.where('managerId', isEqualTo: request.actor.uid);
      case UserRole.salesAgent:
      case UserRole.marketing:
        return query.where('assignedTo', isEqualTo: request.actor.uid);
      case UserRole.viewer:
        return query.where('assignedTo', isEqualTo: '__no_export_scope__');
    }
  }

  ExportDataset _dataset({
    required ExportRequest request,
    required List<ExportColumn> columns,
    required List<List<String>> rows,
    required bool limitedByCap,
    List<ExportSheet> extraSheets = const <ExportSheet>[],
  }) {
    return ExportDataset(
      columns: columns,
      rows: rows,
      extraSheets: extraSheets,
      limitedByCap: limitedByCap,
      summary: {
        _label(request, 'product'): 'Masar CRM',
        _label(request, 'company'): request.actor.companyName,
        _label(request, 'reportName'): _moduleLabel(request),
        _label(request, 'scope'): _scopeLabel(request),
        _label(request, 'dateRange'): _dateRangeLabel(request),
        _label(request, 'generatedBy'): _firstNonEmpty([request.actor.name, request.actor.email]),
        _label(request, 'generatedAt'): _dateTime(DateTime.now()),
        _label(request, 'recordCount'): rows.length.toString(),
        _label(request, 'filtersSummary'): _filtersSummary(request),
      },
    );
  }

  List<ExportColumn> _selectedColumns(
    ExportRequest request,
    List<ExportColumn> columns,
  ) {
    final selected = request.columns.isEmpty
        ? request.filters.selectedColumnIds
        : request.columns;
    if (selected.isEmpty) {
      return columns.where((column) => column.recommended).toList();
    }
    final selectedSet = selected.toSet();
    final filtered = columns.where((column) => selectedSet.contains(column.id)).toList();
    return filtered.isEmpty ? columns.where((column) => column.recommended).toList() : filtered;
  }

  ExportColumn _column(
    ExportRequest request,
    String id, {
    bool recommended = true,
  }) {
    return ExportColumn(
      id: id,
      label: _label(request, 'column.$id'),
      recommended: recommended,
    );
  }

  List<String> _row(List<ExportColumn> columns, Map<String, String> values) {
    return columns.map((column) {
      final value = values[column.id]?.trim() ?? '';
      return value.isEmpty ? '' : value;
    }).toList(growable: false);
  }

  bool _matchesAssignee(ExportRequest request, String assignedTo) {
    final selected = request.filters.assigneeId.trim();
    if (selected.isEmpty || request.actor.role == UserRole.salesAgent ||
        request.actor.role == UserRole.marketing) {
      return true;
    }
    return assignedTo == selected;
  }

  bool _matchesStatus(ExportRequest request, String status) {
    final selected = request.filters.status.trim();
    return selected.isEmpty || status == selected;
  }

  bool _matchesDate(ExportRequest request, DateTime? date) {
    final range = _dateRange(request.filters);
    if (range == null) {
      return true;
    }
    if (date == null) {
      return false;
    }
    final value = DateTime(date.year, date.month, date.day);
    return !value.isBefore(range.start) && value.isBefore(range.end);
  }

  _ExportDateWindow? _dateRange(ExportFilters filters) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (filters.dateRange) {
      ExportDateRangePreset.allTime => null,
      ExportDateRangePreset.today => _ExportDateWindow(today, today.add(const Duration(days: 1))),
      ExportDateRangePreset.thisWeek => () {
          final start = today.subtract(Duration(days: today.weekday - 1));
          return _ExportDateWindow(start, start.add(const Duration(days: 7)));
        }(),
      ExportDateRangePreset.thisMonth => _ExportDateWindow(
          DateTime(today.year, today.month),
          DateTime(today.year, today.month + 1),
        ),
      ExportDateRangePreset.lastMonth => _ExportDateWindow(
          DateTime(today.year, today.month - 1),
          DateTime(today.year, today.month),
        ),
      ExportDateRangePreset.custom => filters.customStart == null ||
              filters.customEnd == null
          ? null
          : _ExportDateWindow(
              DateTime(
                filters.customStart!.year,
                filters.customStart!.month,
                filters.customStart!.day,
              ),
              DateTime(
                filters.customEnd!.year,
                filters.customEnd!.month,
                filters.customEnd!.day,
              ).add(const Duration(days: 1)),
            ),
    };
  }

  void _ensureAllowed(ExportRequest request) {
    final role = request.actor.role;
    if (role == UserRole.viewer) {
      throw StateError(_label(request, 'permissionDenied'));
    }
    if (request.module == ExportModule.properties && role != UserRole.admin) {
      throw StateError(_label(request, 'permissionDenied'));
    }
    if (request.module == ExportModule.teamPerformance &&
        role != UserRole.admin &&
        role != UserRole.manager) {
      throw StateError(_label(request, 'permissionDenied'));
    }
    if (request.module == ExportModule.auditSummary &&
        role != UserRole.admin &&
        role != UserRole.manager) {
      throw StateError(_label(request, 'permissionDenied'));
    }
  }

  String _filtersSummary(ExportRequest request) {
    final parts = <String>[
      _dateRangeLabel(request),
      if (request.filters.status.trim().isNotEmpty)
        '${_label(request, 'status')}: ${_statusFilterLabel(request)}',
      if (request.filters.assigneeId.trim().isNotEmpty)
        '${_label(request, 'assignedTo')}: ${_label(request, 'selectedAssignee')}',
      if (request.filters.includeArchived) _label(request, 'includeArchived'),
    ];
    return parts.join(' | ');
  }

  String _dateRangeLabel(ExportRequest request) {
    return _label(request, 'dateRange.${request.filters.dateRange.name}');
  }

  String _statusFilterLabel(ExportRequest request) {
    final status = request.filters.status.trim();
    if (status.isEmpty) {
      return '';
    }
    final key = switch (request.module) {
      ExportModule.leads => status == 'new'
          ? 'leadStatus.newLead'
          : 'leadStatus.$status',
      ExportModule.deals || ExportModule.pipeline => status == 'new'
          ? 'dealStage.newDeal'
          : 'dealStage.$status',
      ExportModule.tasks => 'taskStatus.$status',
      ExportModule.appointments => 'appointmentStatus.$status',
      ExportModule.properties => 'propertyStatus.$status',
      _ => '',
    };
    return key.isEmpty ? status : _label(request, key);
  }

  String _scopeLabel(ExportRequest request) {
    return switch (request.actor.role) {
      UserRole.admin => _label(request, 'scope.companyWide'),
      UserRole.manager => _label(request, 'scope.myTeam'),
      UserRole.salesAgent || UserRole.marketing => _label(request, 'scope.myRecords'),
      UserRole.viewer => _label(request, 'scope.restricted'),
    };
  }

  String _moduleLabel(ExportRequest request) {
    return _label(request, 'module.${request.module.name}');
  }

  String _label(ExportRequest request, String key) {
    return request.labels[key] ?? key;
  }

  String _enumLabel(ExportRequest request, String key, String fallback) {
    return request.labels[key] ?? fallback;
  }

  String _bool(ExportRequest request, bool value) {
    return value ? _label(request, 'yes') : _label(request, 'no');
  }

  String _date(DateTime? value) {
    if (value == null) {
      return '';
    }
    return DateFormat('yyyy-MM-dd').format(value.toLocal());
  }

  String _dateTime(DateTime? value) {
    if (value == null) {
      return '';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }

  String _number(num value) {
    return NumberFormat('#,##0.##').format(value);
  }

  String _moneyRange(num? min, num? max) {
    final start = min == null ? '' : _number(min);
    final end = max == null ? '' : _number(max);
    if (start.isEmpty && end.isEmpty) {
      return '';
    }
    if (start.isEmpty) {
      return end;
    }
    if (end.isEmpty || end == '0') {
      return start;
    }
    return '$start - $end';
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }
}

class _ExportDateWindow {
  const _ExportDateWindow(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);
