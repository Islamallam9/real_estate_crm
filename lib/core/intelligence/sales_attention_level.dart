/// Business attention level used by Masar's deterministic sales intelligence.
///
/// Keep this file pure Dart. It must not import Flutter, Firebase, or feature
/// presentation code so it can be reused by Leads, Sales Command, and details.
enum SalesAttentionLevel {
  none,
  info,
  soon,
  today,
  urgent,
  manager,
}

extension SalesAttentionLevelX on SalesAttentionLevel {
  bool get isActionable => this != SalesAttentionLevel.none;
}
