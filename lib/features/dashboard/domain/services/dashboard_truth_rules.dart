import '../../../appointments/domain/entities/appointment.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../tasks/domain/entities/crm_task.dart';

/// Shared CRM truth table for dashboard KPIs, Sales Command, and list routes.
///
/// Track A rule: a lead contacted today is removed from urgent follow-up
/// queues for the rest of the company day. It returns when the next follow-up
/// is due again or when Missing Next Step applies on a later day.
abstract final class DashboardTruthRules {
  static const staleLeadDays = 5;
  static const highPriorityStaleLeadDays = 3;
  static const stuckDealDays = 14;

  static DateTime dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool isActiveLead(Lead lead) {
    return !lead.isArchived &&
        lead.status != LeadStatus.won &&
        lead.status != LeadStatus.lost;
  }

  static DateTime? leadLastTouchAt(Lead lead) {
    return latestDate([lead.lastContactAt, lead.updatedAt, lead.createdAt]);
  }

  static bool isHotLead(Lead lead) {
    return isActiveLead(lead) &&
        (lead.priority == LeadPriority.high ||
            lead.status == LeadStatus.interested ||
            lead.status == LeadStatus.visitScheduled ||
            lead.status == LeadStatus.negotiation);
  }

  static bool isContactedToday(Lead lead, DateTime today) {
    final lastContactAt = lead.lastContactAt;
    return lastContactAt != null &&
        dateOnly(lastContactAt) == dateOnly(today);
  }

  static bool isDueTodayFollowUpLead(Lead lead, DateTime today) {
    final followUpAt = lead.nextFollowUpAt;
    return isActiveLead(lead) &&
        !isContactedToday(lead, today) &&
        followUpAt != null &&
        dateOnly(followUpAt) == dateOnly(today);
  }

  static bool isOverdueFollowUpLead(Lead lead, DateTime today) {
    final followUpAt = lead.nextFollowUpAt;
    return isActiveLead(lead) &&
        !isContactedToday(lead, today) &&
        followUpAt != null &&
        dateOnly(followUpAt).isBefore(dateOnly(today));
  }

  static bool isUpcomingFollowUpLead(Lead lead, DateTime today) {
    final followUpAt = lead.nextFollowUpAt;
    return isActiveLead(lead) &&
        followUpAt != null &&
        dateOnly(followUpAt).isAfter(dateOnly(today));
  }

  static bool isLeadWithoutNextFollowUp(Lead lead) {
    return isActiveLead(lead) &&
        lead.nextFollowUpAt == null &&
        !isContactedToday(lead, DateTime.now());
  }

  static bool isContactedTodayWithOverdueFollowUp(Lead lead, DateTime today) {
    // Retained for older dashboard/filter routes, but Track A no longer treats
    // a contacted-today lead as overdue until a later follow-up is due again.
    return false;
  }

  static int? staleLeadAgeDays(
    Lead lead,
    DateTime today, {
    int staleDays = staleLeadDays,
  }) {
    if (!isActiveLead(lead)) {
      return null;
    }
    final lastTouch = leadLastTouchAt(lead);
    if (lastTouch == null) {
      return null;
    }
    final ageDays = dateOnly(today).difference(dateOnly(lastTouch)).inDays;
    return ageDays > staleDays ? ageDays : null;
  }

  static bool isStaleLead(
    Lead lead,
    DateTime today, {
    int staleDays = staleLeadDays,
  }) {
    return staleLeadAgeDays(lead, today, staleDays: staleDays) != null;
  }

  static bool isOpenTask(CrmTask task) {
    return task.isActive &&
        task.status != TaskStatus.completed &&
        task.status != TaskStatus.cancelled;
  }

  static bool isDueTodayTask(CrmTask task, DateTime today) {
    final dueDate = task.dueDate;
    return isOpenTask(task) &&
        dueDate != null &&
        dateOnly(dueDate) == dateOnly(today);
  }

  static bool isOverdueTask(CrmTask task, DateTime today) {
    final dueDate = task.dueDate;
    return isOpenTask(task) &&
        dueDate != null &&
        dateOnly(dueDate).isBefore(dateOnly(today));
  }

  static bool isUpcomingTask(CrmTask task, DateTime today) {
    final dueDate = task.dueDate;
    return isOpenTask(task) &&
        dueDate != null &&
        dateOnly(dueDate).isAfter(dateOnly(today));
  }

  static bool isOpenDeal(Deal deal) {
    return deal.isActive &&
        !deal.isArchived &&
        deal.stage != DealStage.won &&
        deal.stage != DealStage.lost;
  }

  static bool isDealAtRisk(
    Deal deal,
    DateTime now, {
    int staleDays = stuckDealDays,
  }) {
    if (!isOpenDeal(deal)) {
      return false;
    }
    final today = dateOnly(now);
    final closingDate = deal.closingDate;
    if (closingDate != null && !dateOnly(closingDate).isAfter(today)) {
      return true;
    }
    final lastActivity = deal.updatedAt ?? deal.createdAt;
    return lastActivity != null &&
        dateOnly(now).difference(dateOnly(lastActivity)).inDays >= staleDays;
  }

  static DateTime? dealClosedAt(Deal deal) {
    return deal.updatedAt ?? deal.closingDate ?? deal.createdAt;
  }

  static bool isDealWonThisMonth(Deal deal, DateTime now) {
    final closedAt = dealClosedAt(deal)?.toLocal();
    return deal.stage == DealStage.won &&
        closedAt != null &&
        closedAt.year == now.year &&
        closedAt.month == now.month;
  }

  static bool isMissedAppointment(Appointment appointment, DateTime now) {
    if (appointment.status == AppointmentStatus.completed ||
        appointment.status == AppointmentStatus.cancelled) {
      return false;
    }
    final openStatus = appointment.status == AppointmentStatus.scheduled ||
        appointment.status == AppointmentStatus.rescheduled;
    final endAt = (appointment.endAt ?? appointment.scheduledAt)?.toLocal();
    return appointment.status == AppointmentStatus.missed ||
        (openStatus && endAt != null && endAt.isBefore(now));
  }

  static bool isActiveProperty(Property property) {
    return !property.isArchived && property.status == PropertyStatus.available;
  }

  static DateTime? latestDate(List<DateTime?> dates) {
    DateTime? latest;
    for (final date in dates) {
      if (date == null) {
        continue;
      }
      if (latest == null || date.isAfter(latest)) {
        latest = date;
      }
    }
    return latest;
  }
}
