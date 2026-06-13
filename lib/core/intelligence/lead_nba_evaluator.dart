import 'sales_attention_level.dart';
import 'sales_next_action_type.dart';

/// Pure-Dart input for Lead Next Best Action evaluation.
///
/// This intentionally uses primitive/status strings instead of importing the
/// Lead entity. The evaluator lives in core and must not depend on feature
/// layers, Flutter, Firebase, or UI code.
class LeadNbaInput {
  const LeadNbaInput({
    required this.status,
    required this.priority,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    required this.now,
    this.lastContactAt,
    this.nextActionAt,
    this.assignedTo = '',
    this.canViewUnassignedLeads = false,
    this.hasAppointment = false,
    this.hasDeal = false,
    this.staleDays = 14,
    this.highPriorityStaleDays = 3,
  });

  final String status;
  final String priority;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime now;
  final DateTime? lastContactAt;
  final DateTime? nextActionAt;
  final String assignedTo;
  final bool canViewUnassignedLeads;
  final bool hasAppointment;
  final bool hasDeal;
  final int staleDays;
  final int highPriorityStaleDays;
}

class LeadNbaDecision {
  const LeadNbaDecision({
    required this.attentionLevel,
    required this.nextActionType,
    this.reason = '',
    this.dueAt,
    this.relatedAt,
    this.ageDays,
  });

  final SalesAttentionLevel attentionLevel;
  final SalesNextActionType nextActionType;
  final String reason;
  final DateTime? dueAt;
  final DateTime? relatedAt;
  final int? ageDays;

  bool get isActionableNow => attentionLevel.isActionable;

  static const none = LeadNbaDecision(
    attentionLevel: SalesAttentionLevel.none,
    nextActionType: SalesNextActionType.none,
  );
}

abstract final class LeadNbaEvaluator {
  static LeadNbaDecision evaluate(LeadNbaInput input) {
    if (_isClosedOrArchived(input)) {
      return LeadNbaDecision.none;
    }

    if (input.assignedTo.trim().isEmpty && input.canViewUnassignedLeads) {
      return const LeadNbaDecision(
        attentionLevel: SalesAttentionLevel.today,
        nextActionType: SalesNextActionType.assignLead,
        reason: 'unassignedLead',
      );
    }

    if (_wasContactedToday(input)) {
      return const LeadNbaDecision(
        attentionLevel: SalesAttentionLevel.none,
        nextActionType: SalesNextActionType.none,
        reason: 'contactedToday',
      );
    }

    final nextActionAt = input.nextActionAt;
    if (nextActionAt != null) {
      final nextActionDay = _dateOnly(nextActionAt);
      final today = _dateOnly(input.now);
      if (nextActionDay.isBefore(today)) {
        return LeadNbaDecision(
          attentionLevel: SalesAttentionLevel.urgent,
          nextActionType: SalesNextActionType.followUp,
          reason: 'overdueFollowUp',
          dueAt: nextActionAt,
          ageDays: today.difference(nextActionDay).inDays,
        );
      }
      if (nextActionDay == today) {
        return LeadNbaDecision(
          attentionLevel: SalesAttentionLevel.today,
          nextActionType: SalesNextActionType.followUp,
          reason: 'dueTodayFollowUp',
          dueAt: nextActionAt,
        );
      }

      return LeadNbaDecision(
        attentionLevel: SalesAttentionLevel.none,
        nextActionType: SalesNextActionType.futureFollowUp,
        reason: 'futureFollowUp',
        dueAt: nextActionAt,
      );
    }

    if (_isNew(input) && input.lastContactAt == null) {
      return const LeadNbaDecision(
        attentionLevel: SalesAttentionLevel.today,
        nextActionType: SalesNextActionType.contactLead,
        reason: 'contactLead',
      );
    }

    if (_isInterested(input) && !input.hasAppointment) {
      return const LeadNbaDecision(
        attentionLevel: SalesAttentionLevel.soon,
        nextActionType: SalesNextActionType.scheduleAppointment,
        reason: 'scheduleAppointment',
      );
    }

    if (_isVisitScheduled(input) && !input.hasAppointment) {
      return const LeadNbaDecision(
        attentionLevel: SalesAttentionLevel.soon,
        nextActionType: SalesNextActionType.createAppointment,
        reason: 'createAppointment',
      );
    }

    if (_isNegotiation(input) && !input.hasDeal) {
      return const LeadNbaDecision(
        attentionLevel: SalesAttentionLevel.today,
        nextActionType: SalesNextActionType.createDeal,
        reason: 'createDeal',
      );
    }

    if (_needsNextStep(input)) {
      return const LeadNbaDecision(
        attentionLevel: SalesAttentionLevel.soon,
        nextActionType: SalesNextActionType.setNextStep,
        reason: 'missingNextStep',
      );
    }

    final staleAge = _staleAgeDays(input);
    if (staleAge != null) {
      return LeadNbaDecision(
        attentionLevel: input.priority == 'high'
            ? SalesAttentionLevel.urgent
            : SalesAttentionLevel.soon,
        nextActionType: SalesNextActionType.reviewStaleLead,
        reason: 'staleLead',
        relatedAt: _lastMeaningfulActivityAt(input),
        ageDays: staleAge,
      );
    }

    return LeadNbaDecision.none;
  }

  static bool _isClosedOrArchived(LeadNbaInput input) {
    final status = input.status;
    return input.isArchived || status == 'won' || status == 'lost';
  }

  static bool _isNew(LeadNbaInput input) => input.status == 'new';

  static bool _isContacted(LeadNbaInput input) {
    return input.status == 'contacted';
  }

  static bool _wasContactedToday(LeadNbaInput input) {
    final lastContactAt = input.lastContactAt;
    if (lastContactAt == null) {
      return false;
    }
    return _dateOnly(lastContactAt) == _dateOnly(input.now);
  }

  static bool _isInterested(LeadNbaInput input) {
    return input.status == 'interested';
  }

  static bool _isVisitScheduled(LeadNbaInput input) {
    return input.status == 'visitScheduled';
  }

  static bool _isNegotiation(LeadNbaInput input) {
    return input.status == 'negotiation';
  }

  static bool _needsNextStep(LeadNbaInput input) {
    return input.lastContactAt != null &&
        (input.status == 'contacted' ||
            input.status == 'interested' ||
            input.status == 'visitScheduled' ||
            input.status == 'negotiation');
  }

  static int? _staleAgeDays(LeadNbaInput input) {
    final lastActivity = _lastMeaningfulActivityAt(input);
    final threshold = input.priority == 'high'
        ? input.highPriorityStaleDays
        : input.staleDays;
    final ageDays = _dateOnly(input.now).difference(_dateOnly(lastActivity)).inDays;
    return ageDays > threshold ? ageDays : null;
  }

  static DateTime _lastMeaningfulActivityAt(LeadNbaInput input) {
    final dates = <DateTime?>[
      input.lastContactAt,
      input.updatedAt,
      input.createdAt,
    ];
    DateTime? latest;
    for (final date in dates) {
      if (date == null) {
        continue;
      }
      if (latest == null || date.isAfter(latest)) {
        latest = date;
      }
    }
    return latest ?? input.createdAt;
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
