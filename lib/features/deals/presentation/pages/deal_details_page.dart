import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/archive/archive_filter.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../core/widgets/masar_tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../journeys/domain/entities/connected_journey.dart';
import '../../../journeys/presentation/widgets/connected_journey_panel.dart';
import '../../../journeys/presentation/widgets/journey_builders.dart';
import '../../domain/entities/deal.dart';
import '../cubit/deals_cubit.dart';
import '../cubit/deals_state.dart';
import '../widgets/deal_card.dart';
import '../widgets/deals_scope.dart';
import 'deals_page.dart';

class DealDetailsPage extends StatelessWidget {
  const DealDetailsPage({super.key, required this.dealId});

  final String dealId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState.protectedCompanySession;
        return DealsScope(
          key: ValueKey(
            session?.scopeKey('deal-details-scope') ??
                'deal-details-scope:loading',
          ),
          child: _DealDetailsView(dealId: dealId),
        );
      },
    );
  }
}

class _DealDetailsView extends StatefulWidget {
  const _DealDetailsView({required this.dealId});

  final String dealId;

  @override
  State<_DealDetailsView> createState() => _DealDetailsViewState();
}

class _DealDetailsViewState extends State<_DealDetailsView> {
  String? _watchKey;
  int _selectedTab = 0;


  Future<void> _refreshDeal(ProtectedCompanySession? session) async {
    if (session == null) {
      return;
    }
    _watchKey = null;
    _watchDealWhenAllowed(session);
    await Future<void>.delayed(const Duration(milliseconds: 320));
  }

  void _watchDealWhenAllowed(ProtectedCompanySession session) {
    final role = session.profile.role;
    if (!PermissionService.can(role, AppPermission.viewDeals)) {
      return;
    }
    final archiveFilter = role == UserRole.admin || role == UserRole.manager
        ? ArchiveFilter.all
        : ArchiveFilter.active;
    final key = '${session.scopeKey('deal-details-watch')}:${archiveFilter.name}';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<DealsCubit>().watchDeals(
      companyId: session.companyId,
      role: role,
      currentUserId: session.uid,
      archiveFilter: archiveFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState.protectedCompanySession;

    if (authState.isWaitingForProtectedCompanySession) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.deals,
        title: l.dealDetails,
        child: const AppLoading(),
      );
    }

    final role = session?.profile.role;
    final companyId = session?.companyId ?? '';
    final uid = session?.uid ?? '';
    final canView =
        role != null && PermissionService.can(role, AppPermission.viewDeals);
    final canEdit = role != null && PermissionService.can(role, AppPermission.editDeal);
    final canArchive =
        role != null && PermissionService.can(role, AppPermission.archiveDeal);
    final canUpdateStage = role != null && role != UserRole.viewer && canView;
    if (session != null && canView) {
      _watchDealWhenAllowed(session);
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.deals,
      title: l.dealDetails,
      child: !canView
          ? AppErrorView(message: l.permissionDenied)
          : BlocListener<DealsCubit, DealsState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.lastAction != current.lastAction ||
            previous.message != current.message,
        listener: (context, state) {
          if (state.status == DealsStatus.saved &&
              state.lastAction == DealsAction.archiveDeal) {
            AppFeedback.success(context, l.dealArchivedSuccessfully);
            context.read<DealsCubit>().clearAction();
          } else if (state.status == DealsStatus.saved &&
              state.lastAction == DealsAction.restoreDeal) {
            AppFeedback.success(context, l.recordRestoredSuccessfully);
            context.read<DealsCubit>().clearAction();
          } else if (state.status == DealsStatus.saved &&
              state.lastAction == DealsAction.updateStage) {
            AppFeedback.success(context, l.dealStageUpdatedSuccessfully);
            context.read<DealsCubit>().clearAction();
          } else if (state.status == DealsStatus.failure &&
              state.lastAction != DealsAction.none) {
            AppFeedback.error(context, localizeDealError(l, state.message));
            context.read<DealsCubit>().clearAction();
          }
        },
        child: BlocBuilder<DealsCubit, DealsState>(
          builder: (context, state) {
          if ((state.status == DealsStatus.initial ||
                  state.status == DealsStatus.loading) &&
              state.deals.isEmpty) {
            return const AppLoading();
          }
          final deal = _findDeal(state.deals, widget.dealId);
          if (deal == null || companyId.isEmpty || uid.isEmpty) {
            return AppErrorView(message: l.dealNotFoundMessage);
          }

          return RefreshIndicator(
            onRefresh: () => _refreshDeal(session),
            child: ListView(
              primary: true,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _title(l, deal),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (deal.isArchived)
                              AppStatusBadge(
                                label: l.archived,
                                tone: AppStatusTone.neutral,
                              ),
                            AppStatusBadge(
                              label: dealStageLabel(l, deal.stage),
                              tone: dealStageTone(deal.stage),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppButton(
                          label: l.backToDeals,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => context.go(RouteNames.deals),
                        ),
                        if (canUpdateStage && !deal.isArchived)
                          AppButton(
                            label: l.updateStage,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => showDealStageDialog(
                              context,
                              companyId: companyId,
                              deal: deal,
                              updatedBy: uid,
                            ),
                          ),
                        if (canEdit && !deal.isArchived)
                          AppButton(
                            label: l.editDeal,
                            onPressed: () =>
                                context.go(RouteNames.dealEdit(deal.id)),
                          ),
                        if (canArchive && !deal.isArchived)
                          AppButton(
                            label: l.archiveDeal,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => showArchiveDealDialog(
                              context,
                              companyId: companyId,
                              deal: deal,
                              updatedBy: uid,
                            ),
                          ),
                        if (canArchive && deal.isArchived)
                          AppButton(
                            label: l.restore,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => showRestoreDealDialog(
                              context,
                              companyId: companyId,
                              deal: deal,
                              updatedBy: uid,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MasarSwitchTabBar(
                      compact: true,
                      selectedIndex: _selectedTab,
                      onChanged: (index) =>
                          setState(() => _selectedTab = index),
                      tabs: [
                        MasarSwitchTabItem(
                          label: l.details,
                          icon: Icons.info_outline_rounded,
                        ),
                        MasarSwitchTabItem(
                          label: l.connectedJourneyTitle,
                          icon: Icons.route_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _selectedTab == 0
                          ? Column(
                              key: const ValueKey('deal-details-tab'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _DetailsSection(
                                  title: l.dealSummary,
                                  children: [
                                    _detail(
                                      context,
                                      l.dealStage,
                                      dealStageLabel(l, deal.stage),
                                    ),
                                    _detail(
                                      context,
                                      l.expectedValue,
                                      _formatNumber(
                                        context,
                                        deal.expectedValue,
                                      ),
                                    ),
                                    _detail(
                                      context,
                                      l.commission,
                                      _formatNumber(context, deal.commission),
                                    ),
                                    _detail(
                                      context,
                                      l.closingDate,
                                      _formatOptionalDate(
                                        context,
                                        deal.closingDate,
                                        l,
                                      ),
                                    ),
                                    if (deal.stage == DealStage.lost)
                                      _detail(
                                        context,
                                        l.lostReason,
                                        _value(l, deal.lostReason),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _DetailsSection(
                                  title: l.client,
                                  children: [
                                    _detail(
                                      context,
                                      l.fullName,
                                      _value(l, deal.clientName),
                                    ),
                                    _detail(
                                      context,
                                      l.email,
                                      _value(l, deal.clientEmail),
                                    ),
                                    _detail(
                                      context,
                                      l.phone,
                                      _value(l, deal.clientPhone),
                                    ),
                                  ],
                                ),
                                if (deal.leadName.trim().isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  _DetailsSection(
                                    title: l.lead,
                                    children: [
                                      _detail(
                                        context,
                                        l.leadName,
                                        _value(l, deal.leadName),
                                      ),
                                      _detail(
                                        context,
                                        l.phone,
                                        _value(l, deal.leadPhone),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.md),
                                _DetailsSection(
                                  title: l.property,
                                  children: [
                                    _detail(
                                      context,
                                      l.propertyTitle,
                                      _value(l, deal.propertyTitle),
                                    ),
                                    _detail(
                                      context,
                                      l.location,
                                      _value(l, deal.propertyLocation),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _DetailsSection(
                                  title: l.assignedAgent,
                                  children: [
                                    _detail(
                                      context,
                                      l.fullName,
                                      _value(l, deal.assignedToName),
                                    ),
                                    _detail(
                                      context,
                                      l.email,
                                      _value(l, deal.assignedToEmail),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _DetailsSection(
                                  title: l.notes,
                                  children: [
                                    _detail(
                                      context,
                                      l.notes,
                                      _value(l, deal.notes),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _DetailsSection(
                                  title: l.auditInfo,
                                  children: [
                                    _detail(
                                      context,
                                      l.createdAt,
                                      _formatOptionalDate(
                                        context,
                                        deal.createdAt,
                                        l,
                                      ),
                                    ),
                                    _detail(
                                      context,
                                      l.updatedAt,
                                      _formatOptionalDate(
                                        context,
                                        deal.updatedAt,
                                        l,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : ConnectedJourneyPanel(
                              key: const ValueKey('deal-journey-tab'),
                              recordType: JourneyRecordType.deal,
                              recordId: deal.id,
                              scope: JourneyQueryScope(
                                companyId: companyId,
                                currentUserId: uid,
                                role: role ?? UserRole.viewer,
                                teamId: session?.profile.teamId ?? '',
                                managerId: session?.profile.managerId ?? '',
                              ),
                              baseItems: dealBaseJourneyItems(deal),
                              recommendations: dealJourneyRecommendations(
                                l,
                                deal,
                                canCreateTask: role != null &&
                                    PermissionService.can(
                                      role,
                                      AppPermission.createTask,
                                    ),
                                canCreateAppointment: role != null &&
                                    PermissionService.can(
                                      role,
                                      AppPermission.createAppointment,
                                    ),
                                canUpdateStage: canUpdateStage,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          );
          },
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

Widget _detail(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, maxLines: 3, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

Deal? _findDeal(List<Deal> deals, String dealId) {
  for (final deal in deals) {
    if (deal.id == dealId) {
      return deal;
    }
  }
  return null;
}

String _title(AppLocalizations l, Deal deal) {
  final client = deal.clientName.trim();
  final property = deal.propertyTitle.trim();
  if (client.isEmpty && property.isEmpty) {
    return l.dealDetails;
  }
  if (client.isEmpty) {
    return property;
  }
  if (property.isEmpty) {
    return client;
  }
  return '$client - $property';
}

String _value(AppLocalizations l, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? l.notAvailable : trimmed;
}

String _formatNumber(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(localeName).format(value);
}

String _formatOptionalDate(
  BuildContext context,
  DateTime? value,
  AppLocalizations l,
) {
  if (value == null) {
    return l.notAvailable;
  }
  final localeName = Localizations.localeOf(context).toString();
  return DateFormat.yMd(localeName).add_jm().format(value.toLocal());
}
