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
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/properties_scope.dart';
import '../widgets/property_form.dart';

class CreatePropertyPage extends StatelessWidget {
  const CreatePropertyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PropertiesScope(child: _CreatePropertyView());
  }
}

class _CreatePropertyView extends StatefulWidget {
  const _CreatePropertyView();

  @override
  State<_CreatePropertyView> createState() => _CreatePropertyViewState();
}

class _CreatePropertyViewState extends State<_CreatePropertyView> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final userProfile = authState.userProfile;
    final user = authState.user;

    if (userProfile == null || user == null) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.properties,
        title: l.createProperty,
        child: AppErrorView(message: l.missingCompanyProfile),
      );
    }

    final companyId = userProfile.companyId;
    final uid = user.uid;
    final role = userProfile.role;
    final canCreate = PermissionService.can(role, AppPermission.createProperty);

    return CrmAppShell(
      selectedItem: CrmNavigationItem.properties,
      title: l.createProperty,
      child: !canCreate
          ? AppErrorView(message: l.permissionDenied)
          : BlocBuilder<PropertiesCubit, PropertiesState>(
              builder: (context, state) {
                final isSaving =
                    _isSubmitting || state.status == PropertiesStatus.saving;
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
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => context.go(RouteNames.properties),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(l.back),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PropertyForm(
                              companyId: companyId,
                              actorUid: uid,
                              isSaving: isSaving,
                              submitLabel: l.createProperty,
                              onSubmit: (
                                property, {
                                newImages = const [],
                                removedImageStoragePaths = const [],
                              }) async {
                                if (_isSubmitting) {
                                  return;
                                }
                                setState(() => _isSubmitting = true);
                                final cubit = context.read<PropertiesCubit>();
                                final success = await cubit.createProperty(
                                  companyId: companyId,
                                  property: property,
                                  newImages: newImages,
                                );
                                if (!mounted) {
                                  return;
                                }
                                setState(() => _isSubmitting = false);
                                if (success) {
                                  AppFeedback.success(
                                    context,
                                    l.propertyCreatedSuccessfully,
                                  );
                                  context.go(RouteNames.properties);
                                  return;
                                }
                                AppFeedback.error(
                                  context,
                                  localizeErrorMessage(l, cubit.state.message),
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
