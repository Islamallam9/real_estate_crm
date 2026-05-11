import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/property.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/properties_scope.dart';
import '../widgets/property_form.dart';

class EditPropertyPage extends StatelessWidget {
  const EditPropertyPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return PropertiesScope(child: _EditPropertyView(propertyId: propertyId));
  }
}

class _EditPropertyView extends StatefulWidget {
  const _EditPropertyView({required this.propertyId});

  final String propertyId;

  @override
  State<_EditPropertyView> createState() => _EditPropertyViewState();
}

class _EditPropertyViewState extends State<_EditPropertyView> {
  @override
  void initState() {
    super.initState();
    final companyId = _companyId(context);
    if (companyId.isNotEmpty) {
      context.read<PropertiesCubit>().watchProperties(companyId: companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final role = authState.userProfile?.role ?? authState.user?.role;
    final canEdit =
        role != null && PermissionService.can(role, AppPermission.editProperty);
    final companyId = _companyId(context);
    final uid = authState.user?.uid ?? '';

    return CrmAppShell(
      selectedItem: CrmNavigationItem.properties,
      title: l.editProperty,
      child: !canEdit
          ? AppErrorView(message: l.permissionDenied)
          : BlocConsumer<PropertiesCubit, PropertiesState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status &&
                  (current.status == PropertiesStatus.saved ||
                      current.status == PropertiesStatus.failure),
              listener: (context, state) {
                if (state.status == PropertiesStatus.failure) {
                  AppFeedback.error(
                    context,
                    localizeErrorMessage(l, state.message),
                  );
                  return;
                }
                AppFeedback.success(
                  context,
                  l.propertyUpdatedSuccessfully,
                );
                context.go(RouteNames.properties);
              },
              builder: (context, state) {
                if (state.status == PropertiesStatus.initial ||
                    (state.status == PropertiesStatus.loading &&
                        state.properties.isEmpty)) {
                  return const AppLoading();
                }

                final property = _findPropertyById(
                  properties: state.properties,
                  propertyId: widget.propertyId,
                );
                if (property == null || companyId.isEmpty || uid.isEmpty) {
                  return AppErrorView(
                    message: localizationsErrorFallback(
                      l,
                      state.message,
                      l.unableToLoadPropertyForEdit,
                    ),
                    onRetry: () {
                      context.read<PropertiesCubit>().watchProperties(
                        companyId: companyId,
                      );
                    },
                  );
                }

                final isSaving = state.status == PropertiesStatus.saving;
                return ListView(
                      primary: true,
                      physics: const ClampingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      children: [
                        Align(
                          alignment: AlignmentDirectional.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 860),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PropertyForm(
                                  companyId: companyId,
                                  actorUid: uid,
                                  property: property,
                                  isSaving: isSaving,
                                  submitLabel: l.updateProperty,
                                  onSubmit: (updatedProperty) {
                                    context.read<PropertiesCubit>().updateProperty(
                                      companyId: companyId,
                                      property: updatedProperty,
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppButton(
                                  label: l.cancel,
                                  onPressed: isSaving
                                      ? null
                                      : () => context.go(RouteNames.properties),
                                ),
                              ],
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

String _companyId(BuildContext context) {
  final authState = context.read<AuthBloc>().state;
  return authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
}

String localizationsErrorFallback(
  AppLocalizations localizations,
  String? message,
  String fallback,
) {
  if (message == null || message.trim().isEmpty) {
    return fallback;
  }
  return localizeErrorMessage(localizations, message);
}

Property? _findPropertyById({
  required List<Property> properties,
  required String propertyId,
}) {
  for (final property in properties) {
    if (property.id == propertyId) {
      return property;
    }
  }
  return null;
}
