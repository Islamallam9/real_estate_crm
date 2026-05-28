import '../entities/dashboard_analytics.dart';
import '../services/dashboard_analytics_rules.dart';

export '../services/dashboard_analytics_rules.dart' show DashboardAnalyticsInput;

class BuildDashboardAnalyticsUseCase {
  const BuildDashboardAnalyticsUseCase({
    DashboardAnalyticsRules rules = const DashboardAnalyticsRules(),
  }) : _rules = rules;

  final DashboardAnalyticsRules _rules;

  DashboardAnalytics call(DashboardAnalyticsInput input) {
    return _rules.build(input);
  }
}
