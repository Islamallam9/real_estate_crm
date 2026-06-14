/// Deterministic next action types for Masar's sales workflow.
///
/// Keep this file pure Dart. UI layers can translate these values into
/// localized labels, routes, and buttons without duplicating business rules.
enum SalesNextActionType {
  none,
  contactLead,
  followUp,
  scheduleAppointment,
  createAppointment,
  createDeal,
  assignLead,
  setNextStep,
  reviewStaleLead,
  futureFollowUp,
  managerReview,
  closeLost,
}
