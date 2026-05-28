import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../leads/domain/entities/lead_timeline_event.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/entities/connected_journey.dart';

List<JourneyItem> leadBaseJourneyItems(
  AppLocalizations l,
  Lead lead,
  List<LeadTimelineEvent> timeline, {
  List<UserProfile> users = const <UserProfile>[],
}) {
  final items = <JourneyItem>[
    JourneyItem(
      id: 'lead:${lead.id}:created',
      type: JourneyItemType.recordCreated,
      targetType: JourneyTargetType.lead,
      targetId: lead.id,
      title: lead.fullName,
      subtitle: lead.phone,
      occurredAt: lead.createdAt,
      tone: JourneyTone.info,
    ),
    JourneyItem(
      id: 'lead:${lead.id}:updated:${lead.updatedAt.millisecondsSinceEpoch}',
      type: JourneyItemType.recordUpdated,
      targetType: JourneyTargetType.lead,
      targetId: lead.id,
      title: lead.fullName,
      subtitle: lead.assignedToName,
      occurredAt: lead.updatedAt,
      tone: JourneyTone.neutral,
    ),
    if (lead.isArchived && lead.archivedAt != null)
      JourneyItem(
        id: 'lead:${lead.id}:archived:${lead.archivedAt!.millisecondsSinceEpoch}',
        type: JourneyItemType.recordArchived,
        targetType: JourneyTargetType.lead,
        targetId: lead.id,
        title: lead.fullName,
        subtitle: lead.archiveReason,
        occurredAt: lead.archivedAt!,
        tone: JourneyTone.neutral,
        actorName: lead.archivedByName,
      ),
    if (lead.restoredAt != null)
      JourneyItem(
        id: 'lead:${lead.id}:restored:${lead.restoredAt!.millisecondsSinceEpoch}',
        type: JourneyItemType.recordRestored,
        targetType: JourneyTargetType.lead,
        targetId: lead.id,
        title: lead.fullName,
        subtitle: lead.restoredByName,
        occurredAt: lead.restoredAt!,
        tone: JourneyTone.success,
        actorName: lead.restoredByName,
      ),
    for (final event in timeline)
      _leadTimelineJourneyItem(l, lead, event, users),
  ];
  return _dedupe(items);
}

JourneyItem _leadTimelineJourneyItem(
  AppLocalizations l,
  Lead lead,
  LeadTimelineEvent event,
  List<UserProfile> users,
) {
  final title = _timelineTitle(l, event, users);
  final description = _timelineDescription(l, event, users);
  return JourneyItem(
    id: 'lead-timeline:${event.id}',
    type: _timelineJourneyType(event),
    targetType: JourneyTargetType.lead,
    targetId: lead.id,
    title: title,
    subtitle: description,
    occurredAt: event.createdAt,
    tone: _timelineTone(event.title.isNotEmpty ? event.title : event.type),
    actorName: _eventActorName(l, event, users),
    statusLabel: _timelineStatusLabel(l, event),
    metadata: event.metadata,
  );
}

JourneyItemType _timelineJourneyType(LeadTimelineEvent event) {
  return switch (event.title) {
    'lead_created' => JourneyItemType.recordCreated,
    'lead_archived' => JourneyItemType.recordArchived,
    'lead_reassigned' || 'lead_assigned' => JourneyItemType.auditUpdated,
    'status_changed' => JourneyItemType.dealStageChanged,
    'note_added' => JourneyItemType.leadTimeline,
    'field_changed' => JourneyItemType.recordUpdated,
    _ => JourneyItemType.leadTimeline,
  };
}

String _timelineTitle(
  AppLocalizations l,
  LeadTimelineEvent event,
  List<UserProfile> users,
) {
  final actor = _eventActorName(l, event, users);
  switch (event.title) {
    case 'lead_created':
      return l.leadCreatedBy(actor);
    case 'lead_assigned':
      return l.leadReassignedBy(actor);
    case 'lead_reassigned':
      return l.leadReassignedFromToBy(
        _timelineValueLabel(l, event.description, event.oldValue, users),
        _timelineValueLabel(l, event.description, event.newValue, users),
        actor,
      );
    case 'status_changed':
      return l.statusChangedToBy(_statusValueLabel(l, event.newValue), actor);
    case 'note_added':
      return l.noteAddedBy(actor);
    case 'lead_archived':
      return l.leadArchivedBy(actor);
    case 'field_changed':
      return l.fieldChangedBy(_fieldLabel(l, event.description), actor);
    default:
      final rawTitle = event.title.trim();
      if (rawTitle.isNotEmpty && !_isTechnicalToken(rawTitle)) {
        return rawTitle;
      }
      return l.fieldChangedBy(_fieldLabel(l, event.description), actor);
  }
}

String _timelineDescription(
  AppLocalizations l,
  LeadTimelineEvent event,
  List<UserProfile> users,
) {
  if (event.title == 'note_added') {
    return event.description;
  }
  if (event.oldValue.isEmpty && event.newValue.isEmpty) {
    return event.description.trim().isEmpty ? '' : _fieldLabel(l, event.description);
  }
  if (event.title == 'lead_reassigned') {
    return '';
  }
  return l.changedFromTo(
    _timelineValueLabel(l, event.description, event.oldValue, users),
    _timelineValueLabel(l, event.description, event.newValue, users),
  );
}

String _timelineStatusLabel(AppLocalizations l, LeadTimelineEvent event) {
  return switch (event.title) {
    'note_added' => l.notes,
    'status_changed' => l.statusUpdated,
    'field_changed' => _fieldLabel(l, event.description),
    'lead_reassigned' || 'lead_assigned' => l.assignedToLabel,
    _ => l.timeline,
  };
}

String _eventActorName(
  AppLocalizations l,
  LeadTimelineEvent event,
  List<UserProfile> users,
) {
  if (event.createdByName.trim().isNotEmpty) {
    return event.createdByName.trim();
  }
  for (final user in users) {
    if (user.uid == event.createdBy) {
      return user.fullName;
    }
  }
  return l.unknownUser;
}

String _fieldLabel(AppLocalizations l, String field) {
  switch (field) {
    case 'fullName':
      return l.fullNameUpdated;
    case 'phone':
      return l.phoneUpdated;
    case 'email':
      return l.emailUpdated;
    case 'source':
      return l.sourceUpdated;
    case 'sourceDetails':
      return l.sourceDetails;
    case 'status':
      return l.statusUpdated;
    case 'priority':
      return l.priorityUpdated;
    case 'budget':
      return l.budgetUpdated;
    case 'preferredLocation':
      return l.preferredLocationUpdated;
    case 'preferredPropertyType':
      return l.preferredPropertyTypeUpdated;
    case 'assignedTo':
      return l.assignedToLabel;
    case 'notes':
      return l.notes;
    case 'lastContactAt':
      return l.lastContact;
    case 'nextFollowUpAt':
      return l.nextFollowUp;
    default:
      return _humanizeToken(field);
  }
}

String _timelineValueLabel(
  AppLocalizations l,
  String field,
  String value,
  List<UserProfile> users,
) {
  if (field == 'status') {
    return _statusValueLabel(l, value);
  }
  if (field == 'source') {
    return _sourceValueLabel(l, value);
  }
  if (field == 'priority') {
    return _priorityValueLabel(l, value);
  }
  if (field == 'assignedTo') {
    return _assigneeName(users, value, l);
  }
  return value.isEmpty ? l.notAvailable : value;
}

String _assigneeName(List<UserProfile> users, String uid, AppLocalizations l) {
  if (uid.isEmpty) {
    return l.unassigned;
  }
  for (final user in users) {
    if (user.uid == uid) {
      return user.fullName;
    }
  }
  if (!_looksLikeUid(uid)) {
    return uid;
  }
  return l.assignedUserUnavailable;
}

bool _looksLikeUid(String value) {
  return RegExp(r'^[A-Za-z0-9_-]{20,}$').hasMatch(value);
}

String _statusValueLabel(AppLocalizations l, String value) {
  switch (value) {
    case 'newLead':
    case 'new':
      return l.newLeadStatus;
    case 'contacted':
      return l.contactedLeadStatus;
    case 'interested':
      return l.interestedLeadStatus;
    case 'visitScheduled':
      return l.visitScheduledLeadStatus;
    case 'negotiation':
      return l.negotiationLeadStatus;
    case 'won':
      return l.wonLeadStatus;
    case 'lost':
      return l.lostLeadStatus;
    default:
      return value.isEmpty ? l.notAvailable : _humanizeToken(value);
  }
}

String _sourceValueLabel(AppLocalizations l, String value) {
  switch (value) {
    case 'facebook':
      return l.facebook;
    case 'website':
      return l.website;
    case 'phoneCall':
      return l.phoneCall;
    case 'whatsapp':
      return l.whatsapp;
    case 'referral':
      return l.referral;
    case 'walkIn':
      return l.walkIn;
    case 'other':
      return l.other;
    default:
      return value.isEmpty ? l.notAvailable : _humanizeToken(value);
  }
}

String _priorityValueLabel(AppLocalizations l, String value) {
  switch (value) {
    case 'high':
      return l.high;
    case 'medium':
      return l.medium;
    case 'low':
      return l.low;
    default:
      return value.isEmpty ? l.notAvailable : _humanizeToken(value);
  }
}

List<JourneyItem> clientBaseJourneyItems(Client client) {
  final items = <JourneyItem>[
    if (client.createdAt != null)
      JourneyItem(
        id: 'client:${client.id}:created',
        type: JourneyItemType.recordCreated,
        targetType: JourneyTargetType.client,
        targetId: client.id,
        title: client.fullName,
        subtitle: client.phone,
        occurredAt: client.createdAt!,
        tone: JourneyTone.info,
      ),
    if (client.updatedAt != null)
      JourneyItem(
        id: 'client:${client.id}:updated:${client.updatedAt!.millisecondsSinceEpoch}',
        type: JourneyItemType.recordUpdated,
        targetType: JourneyTargetType.client,
        targetId: client.id,
        title: client.fullName,
        subtitle: client.assignedToName,
        occurredAt: client.updatedAt!,
        tone: JourneyTone.neutral,
      ),
    if (client.isArchived && client.archivedAt != null)
      JourneyItem(
        id: 'client:${client.id}:archived:${client.archivedAt!.millisecondsSinceEpoch}',
        type: JourneyItemType.recordArchived,
        targetType: JourneyTargetType.client,
        targetId: client.id,
        title: client.fullName,
        subtitle: client.archiveReason,
        occurredAt: client.archivedAt!,
        tone: JourneyTone.neutral,
        actorName: client.archivedByName,
      ),
    if (client.restoredAt != null)
      JourneyItem(
        id: 'client:${client.id}:restored:${client.restoredAt!.millisecondsSinceEpoch}',
        type: JourneyItemType.recordRestored,
        targetType: JourneyTargetType.client,
        targetId: client.id,
        title: client.fullName,
        subtitle: client.restoredByName,
        occurredAt: client.restoredAt!,
        tone: JourneyTone.success,
        actorName: client.restoredByName,
      ),
  ];
  return _dedupe(items);
}

List<JourneyItem> dealBaseJourneyItems(Deal deal) {
  final items = <JourneyItem>[
    if (deal.createdAt != null)
      JourneyItem(
        id: 'deal:${deal.id}:created',
        type: JourneyItemType.dealCreated,
        targetType: JourneyTargetType.deal,
        targetId: deal.id,
        title: _dealTitle(deal),
        subtitle: deal.propertyTitle,
        occurredAt: deal.createdAt!,
        tone: JourneyTone.info,
      ),
    if (deal.updatedAt != null)
      JourneyItem(
        id: 'deal:${deal.id}:updated:${deal.updatedAt!.millisecondsSinceEpoch}',
        type: _dealStageType(deal.stage),
        targetType: JourneyTargetType.deal,
        targetId: deal.id,
        title: _dealTitle(deal),
        subtitle: deal.propertyTitle,
        occurredAt: deal.updatedAt!,
        tone: _dealTone(deal.stage),
        actorName: deal.assignedToName,
      ),
    if (deal.closingDate != null)
      JourneyItem(
        id: 'deal:${deal.id}:closing:${deal.closingDate!.millisecondsSinceEpoch}',
        type: JourneyItemType.dealAtRisk,
        targetType: JourneyTargetType.deal,
        targetId: deal.id,
        title: _dealTitle(deal),
        subtitle: deal.propertyTitle,
        occurredAt: deal.closingDate!,
        tone: JourneyTone.warning,
      ),
    if (deal.isArchived && deal.archivedAt != null)
      JourneyItem(
        id: 'deal:${deal.id}:archived:${deal.archivedAt!.millisecondsSinceEpoch}',
        type: JourneyItemType.recordArchived,
        targetType: JourneyTargetType.deal,
        targetId: deal.id,
        title: _dealTitle(deal),
        subtitle: deal.archiveReason,
        occurredAt: deal.archivedAt!,
        tone: JourneyTone.neutral,
        actorName: deal.archivedByName,
      ),
  ];
  return _dedupe(items);
}

List<JourneyRecommendation> leadJourneyRecommendations(
  AppLocalizations l,
  Lead lead, {
  required bool canCreateTask,
  required bool canCreateAppointment,
}) {
  final today = _dateOnly(DateTime.now());
  final recommendations = <JourneyRecommendation>[];
  final followUp = lead.nextFollowUpAt;
  if (followUp != null && _dateOnly(followUp).isBefore(today)) {
    recommendations.add(JourneyRecommendation(
      title: l.journeyActionOverdueFollowUp,
      subtitle: l.journeyActionOverdueFollowUpDescription,
      tone: JourneyTone.danger,
      actionLabel: canCreateTask ? l.createTask : '',
      actionRoute: canCreateTask
          ? RouteNames.taskCreateFor(
              relatedType: 'lead',
              relatedId: lead.id,
              relatedTitle: lead.fullName,
              relatedSubtitle: lead.phone,
              assignedTo: lead.assignedTo,
            )
          : '',
    ));
  }
  final lastContact = lead.lastContactAt;
  if (lastContact == null || today.difference(_dateOnly(lastContact)).inDays >= 7) {
    recommendations.add(JourneyRecommendation(
      title: l.journeyActionNoContact,
      subtitle: l.journeyActionNoContactDescription,
      tone: JourneyTone.warning,
      actionLabel: canCreateTask ? l.createTask : '',
      actionRoute: canCreateTask
          ? RouteNames.taskCreateFor(
              relatedType: 'lead',
              relatedId: lead.id,
              relatedTitle: lead.fullName,
              relatedSubtitle: lead.phone,
              assignedTo: lead.assignedTo,
            )
          : '',
    ));
  }
  if (canCreateAppointment &&
      (lead.status == LeadStatus.interested ||
          lead.status == LeadStatus.visitScheduled ||
          lead.status == LeadStatus.negotiation)) {
    recommendations.add(JourneyRecommendation(
      title: l.journeyActionScheduleVisit,
      subtitle: l.journeyActionScheduleVisitDescription,
      tone: JourneyTone.info,
      actionLabel: l.newAppointment,
      actionRoute: RouteNames.appointmentCreateFor(
        relatedType: 'lead',
        relatedId: lead.id,
        relatedTitle: lead.fullName,
        relatedSubtitle: lead.phone,
        assignedTo: lead.assignedTo,
      ),
    ));
  }
  return recommendations;
}

List<JourneyRecommendation> clientJourneyRecommendations(
  AppLocalizations l,
  Client client, {
  required bool canCreateTask,
  required bool canCreateAppointment,
  required bool canEdit,
}) {
  final recommendations = <JourneyRecommendation>[];
  final updatedAt = client.updatedAt;
  if (updatedAt == null || _dateOnly(DateTime.now()).difference(_dateOnly(updatedAt)).inDays >= 14) {
    recommendations.add(JourneyRecommendation(
      title: l.journeyActionNoContact,
      subtitle: l.journeyActionNoContactDescription,
      tone: JourneyTone.warning,
      actionLabel: canCreateTask ? l.createTask : '',
      actionRoute: canCreateTask
          ? RouteNames.taskCreateFor(
              relatedType: 'client',
              relatedId: client.id,
              relatedTitle: client.fullName,
              relatedSubtitle: client.phone,
              assignedTo: client.assignedTo,
            )
          : '',
    ));
  }
  if (canCreateAppointment) {
    recommendations.add(JourneyRecommendation(
      title: l.journeyActionScheduleVisit,
      subtitle: l.journeyActionScheduleVisitDescription,
      tone: JourneyTone.info,
      actionLabel: l.newAppointment,
      actionRoute: RouteNames.appointmentCreateFor(
        relatedType: 'client',
        relatedId: client.id,
        relatedTitle: client.fullName,
        relatedSubtitle: client.phone,
        assignedTo: client.assignedTo,
      ),
    ));
  }
  if (canEdit && (client.preferredLocation.trim().isEmpty || client.preferredPropertyType.trim().isEmpty)) {
    recommendations.add(JourneyRecommendation(
      title: l.journeyActionCompleteProfile,
      subtitle: l.journeyActionCompleteProfileDescription,
      tone: JourneyTone.info,
      actionLabel: l.editClient,
      actionRoute: RouteNames.clientEdit(client.id),
    ));
  }
  return recommendations;
}

List<JourneyRecommendation> dealJourneyRecommendations(
  AppLocalizations l,
  Deal deal, {
  required bool canCreateTask,
  required bool canCreateAppointment,
  required bool canUpdateStage,
}) {
  final recommendations = <JourneyRecommendation>[];
  final open = deal.stage != DealStage.won && deal.stage != DealStage.lost;
  final updatedAt = deal.updatedAt ?? deal.createdAt;
  if (open && updatedAt != null && _dateOnly(DateTime.now()).difference(_dateOnly(updatedAt)).inDays >= 7) {
    recommendations.add(JourneyRecommendation(
      title: l.journeyActionStuckDeal,
      subtitle: l.journeyActionStuckDealDescription,
      tone: JourneyTone.danger,
      actionLabel: canUpdateStage ? l.updateStage : '',
      actionRoute: canUpdateStage ? RouteNames.dealDetails(deal.id) : '',
    ));
  }
  final closing = deal.closingDate;
  if (open && closing != null && _dateOnly(closing).isBefore(_dateOnly(DateTime.now()))) {
    recommendations.add(JourneyRecommendation(
      title: l.journeyActionClosingDue,
      subtitle: l.journeyActionClosingDueDescription,
      tone: JourneyTone.warning,
      actionLabel: canCreateTask ? l.createTask : '',
      actionRoute: canCreateTask
          ? RouteNames.taskCreateFor(
              relatedType: 'deal',
              relatedId: deal.id,
              relatedTitle: _dealTitle(deal),
              relatedSubtitle: deal.propertyTitle,
              assignedTo: deal.assignedTo,
            )
          : '',
    ));
  }
  if (canCreateAppointment && open) {
    recommendations.add(JourneyRecommendation(
      title: l.journeyActionScheduleVisit,
      subtitle: l.journeyActionScheduleVisitDescription,
      tone: JourneyTone.info,
      actionLabel: l.newAppointment,
      actionRoute: RouteNames.appointmentCreateFor(
        relatedType: 'deal',
        relatedId: deal.id,
        relatedTitle: _dealTitle(deal),
        relatedSubtitle: deal.propertyTitle,
        assignedTo: deal.assignedTo,
      ),
    ));
  }
  return recommendations;
}

JourneyTone _timelineTone(String type) {
  final normalized = type.toLowerCase();
  if (normalized.contains('archive')) return JourneyTone.neutral;
  if (normalized.contains('status') || normalized.contains('follow')) return JourneyTone.warning;
  if (normalized.contains('note')) return JourneyTone.info;
  return JourneyTone.neutral;
}

JourneyItemType _dealStageType(DealStage stage) {
  return switch (stage) {
    DealStage.won => JourneyItemType.dealWon,
    DealStage.lost => JourneyItemType.dealLost,
    _ => JourneyItemType.dealStageChanged,
  };
}

JourneyTone _dealTone(DealStage stage) {
  return switch (stage) {
    DealStage.won => JourneyTone.success,
    DealStage.lost => JourneyTone.danger,
    DealStage.negotiation || DealStage.proposal => JourneyTone.warning,
    _ => JourneyTone.info,
  };
}

String _dealTitle(Deal deal) {
  if (deal.clientName.trim().isNotEmpty) return deal.clientName.trim();
  if (deal.leadName.trim().isNotEmpty) return deal.leadName.trim();
  return deal.id;
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

List<JourneyItem> _dedupe(List<JourneyItem> items) {
  final map = <String, JourneyItem>{};
  for (final item in items) {
    map[item.id] = item;
  }
  return map.values.toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
}

bool _isTechnicalToken(String value) {
  return RegExp(r'^[a-zA-Z]+(_[a-zA-Z]+)+$').hasMatch(value.trim());
}

String _humanizeToken(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final spaced = trimmed
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
      .toLowerCase();
  return spaced.isEmpty ? trimmed : spaced[0].toUpperCase() + spaced.substring(1);
}
