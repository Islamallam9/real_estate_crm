import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../journeys/domain/entities/connected_journey.dart';
import '../../../journeys/presentation/widgets/connected_journey_panel.dart';
import '../../../journeys/presentation/widgets/journey_builders.dart';
import '../../../property_matching/presentation/widgets/matching_properties_card.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/presentation/widgets/property_labels.dart';
import '../../domain/entities/client.dart';
import '../cubit/clients_cubit.dart';
import '../cubit/clients_state.dart';
import '../widgets/clients_scope.dart';
import '../../../../core/widgets/masar_loading_view.dart';
import '../../../../core/widgets/masar_tab_bar.dart';


String _preferredPropertyTypeDisplayLabel(AppLocalizations l, String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return l.notAvailable;
  }
  for (final type in PropertyType.values) {
    if (type.name == normalized) {
      return propertyTypeLabel(l, type);
    }
  }
  return value.trim();
}

class ClientDetailsPage extends StatelessWidget {
  const ClientDetailsPage({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState.protectedCompanySession;
        return ClientsScope(
          key: ValueKey(
            session?.scopeKey('client-details-scope') ??
                'client-details-scope:loading',
          ),
          child: _ClientDetailsView(clientId: clientId),
        );
      },
    );
  }
}

class _ClientDetailsView extends StatefulWidget {
  const _ClientDetailsView({required this.clientId});

  final String clientId;

  @override
  State<_ClientDetailsView> createState() => _ClientDetailsViewState();
}

class _ClientDetailsViewState extends State<_ClientDetailsView> {
  String? _watchKey;
  int _selectedTab = 0;


  Future<void> _refreshClient(String companyId) async {
    if (companyId.isEmpty || widget.clientId.isEmpty) {
      return;
    }
    context.read<ClientsCubit>().watchClient(
      companyId: companyId,
      clientId: widget.clientId,
    );
    await Future<void>.delayed(const Duration(milliseconds: 320));
  }

  void _watchClientWhenReady(ProtectedCompanySession session) {
    if (widget.clientId.isEmpty) {
      return;
    }
    final key =
        '${session.scopeKey('client-details-watch')}:${widget.clientId}';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<ClientsCubit>().watchClient(
      companyId: session.companyId,
      clientId: widget.clientId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState.protectedCompanySession;

    if (authState.isWaitingForProtectedCompanySession) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.clients,
        title: l.clientDetails,
        child: const AppLoading(),
      );
    }

    final role = session?.profile.role;
    final uid = session?.uid ?? '';
    final companyId = session?.companyId ?? '';
    final canView =
        role != null && PermissionService.can(role, AppPermission.viewClients);
    final canEdit =
        role != null && PermissionService.can(role, AppPermission.editClient);
    if (session != null && canView) {
      _watchClientWhenReady(session);
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.clients,
      title: l.clientDetails,
      child: !canView || companyId.isEmpty || widget.clientId.isEmpty
          ? AppErrorView(message: l.permissionDenied)
          : BlocBuilder<ClientsCubit, ClientsState>(
              builder: (context, state) {
                if (state.status == ClientsStatus.initial ||
                    (state.status == ClientsStatus.loading &&
                        state.selectedClient == null)) {
                  return const AppLoading();
                }

                if (state.status == ClientsStatus.failure &&
                    state.selectedClient == null) {
                  return AppErrorView(
                    message: localizeErrorMessage(l, state.message),
                    onRetry: () {
                      context.read<ClientsCubit>().watchClient(
                        companyId: companyId,
                        clientId: widget.clientId,
                      );
                    },
                  );
                }

                final client = state.selectedClient;
                if (client == null) {
                  return AppErrorView(
                    message: l.clientNotFoundMessage,
                    onRetry: () {
                      context.read<ClientsCubit>().watchClient(
                        companyId: companyId,
                        clientId: widget.clientId,
                      );
                    },
                  );
                }

                if (role == UserRole.salesAgent && client.assignedTo != uid) {
                  return AppErrorView(message: l.permissionDenied);
                }

                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () => _refreshClient(companyId),
                      child: ListView(
                        primary: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppSpacing.lg,
                        ),
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _valueOrNotAvailable(l, client.fullName),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (client.isArchived) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    AppStatusBadge(
                                      label: l.archived,
                                      tone: AppStatusTone.neutral,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  AppButton(
                                    label: l.backToClients,
                                    variant: AppButtonVariant.secondary,
                                    onPressed: () =>
                                        context.go(RouteNames.clients),
                                  ),
                                  if (canEdit && !client.isArchived)
                                    AppButton(
                                      label: l.editClient,
                                      onPressed: () => context.go(
                                        RouteNames.clientEdit(client.id),
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
                                        key: const ValueKey('client-details-tab'),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _DetailsSection(
                                            title: l.contactInformation,
                                            children: [
                                              _detail(
                                                context,
                                                l.fullNameUpdated,
                                                _valueOrNotAvailable(
                                                  l,
                                                  client.fullName,
                                                ),
                                              ),
                                              _detail(
                                                context,
                                                l.phone,
                                                _valueOrNotAvailable(
                                                  l,
                                                  client.phone,
                                                ),
                                              ),
                                              _detail(
                                                context,
                                                l.email,
                                                _valueOrNotAvailable(
                                                  l,
                                                  client.email,
                                                ),
                                              ),
                                              _detail(
                                                context,
                                                l.assignedToLabel,
                                                _assigneeDisplayLabel(
                                                  l,
                                                  client,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.md,
                                          ),
                                          _DetailsSection(
                                            title: l.clientPreferences,
                                            children: [
                                              _detail(
                                                context,
                                                l.budgetMin,
                                                _formatOptionalNumber(
                                                  context,
                                                  l,
                                                  client.budgetMin,
                                                ),
                                              ),
                                              _detail(
                                                context,
                                                l.budgetMax,
                                                _formatOptionalNumber(
                                                  context,
                                                  l,
                                                  client.budgetMax,
                                                ),
                                              ),
                                              _detail(
                                                context,
                                                l.preferredLocation,
                                                _valueOrNotAvailable(
                                                  l,
                                                  client.preferredLocation,
                                                ),
                                              ),
                                              _detail(
                                                context,
                                                l.preferredPropertyType,
                                                _preferredPropertyTypeDisplayLabel(
                                                  l,
                                                  client.preferredPropertyType,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.md,
                                          ),
                                          MatchingPropertiesCard(
                                            companyId: companyId,
                                            preferredLocation:
                                                client.preferredLocation,
                                            preferredPropertyType:
                                                client.preferredPropertyType,
                                            budgetMin: client.budgetMin,
                                            budgetMax: client.budgetMax,
                                            isClient: true,
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.md,
                                          ),
                                          _DetailsSection(
                                            title: l.notes,
                                            children: [
                                              _detail(
                                                context,
                                                l.notes,
                                                _valueOrNotAvailable(
                                                  l,
                                                  client.notes,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.md,
                                          ),
                                          _DetailsSection(
                                            title: l.auditInfo,
                                            children: [
                                              _detail(
                                                context,
                                                l.createdAt,
                                                _formatOptionalDate(
                                                  context,
                                                  l,
                                                  client.createdAt,
                                                ),
                                              ),
                                              _detail(
                                                context,
                                                l.updatedAt,
                                                _formatOptionalDate(
                                                  context,
                                                  l,
                                                  client.updatedAt,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    : ConnectedJourneyPanel(
                                        key: const ValueKey(
                                          'client-journey-tab',
                                        ),
                                        recordType: JourneyRecordType.client,
                                        recordId: client.id,
                                        scope: JourneyQueryScope(
                                          companyId: companyId,
                                          currentUserId: uid,
                                          role: role ?? UserRole.viewer,
                                          teamId: session?.profile.teamId ?? '',
                                          managerId:
                                              session?.profile.managerId ?? '',
                                        ),
                                        baseItems:
                                            clientBaseJourneyItems(client),
                                        recommendations:
                                            clientJourneyRecommendations(
                                          l,
                                          client,
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
                                          canEdit: canEdit,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ),
                    if (state.status == ClientsStatus.loading)
                      Positioned.fill(
                        child: AbsorbPointer(
                          child: Container(
                            color: AppColors.appBackground(
                              context,
                            ).withValues(alpha: 0.55),
                            child: const Center(
                              child: MasarLogoLoader(size: 42),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
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
        Text(
          value,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
        ),
      ],
    ),
  );
}

String _valueOrNotAvailable(AppLocalizations l, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? l.notAvailable : trimmed;
}

String _assigneeDisplayLabel(AppLocalizations l, Client client) {
  final assignedTo = client.assignedTo.trim();
  if (assignedTo.isEmpty) {
    return l.unassigned;
  }
  final name = client.assignedToName.trim();
  if (name.isNotEmpty) {
    return name;
  }
  final email = client.assignedToEmail.trim();
  if (email.isNotEmpty) {
    return email;
  }
  return l.assignedUserUnavailable;
}

String _formatOptionalDate(
  BuildContext context,
  AppLocalizations l,
  DateTime? value,
) {
  if (value == null) {
    return l.notAvailable;
  }
  final localeName = Localizations.localeOf(context).toString();
  return DateFormat.yMd(localeName).add_jm().format(value.toLocal());
}

String _formatOptionalNumber(
  BuildContext context,
  AppLocalizations l,
  num? value,
) {
  if (value == null) {
    return l.notAvailable;
  }
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(localeName).format(value);
}
