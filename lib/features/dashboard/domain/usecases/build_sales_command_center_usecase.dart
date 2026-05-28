import '../../../../core/constants/role_constants.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../tasks/domain/entities/crm_task.dart';
import '../entities/sales_command_center.dart';
import '../services/sales_command_center_rules.dart';

class BuildSalesCommandCenterUseCase {
  const BuildSalesCommandCenterUseCase({
    SalesCommandCenterRules rules = const SalesCommandCenterRules(),
  }) : _rules = rules;

  final SalesCommandCenterRules _rules;

  SalesCommandSummary call({
    required UserRole role,
    required DateTime now,
    required List<Lead> leads,
    required List<CrmTask> tasks,
    required List<Deal> deals,
    required List<Appointment> appointments,
    required bool includeLeads,
    required bool includeTasks,
    required bool includeDeals,
    required bool includeAppointments,
    required bool canViewUnassignedLeads,
  }) {
    return _rules.build(
      SalesCommandCenterRuleInput(
        role: role,
        now: now,
        leads: leads,
        tasks: tasks,
        deals: deals,
        appointments: appointments,
        includeLeads: includeLeads,
        includeTasks: includeTasks,
        includeDeals: includeDeals,
        includeAppointments: includeAppointments,
        canViewUnassignedLeads: canViewUnassignedLeads,
      ),
    );
  }
}
