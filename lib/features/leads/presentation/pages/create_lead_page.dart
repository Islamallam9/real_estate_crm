import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/lead_form.dart';
import '../widgets/leads_scope.dart';

class CreateLeadPage extends StatelessWidget {
  const CreateLeadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LeadsScope(child: _CreateLeadView());
  }
}

class _CreateLeadView extends StatelessWidget {
  const _CreateLeadView();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final companyId =
        authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
    final uid = authState.user?.uid ?? '';

    return CrmAppShell(
      selectedItem: CrmNavigationItem.leads,
      title: localizations.createLead,
      child: BlocListener<LeadsCubit, LeadsState>(
        listenWhen: (previous, current) {
          return previous.status != current.status &&
              current.status == LeadsStatus.saved;
        },
        listener: (context, state) => context.go(RouteNames.leads),
        child: companyId.isEmpty || uid.isEmpty
            ? AppErrorView(message: localizations.authErrorProfileMissing)
            : _CreateLeadFormContent(companyId: companyId, uid: uid),
      ),
    );
  }
}

class _CreateLeadFormContent extends StatelessWidget {
  const _CreateLeadFormContent({required this.companyId, required this.uid});

  final String companyId;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ScrollConfiguration(
      behavior: const _LeadFormScrollBehavior(),
      child: ListView(
        primary: true,
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => context.go(RouteNames.leads),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(localizations.back),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RepaintBoundary(
                    child: BlocSelector<LeadsCubit, LeadsState, bool>(
                      selector: (state) => state.status == LeadsStatus.saving,
                      builder: (context, isSaving) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LeadForm(
                              companyId: companyId,
                              createdBy: uid,
                              isSaving: isSaving,
                              onSubmit: (lead) {
                                context.read<LeadsCubit>().createLead(
                                  companyId: companyId,
                                  lead: lead,
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: localizations.cancel,
                              onPressed: isSaving
                                  ? null
                                  : () => context.go(RouteNames.leads),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadFormScrollBehavior extends ScrollBehavior {
  const _LeadFormScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
