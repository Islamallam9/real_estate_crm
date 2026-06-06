import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/protected_company_session.dart';
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
import '../../../auth/presentation/bloc/auth_state.dart';
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState.protectedCompanySession;
        return PropertiesScope(
          key: ValueKey(
            session?.scopeKey('edit-property-scope') ??
                'edit-property-scope:loading',
          ),
          child: _EditPropertyView(propertyId: propertyId),
        );
      },
    );
  }
}

class _EditPropertyView extends StatefulWidget {
  const _EditPropertyView({required this.propertyId});

  final String propertyId;

  @override
  State<_EditPropertyView> createState() => _EditPropertyViewState();
}

class _EditPropertyViewState extends State<_EditPropertyView> {
  bool _isSubmitting = false;
  String? _watchKey;

  void _watchPropertyWhenReady(ProtectedCompanySession session) {
    final key = '${session.scopeKey('edit-property-watch')}:${widget.propertyId}';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<PropertiesCubit>().watchProperty(
      companyId: session.companyId,
      propertyId: widget.propertyId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState.protectedCompanySession;

    if (authState.isWaitingForProtectedCompanySession) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.properties,
        title: l.editProperty,
        child: const AppLoading(),
      );
    }

    final role = session?.profile.role;
    final canEdit =
        role != null && PermissionService.can(role, AppPermission.editProperty);
    final companyId = session?.companyId ?? '';
    final uid = session?.uid ?? '';
    if (session != null && canEdit) {
      _watchPropertyWhenReady(session);
    }

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
                  setState(() => _isSubmitting = false);
                  AppFeedback.error(
                    context,
                    localizeErrorMessage(l, state.message),
                  );
                  return;
                }
                setState(() => _isSubmitting = false);
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
                      context.read<PropertiesCubit>().watchProperty(
                        companyId: companyId,
                        propertyId: widget.propertyId,
                      );
                    },
                  );
                }

                final isSaving = _isSubmitting || state.status == PropertiesStatus.saving;
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
                                  onSubmit: (
                                    updatedProperty, {
                                    newImages = const [],
                                    removedImageStoragePaths = const [],
                                  }) {
                                    if (_isSubmitting) {
                                      return;
                                    }
                                    setState(() => _isSubmitting = true);
                                    context.read<PropertiesCubit>().updateProperty(
                                      companyId: companyId,
                                      property: updatedProperty,
                                      newImages: newImages,
                                      removedImageStoragePaths:
                                          removedImageStoragePaths,
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
