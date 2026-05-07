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
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/properties_scope.dart';
import '../widgets/property_card.dart';
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
  });

  final String companyId;
  final bool canCreate;

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
            Expanded(
              child: _PropertiesBody(
                companyId: widget.companyId,
                state: state,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PropertiesBody extends StatelessWidget {
  const _PropertiesBody({required this.companyId, required this.state});

  final String companyId;
  final PropertiesState state;

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

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return ListView.separated(
                itemCount: state.properties.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return PropertyCard(property: state.properties[index]);
                },
              );
            }

            return PropertyListTable(properties: state.properties);
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
