import '../../../appointments/domain/entities/appointment.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../tasks/domain/entities/crm_task.dart';

/// Dashboard truth table for the v2.29.4 stabilization pass:
/// - Active leads: loaded, scoped, not archived, not won, not lost.
/// - Hot opportunities: loaded/scoped active leads with high priority or an
///   interested/visit/negotiation status.
/// - Overdue tasks: loaded/scoped active tasks, not completed/cancelled, with
///   due date before today.
/// - Open deals: loaded/scoped active deals, not archived, not won, not lost.
/// - Deal risks: loaded/scoped open deals with closing date due/past or no
///   activity for 14+ days. This matches the Deals page at-risk filter.
/// - Missed appointments: loaded/scoped explicit missed appointments or open
///   scheduled/rescheduled appointments whose end time has passed.
///
/// These are loaded-stream counts, not server aggregate totals. A later
/// server-side aggregate phase should replace them where exact full-scope
/// totals are required.
abstract final class DashboardTruthRules {
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

  static bool isHotLead(Lead lead) {
    return isActiveLead(lead) &&
        (lead.priority == LeadPriority.high ||
            lead.status == LeadStatus.interested ||
            lead.status == LeadStatus.visitScheduled ||
            lead.status == LeadStatus.negotiation);
  }

  static bool isDueTodayFollowUpLead(Lead lead, DateTime today) {
    final followUpAt = lead.nextFollowUpAt;
    return isActiveLead(lead) &&
        followUpAt != null &&
        dateOnly(followUpAt) == dateOnly(today);
  }

  static bool isOverdueFollowUpLead(Lead lead, DateTime today) {
    final followUpAt = lead.nextFollowUpAt;
    return isActiveLead(lead) &&
        followUpAt != null &&
        dateOnly(followUpAt).isBefore(dateOnly(today));
  }

  static bool isOpenTask(CrmTask task) {
    return task.isActive &&
        task.status != TaskStatus.completed &&
        task.status != TaskStatus.cancelled;
  }

  static bool isOverdueTask(CrmTask task, DateTime today) {
    final dueDate = task.dueDate;
    return isOpenTask(task) &&
        dueDate != null &&
        dateOnly(dueDate).isBefore(dateOnly(today));
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
        now.difference(lastActivity.toLocal()).inDays >= staleDays;
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
}
