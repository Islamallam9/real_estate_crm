import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/masar_refresh_indicator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/property.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/properties_scope.dart';
import '../widgets/property_card.dart';
import '../widgets/property_labels.dart';
import '../../../../core/widgets/masar_loading_view.dart';

class PropertiesPage extends StatelessWidget {
  const PropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.properties,
      title: localizations.properties,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.isWaitingForProtectedCompanySession) {
            return const AppLoading();
          }

          final session = authState.protectedCompanySession;
          if (session == null) {
            return const AppLoading();
          }

          final profile = session.profile;
          final companyId = session.companyId;
          if (companyId.isEmpty) {
            return AppErrorView(message: localizations.missingCompanyProfile);
          }

          final role = profile.role;
          final canCreate = PermissionService.can(role, AppPermission.createProperty);
          final canDeactivate = PermissionService.can(role, AppPermission.editProperty);

          return PropertiesScope(
            key: ValueKey(session.scopeKey('properties-scope')),
            child: _PropertiesListContent(
              key: ValueKey(session.scopeKey('properties-content')),
              companyId: companyId,
              canCreate: canCreate,
              canEdit: PermissionService.can(role, AppPermission.editProperty),
              canDeactivate: canDeactivate,
              uid: profile.uid,
            ),
          );
        },
      ),
    );
  }
}

class _PropertiesListContent extends StatefulWidget {
  const _PropertiesListContent({
    super.key,
    required this.companyId,
    required this.canCreate,
    required this.canEdit,
    required this.canDeactivate,
    required this.uid,
  });

  final String companyId;
  final bool canCreate;
  final bool canEdit;
  final bool canDeactivate;
  final String uid;

  @override
  State<_PropertiesListContent> createState() => _PropertiesListContentState();
}

class _PropertiesListContentState extends State<_PropertiesListContent> {
  @override
  void initState() {
    super.initState();
    _watchProperties();
  }

  @override
  void didUpdateWidget(covariant _PropertiesListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      _watchProperties();
    }
  }

  void _watchProperties() {
    context.read<PropertiesCubit>().watchProperties(
      companyId: widget.companyId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return BlocListener<PropertiesCubit, PropertiesState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.lastAction != current.lastAction ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == PropertiesStatus.saved &&
            state.lastAction == PropertiesAction.deactivateProperty) {
          AppFeedback.success(
            context,
            localizations.propertyDeactivatedSuccessfully,
          );
          context.read<PropertiesCubit>().clearAction();
          return;
        }
        if (state.status == PropertiesStatus.failure &&
            state.lastAction == PropertiesAction.deactivateProperty &&
            (state.message?.isNotEmpty ?? false)) {
          AppFeedback.error(
            context,
            localizeErrorMessage(localizations, state.message),
          );
          context.read<PropertiesCubit>().clearAction();
        }
      },
      child: BlocBuilder<PropertiesCubit, PropertiesState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 720;

              final header = Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.propertiesSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppButton(
                    label: localizations.createProperty,
                    onPressed: widget.canCreate
                        ? () => context.go(RouteNames.propertiesCreate)
                        : null,
                  ),
                ],
              );

              final failureBanner =
              state.status == PropertiesStatus.failure && state.properties.isNotEmpty
                  ? AppErrorView(
                message: localizeErrorMessage(localizations, state.message),
                onRetry: () {
                  context.read<PropertiesCubit>().watchProperties(
                    companyId: widget.companyId,
                  );
                },
              )
                  : null;

              final filters = _PropertiesFilters(state: state);

              final body = _PropertiesBody(
                companyId: widget.companyId,
                state: state,
                canEdit: widget.canEdit,
                canDeactivate: widget.canDeactivate,
                uid: widget.uid,
              );

              if (isMobile) {
                return SingleChildScrollView(
                  physics: const MasarRefreshPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      if (failureBanner != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        failureBanner,
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      filters,
                      const SizedBox(height: AppSpacing.sm),
                      body,
                      const SizedBox(height: 96),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  if (failureBanner != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    failureBanner,
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  filters,
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(child: body),
                ],
              );
            },
          );
      },
      ),
    );
  }
}

class _PropertiesBody extends StatelessWidget {
  const _PropertiesBody({
    required this.companyId,
    required this.state,
    required this.canEdit,
    required this.canDeactivate,
    required this.uid,
  });

  final String companyId;
  final PropertiesState state;
  final bool canEdit;
  final bool canDeactivate;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    if ((state.status == PropertiesStatus.initial ||
            state.status == PropertiesStatus.loading) &&
        state.properties.isEmpty) {
      return const AppLoading();
    }

    if (state.status == PropertiesStatus.failure && state.properties.isEmpty) {
      return AppErrorView(
        message: localizeErrorMessage(localizations, state.message),
        onRetry: () {
          context.read<PropertiesCubit>().watchProperties(
            companyId: companyId,
          );
        },
      );
    }

    if (state.properties.isEmpty) {
      return AppEmptyState(
        title: localizations.noProperties,
        message: localizations.propertiesSubtitle,
        icon: Icons.business_outlined,
      );
    }

    if (state.filteredProperties.isEmpty) {
      return AppEmptyState(
        title: localizations.noMatchingProperties,
        message: localizations.adjustPropertyFiltersHint,
        icon: Icons.search_off_outlined,
      );
    }

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 1080
                ? 4
                : constraints.maxWidth >= 760
                ? 3
                : 2;

            final cardExtent = constraints.maxWidth >= 1080
                ? 318.0
                : constraints.maxWidth >= 760
                ? 312.0
                : 305.0;

            final isNestedInPageScroll = !constraints.hasBoundedHeight;

            return GridView.builder(
              shrinkWrap: isNestedInPageScroll,
              physics: isNestedInPageScroll
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              cacheExtent: 600,
              itemCount: state.filteredProperties.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: cardExtent,
              ),
              itemBuilder: (context, index) {
                return PropertyCard(
                  property: state.filteredProperties[index],
                  canEdit: canEdit,
                  canDeactivate: canDeactivate,
                  onDeactivate: (property) => _confirmDeactivate(
                    context,
                    property: property,
                    companyId: companyId,
                    updatedBy: uid,
                  ),
                );
              },
            );
          },
        ),
        if (state.status == PropertiesStatus.saving)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.appBackground(
                context,
              ).withValues(alpha: 0.42),
              child: const Center(child: MasarLogoLoader(size: 42)),
            ),
          ),
      ],
    );
  }
}

Future<void> _confirmDeactivate(
  BuildContext context, {
  required Property property,
  required String companyId,
  required String updatedBy,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<PropertiesCubit>();
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l.deactivateProperty),
            content: Text(l.deactivatePropertyConfirmation),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l.cancel),
              ),
              AppButton(
                label: l.deactivate,
                isLoading: isSubmitting,
                onPressed: () async {
                  setDialogState(() => isSubmitting = true);
                  await cubit.deactivateProperty(
                    companyId: companyId,
                    propertyId: property.id,
                    updatedBy: updatedBy,
                  );
                  final completed =
                      cubit.state.status == PropertiesStatus.saved &&
                      cubit.state.lastAction ==
                          PropertiesAction.deactivateProperty;
                  if (completed && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    return;
                  }
                  if (dialogContext.mounted) {
                    setDialogState(() => isSubmitting = false);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

class _PropertiesFilters extends StatelessWidget {
  const _PropertiesFilters({required this.state});

  final PropertiesState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<PropertiesCubit>();
    final hasFilters =
        state.searchQuery.trim().isNotEmpty ||
            state.propertyTypeFilter != null ||
            state.listingTypeFilter != null ||
            state.statusFilter != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: cubit.setSearchQuery,
                      decoration: InputDecoration(
                        labelText: l.searchProperties,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: l.filters,
                    icon: Icons.tune,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      _showPropertiesFiltersSheet(context, state: state);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.propertiesResultsCount(
                        state.filteredProperties.length,
                        state.properties.length,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                    ),
                  ),
                  if (hasFilters)
                    TextButton(
                      onPressed: cubit.clearFilters,
                      child: Text(l.clearFilters),
                    ),
                ],
              ),
              _PropertiesActiveFilterChips(state: state),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: cubit.setSearchQuery,
                    decoration: InputDecoration(
                      labelText: l.searchProperties,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: l.filters,
                  icon: Icons.tune,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _showPropertiesFiltersSheet(
                    context,
                    state: state,
                  ),
                ),
                if (hasFilters) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: l.clearFilters,
                    variant: AppButtonVariant.secondary,
                    onPressed: cubit.clearFilters,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.propertiesResultsCount(
                state.filteredProperties.length,
                state.properties.length,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
            _PropertiesActiveFilterChips(state: state),
          ],
        );
      },
    );
  }
}

class _PropertiesActiveFilterChips extends StatelessWidget {
  const _PropertiesActiveFilterChips({required this.state});

  final PropertiesState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<PropertiesCubit>();
    final chips = <Widget>[
      if (state.propertyTypeFilter != null)
        _ActiveFilterChip(
          label: propertyTypeLabel(l, state.propertyTypeFilter!),
          onDeleted: () => cubit.setPropertyTypeFilter(null),
        ),
      if (state.listingTypeFilter != null)
        _ActiveFilterChip(
          label: propertyListingTypeLabel(l, state.listingTypeFilter!),
          onDeleted: () => cubit.setListingTypeFilter(null),
        ),
      if (state.statusFilter != null)
        _ActiveFilterChip(
          label: propertyStatusLabel(l, state.statusFilter!),
          onDeleted: () => cubit.setStatusFilter(null),
        ),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: chips,
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textPrimaryColor(context),
            fontWeight: FontWeight.w700,
          ),
      backgroundColor: AppColors.primaryColor(context).withValues(alpha: 0.08),
      side: BorderSide(
        color: AppColors.primaryColor(context).withValues(alpha: 0.18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _PropertiesFilterControls extends StatelessWidget {
  const _PropertiesFilterControls({required this.state});

  final PropertiesState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<PropertiesCubit>();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SizedBox(
          width: 210,
          child: AppDropdown<_FilterOption<PropertyType>>(
            label: l.propertyType,
            value: _FilterOption.fromValue(state.propertyTypeFilter),
            items: _filterOptions(PropertyType.values),
            itemLabelBuilder: (option) => option.isAll
                ? l.allPropertyTypes
                : propertyTypeLabel(l, option.value!),
            onChanged: (option) {
              cubit.setPropertyTypeFilter(option.value);
            },
          ),
        ),
        SizedBox(
          width: 210,
          child: AppDropdown<_FilterOption<PropertyListingType>>(
            label: l.listingType,
            value: _FilterOption.fromValue(state.listingTypeFilter),
            items: _filterOptions(PropertyListingType.values),
            itemLabelBuilder: (option) => option.isAll
                ? l.allListingTypes
                : propertyListingTypeLabel(l, option.value!),
            onChanged: (option) {
              cubit.setListingTypeFilter(option.value);
            },
          ),
        ),
        SizedBox(
          width: 210,
          child: AppDropdown<_FilterOption<PropertyStatus>>(
            label: l.status,
            value: _FilterOption.fromValue(state.statusFilter),
            items: _filterOptions(PropertyStatus.values),
            itemLabelBuilder: (option) => option.isAll
                ? l.allStatuses
                : propertyStatusLabel(l, option.value!),
            onChanged: (option) {
              cubit.setStatusFilter(option.value);
            },
          ),
        ),
      ],
    );
  }
}

Future<void> _showPropertiesFiltersSheet(
    BuildContext context, {
      required PropertiesState state,
    }) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<PropertiesCubit>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.filters,
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _PropertiesFilterControls(state: state),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l.clearFilters,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    cubit.clearFilters();
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _FilterOption<T> {
  const _FilterOption._({required this.value, required this.isAll});

  const _FilterOption.all() : this._(value: null, isAll: true);

  const _FilterOption.value(T value) : this._(value: value, isAll: false);

  factory _FilterOption.fromValue(T? value) {
    return value == null
        ? _FilterOption<T>.all()
        : _FilterOption<T>.value(value);
  }

  final T? value;
  final bool isAll;

  @override
  bool operator ==(Object other) {
    return other is _FilterOption<T> &&
        other.isAll == isAll &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(value, isAll);
}

List<_FilterOption<T>> _filterOptions<T>(List<T> values) {
  return [
    _FilterOption<T>.all(),
    for (final value in values) _FilterOption<T>.value(value),
  ];
}
