import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
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
import '../widgets/property_list_table.dart';

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
          if (authState.status == AuthStatus.initial ||
              authState.status == AuthStatus.loading) {
            return const AppLoading();
          }

          final companyId =
              authState.userProfile?.companyId ??
              authState.user?.companyId ??
              '';
          if (companyId.isEmpty) {
            return AppErrorView(message: localizations.missingCompanyProfile);
          }

          final role = authState.userProfile?.role ?? authState.user?.role;
          final canCreate = role != null
              ? PermissionService.can(role, AppPermission.createProperty)
              : false;

          return PropertiesScope(
            child: _PropertiesListContent(
              companyId: companyId,
              canCreate: canCreate,
              canEdit: role != null
                  ? PermissionService.can(role, AppPermission.editProperty)
                  : false,
            ),
          );
        },
      ),
    );
  }
}

class _PropertiesListContent extends StatefulWidget {
  const _PropertiesListContent({
    required this.companyId,
    required this.canCreate,
    required this.canEdit,
  });

  final String companyId;
  final bool canCreate;
  final bool canEdit;

  @override
  State<_PropertiesListContent> createState() => _PropertiesListContentState();
}

class _PropertiesListContentState extends State<_PropertiesListContent> {
  @override
  void initState() {
    super.initState();
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

    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
            ),
            if (state.status == PropertiesStatus.failure &&
                state.properties.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              AppErrorView(
                message: localizeErrorMessage(localizations, state.message),
                onRetry: () {
                  context.read<PropertiesCubit>().watchProperties(
                    companyId: widget.companyId,
                  );
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _PropertiesFilters(state: state),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _PropertiesBody(
                companyId: widget.companyId,
                state: state,
                canEdit: widget.canEdit,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PropertiesBody extends StatelessWidget {
  const _PropertiesBody({
    required this.companyId,
    required this.state,
    required this.canEdit,
  });

  final String companyId;
  final PropertiesState state;
  final bool canEdit;

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
            if (constraints.maxWidth < 720) {
              return ListView.separated(
                itemCount: state.filteredProperties.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return PropertyCard(
                    property: state.filteredProperties[index],
                    canEdit: canEdit,
                  );
                },
              );
            }

            return PropertyListTable(
              properties: state.filteredProperties,
              canEdit: canEdit,
            );
          },
        ),
        if (state.status == PropertiesStatus.saving)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.appBackground(
                context,
              ).withValues(alpha: 0.42),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppButton(
              label: l.clearFilters,
              variant: AppButtonVariant.secondary,
              onPressed: hasFilters ? cubit.clearFilters : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
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
      ],
    );
  }
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
