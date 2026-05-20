import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/masar_brand.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/public_auth_actions.dart';
import '../../data/datasources/company_registration_remote_data_source.dart';
import '../../data/repositories/company_registration_repository_impl.dart';
import '../../domain/entities/company_invitation_preview.dart';
import '../../domain/usecases/accept_company_invitation_usecase.dart';
import '../../domain/usecases/validate_company_invitation_usecase.dart';
import '../cubit/company_registration_cubit.dart';
import '../cubit/company_registration_state.dart';

class RegisterCompanyPage extends StatelessWidget {
  const RegisterCompanyPage({super.key, this.initialCode});

  final String? initialCode;

  static Widget withDependencies({String? initialCode}) {
    final remoteDataSource = FirebaseCompanyRegistrationRemoteDataSource();
    final repository = CompanyRegistrationRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    return BlocProvider(
      create: (_) => CompanyRegistrationCubit(
        validateInvitationUseCase: ValidateCompanyInvitationUseCase(repository),
        acceptInvitationUseCase: AcceptCompanyInvitationUseCase(repository),
      ),
      child: RegisterCompanyPage(initialCode: initialCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _RegisterCompanyView(initialCode: initialCode ?? '');
  }
}

enum _RegistrationStep { invitation, company, admin, review }

class _RegisterCompanyView extends StatefulWidget {
  const _RegisterCompanyView({required this.initialCode});

  final String initialCode;

  @override
  State<_RegisterCompanyView> createState() => _RegisterCompanyViewState();
}

class _RegisterCompanyViewState extends State<_RegisterCompanyView> {
  final _invitationFormKey = GlobalKey<FormState>();
  final _companyFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  final _code = TextEditingController();
  final _companyName = TextEditingController();
  final _companyPhone = TextEditingController();
  final _companyCity = TextEditingController();
  final _companyWebsite = TextEditingController();
  final _adminName = TextEditingController();
  final _adminEmail = TextEditingController();
  final _adminPhone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _timezone = TextEditingController(text: 'Africa/Cairo');

  var _step = _RegistrationStep.invitation;
  var _locale = 'en';
  var _autoValidatedInitialCode = false;

  String get _companySlug => AppValidators.slugFromName(_companyName.text);

  @override
  void initState() {
    super.initState();
    _code.text = _resolveInitialInvitationCode(widget.initialCode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoValidatedInitialCode || _code.text.trim().isEmpty) {
      return;
    }
    _autoValidatedInitialCode = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _validateInvitation();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _companyName.dispose();
    _companyPhone.dispose();
    _companyCity.dispose();
    _companyWebsite.dispose();
    _adminName.dispose();
    _adminEmail.dispose();
    _adminPhone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _timezone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocListener<CompanyRegistrationCubit, CompanyRegistrationState>(
      listenWhen: (previous, current) {
        return previous.status != current.status &&
            current.status == CompanyRegistrationStatus.completed;
      },
      listener: (context, state) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.companyRegistrationCompleted)),
        );
        context.go(
          state.result?.signedIn == true ? RouteNames.dashboard : RouteNames.login,
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.appBackground(context),
        body: SafeArea(
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: AlignmentDirectional.topEnd.resolve(
                      Directionality.of(context),
                    ),
                    radius: 1.1,
                    colors: [
                      AppColors.primaryColor(context).withValues(alpha: 0.13),
                      AppColors.appBackground(context),
                    ],
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      72,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface(context),
                          border: Border.all(
                            color: AppColors.borderColor(context),
                          ),
                          borderRadius: AppRadius.xLarge,
                          boxShadow:
                              Theme.of(context).brightness == Brightness.dark
                                  ? null
                                  : AppShadows.subtle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: BlocBuilder<CompanyRegistrationCubit,
                              CompanyRegistrationState>(
                            builder: (context, state) {
                              final saving = state.status ==
                                      CompanyRegistrationStatus.submitting ||
                                  state.status ==
                                      CompanyRegistrationStatus.validating;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _Header(),
                                  const SizedBox(height: AppSpacing.lg),
                                  _StepRail(step: _step),
                                  const SizedBox(height: AppSpacing.lg),
                                  if (state.message != null) ...[
                                    _MessageBox(
                                      message:
                                          _localizedInviteMessage(l, state),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: _stepContent(state, saving),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: AppSpacing.md,
                start: AppSpacing.md,
                child: _PublicBackButton(
                  tooltip: l.back,
                  onPressed: () => context.go(RouteNames.onboarding),
                ),
              ),
              const PositionedDirectional(
                top: AppSpacing.md,
                end: AppSpacing.md,
                child: PublicAuthActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepContent(CompanyRegistrationState state, bool saving) {
    return switch (_step) {
      _RegistrationStep.invitation => _InvitationStep(
          key: const ValueKey('invitation'),
          formKey: _invitationFormKey,
          code: _code,
          saving: saving,
          preview: state.preview,
          onValidate: _validateInvitation,
          onNext: state.preview?.valid == true
              ? () => setState(() => _step = _RegistrationStep.company)
              : null,
        ),
      _RegistrationStep.company => _CompanyStep(
          key: const ValueKey('company'),
          formKey: _companyFormKey,
          companyName: _companyName,
          companyPhone: _companyPhone,
          companyCity: _companyCity,
          companyWebsite: _companyWebsite,
          timezone: _timezone,
          locale: _locale,
          saving: saving,
          onLocaleChanged: (value) => setState(() => _locale = value),
          onBack: () => setState(() => _step = _RegistrationStep.invitation),
          onNext: () {
            FocusScope.of(context).unfocus();
            if (_companyFormKey.currentState!.validate()) {
              setState(() => _step = _RegistrationStep.admin);
            }
          },
        ),
      _RegistrationStep.admin => _AdminStep(
          key: const ValueKey('admin'),
          formKey: _adminFormKey,
          adminName: _adminName,
          adminEmail: _adminEmail,
          adminPhone: _adminPhone,
          password: _password,
          confirmPassword: _confirmPassword,
          saving: saving,
          onBack: () => setState(() => _step = _RegistrationStep.company),
          onNext: () {
            FocusScope.of(context).unfocus();
            if (_adminFormKey.currentState!.validate()) {
              setState(() => _step = _RegistrationStep.review);
            }
          },
        ),
      _RegistrationStep.review => _ReviewStep(
          key: const ValueKey('review'),
          preview: state.preview,
          companyName: _companyName.text.trim(),
          companySlug: _companySlug,
          companyPhone: _companyPhone.text.trim(),
          companyCity: _companyCity.text.trim(),
          companyWebsite: _companyWebsite.text.trim(),
          adminName: _adminName.text.trim(),
          adminEmail: _adminEmail.text.trim(),
          adminPhone: _adminPhone.text.trim(),
          locale: _locale,
          timezone: _timezone.text.trim(),
          saving: saving,
          onBack: () => setState(() => _step = _RegistrationStep.admin),
          onSubmit: _submit,
        ),
    };
  }

  Future<void> _validateInvitation() async {
    FocusScope.of(context).unfocus();
    if (!(_invitationFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final valid = await context
        .read<CompanyRegistrationCubit>()
        .validateInvitation(_code.text.trim());
    if (!mounted) return;
    if (valid) {
      final preview = context.read<CompanyRegistrationCubit>().state.preview;
      if (preview != null) {
        setState(() {
          _locale = preview.locale;
          _timezone.text = preview.timezone;
        });
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l = AppLocalizations.of(context)!;
    final validationMessage = _reviewValidationMessage(l);
    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationMessage)),
      );
      return;
    }
    final slug = _companySlug;
    await context.read<CompanyRegistrationCubit>().acceptInvitation(
          invitationCode: _code.text.trim(),
          companyName: _companyName.text.trim(),
          companySlug: slug,
          companyPhone: _companyPhone.text.trim(),
          companyCity: _companyCity.text.trim(),
          companyWebsite: _companyWebsite.text.trim(),
          adminFullName: _adminName.text.trim(),
          adminPhone: _adminPhone.text.trim(),
          adminEmail: _adminEmail.text.trim(),
          password: _password.text,
          confirmPassword: _confirmPassword.text,
          locale: _locale,
          timezone: _timezone.text.trim(),
        );
  }

  String? _reviewValidationMessage(AppLocalizations l) {
    return AppValidators.invitationCode(_code.text, l) ??
        AppValidators.companyName(_companyName.text, l) ??
        AppValidators.phone(_companyPhone.text, l) ??
        AppValidators.requiredText(_companyCity.text, l) ??
        AppValidators.optionalUrl(_companyWebsite.text, l) ??
        AppValidators.companyId(_companySlug, l) ??
        AppValidators.personName(_adminName.text, l) ??
        AppValidators.email(_adminEmail.text, l) ??
        AppValidators.phone(_adminPhone.text, l) ??
        AppValidators.password(_password.text, l) ??
        AppValidators.confirmPassword(_confirmPassword.text, _password.text, l) ??
        AppValidators.requiredText(_timezone.text, l);
  }
}

String _resolveInitialInvitationCode(String rawInitialCode) {
  final directCode = rawInitialCode.trim();
  if (directCode.isNotEmpty) {
    return directCode;
  }

  // Defensive fallback for old/bad invitation links shaped like
  // /register-company?code=MASAR-XXXX#/register-company. The corrected
  // links use /#/register-company?code=MASAR-XXXX, but this keeps already
  // copied links usable.
  final uriCode = Uri.base.queryParameters['code']?.trim() ?? '';
  if (uriCode.isNotEmpty) {
    return uriCode;
  }

  final fragment = Uri.base.fragment;
  final questionIndex = fragment.indexOf('?');
  if (questionIndex == -1 || questionIndex == fragment.length - 1) {
    return '';
  }
  final fragmentQuery = Uri.splitQueryString(fragment.substring(questionIndex + 1));
  return fragmentQuery['code']?.trim() ?? '';
}


class _PublicBackButton extends StatelessWidget {
  const _PublicBackButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context).withValues(alpha: 0.92),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryColor(context).withValues(alpha: 0.10),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: AppColors.primaryColor(context).withValues(alpha: 0.22),
            ),
          ),
          child: const MasarBrandMark(size: 32),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.loginBrandName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                l.registerYourCompany,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepRail extends StatelessWidget {
  const _StepRail({required this.step});

  final _RegistrationStep step;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final steps = [
      l.invitationCode,
      l.companyDetails,
      l.adminAccount,
      l.reviewAndCreate,
    ];
    final activeIndex = _RegistrationStep.values.indexOf(step);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var index = 0; index < steps.length; index++)
          Chip(
            avatar: CircleAvatar(
              radius: 11,
              child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
            ),
            label: Text(steps[index]),
            backgroundColor: index <= activeIndex
                ? AppColors.primaryColor(context).withValues(alpha: 0.12)
                : AppColors.appBackground(context),
            side: BorderSide(color: AppColors.borderColor(context)),
          ),
      ],
    );
  }
}

class _InvitationStep extends StatelessWidget {
  const _InvitationStep({
    super.key,
    required this.formKey,
    required this.code,
    required this.saving,
    required this.preview,
    required this.onValidate,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController code;
  final bool saving;
  final CompanyInvitationPreview? preview;
  final VoidCallback onValidate;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: code,
            label: l.enterInvitationCode,
            prefixIcon: Icons.vpn_key_outlined,
            enabled: !saving,
            validator: (value) => AppValidators.invitationCode(value, l),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: l.validateInvitation,
                icon: Icons.verified_outlined,
                isLoading: saving,
                onPressed: saving ? null : onValidate,
              ),
              AppButton(
                label: l.next,
                icon: Icons.arrow_forward,
                variant: AppButtonVariant.secondary,
                onPressed: saving ? null : onNext,
              ),
            ],
          ),
          if (preview?.valid == true) ...[
            const SizedBox(height: AppSpacing.md),
            _InvitationPreviewBox(preview: preview!),
          ],
        ],
      ),
    );
  }
}

class _CompanyStep extends StatelessWidget {
  const _CompanyStep({
    super.key,
    required this.formKey,
    required this.companyName,
    required this.companyPhone,
    required this.companyCity,
    required this.companyWebsite,
    required this.timezone,
    required this.locale,
    required this.saving,
    required this.onLocaleChanged,
    required this.onBack,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController companyName;
  final TextEditingController companyPhone;
  final TextEditingController companyCity;
  final TextEditingController companyWebsite;
  final TextEditingController timezone;
  final String locale;
  final bool saving;
  final ValueChanged<String> onLocaleChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.createYourAdminPassword,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.adminPasswordHelp,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TwoColumn(
            children: [
              AppTextField(
                controller: companyName,
                label: l.companyName,
                enabled: !saving,
                validator: (value) => AppValidators.companyName(value, l),
              ),
              _GeneratedCompanyIdHint(companyName: companyName),
              AppTextField(
                controller: companyPhone,
                label: l.companyPhone,
                keyboardType: TextInputType.phone,
                enabled: !saving,
                validator: (value) => AppValidators.phone(value, l),
              ),
              AppTextField(
                controller: companyCity,
                label: l.cityLocation,
                enabled: !saving,
                validator: (value) => AppValidators.requiredText(value, l),
              ),
              AppTextField(
                controller: companyWebsite,
                label: l.website,
                keyboardType: TextInputType.url,
                enabled: !saving,
                validator: (value) => AppValidators.optionalUrl(value, l),
              ),
              AppDropdown<String>(
                label: l.preferredLanguage,
                value: locale,
                items: const ['en', 'ar'],
                itemLabelBuilder: (value) => value == 'ar' ? l.arabic : l.english,
                onChanged: onLocaleChanged,
                enabled: !saving,
              ),
              AppTextField(
                controller: timezone,
                label: l.timezone,
                enabled: !saving,
                validator: (value) => AppValidators.requiredText(value, l),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _StepActions(onBack: onBack, onNext: onNext, saving: saving),
        ],
      ),
    );
  }
}

class _GeneratedCompanyIdHint extends StatelessWidget {
  const _GeneratedCompanyIdHint({required this.companyName});

  final TextEditingController companyName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: companyName,
      builder: (context, _) {
        final slug = AppValidators.slugFromName(companyName.text);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryColor(context).withValues(alpha: 0.07),
            border: Border.all(
              color: AppColors.primaryColor(context).withValues(alpha: 0.22),
            ),
            borderRadius: AppRadius.large,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.companyIdGeneratedAutomatically,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                slug.isEmpty ? l.companyIdGeneratedMessage : _isolate(slug),
                style: TextStyle(color: AppColors.textSecondaryColor(context)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminStep extends StatelessWidget {
  const _AdminStep({
    super.key,
    required this.formKey,
    required this.adminName,
    required this.adminEmail,
    required this.adminPhone,
    required this.password,
    required this.confirmPassword,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController adminName;
  final TextEditingController adminEmail;
  final TextEditingController adminPhone;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: Column(
        children: [
          _TwoColumn(
            children: [
              AppTextField(
                controller: adminName,
                label: l.adminFullName,
                enabled: !saving,
                validator: (value) => AppValidators.personName(value, l),
              ),
              AppTextField(
                controller: adminEmail,
                label: l.adminEmail,
                keyboardType: TextInputType.emailAddress,
                enabled: !saving,
                validator: (value) => AppValidators.email(value, l),
              ),
              AppTextField(
                controller: adminPhone,
                label: l.adminPhone,
                keyboardType: TextInputType.phone,
                enabled: !saving,
                validator: (value) => AppValidators.phone(value, l),
              ),
              AppTextField(
                controller: password,
                label: l.companyAdminPassword,
                obscureText: true,
                enabled: !saving,
                validator: (value) => AppValidators.password(value, l),
              ),
              AppTextField(
                controller: confirmPassword,
                label: l.confirmCompanyAdminPassword,
                obscureText: true,
                enabled: !saving,
                validator: (value) => AppValidators.confirmPassword(
                  value,
                  password.text,
                  l,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _StepActions(onBack: onBack, onNext: onNext, saving: saving),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.preview,
    required this.companyName,
    required this.companySlug,
    required this.companyPhone,
    required this.companyCity,
    required this.companyWebsite,
    required this.adminName,
    required this.adminEmail,
    required this.adminPhone,
    required this.locale,
    required this.timezone,
    required this.saving,
    required this.onBack,
    required this.onSubmit,
  });

  final CompanyInvitationPreview? preview;
  final String companyName;
  final String companySlug;
  final String companyPhone;
  final String companyCity;
  final String companyWebsite;
  final String adminName;
  final String adminEmail;
  final String adminPhone;
  final String locale;
  final String timezone;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (preview != null) _InvitationPreviewBox(preview: preview!),
        const SizedBox(height: AppSpacing.md),
        _SummaryPanel(
          title: l.companyDetails,
          rows: {
            l.companyName: companyName,
            l.companyIdSlug: companySlug,
            l.companyPhone: companyPhone,
            l.cityLocation: companyCity,
            l.website: companyWebsite.isEmpty ? l.notAvailable : companyWebsite,
            l.preferredLanguage: locale,
            l.timezone: timezone,
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _SummaryPanel(
          title: l.adminAccount,
          rows: {
            l.adminFullName: adminName,
            l.adminEmail: adminEmail,
            l.adminPhone: adminPhone,
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              label: l.back,
              icon: Icons.arrow_back,
              variant: AppButtonVariant.secondary,
              onPressed: saving ? null : onBack,
            ),
            AppButton(
              label: l.createWorkspace,
              icon: Icons.add_circle_outline,
              isLoading: saving,
              onPressed: saving ? null : onSubmit,
            ),
          ],
        ),
      ],
    );
  }
}

class _InvitationPreviewBox extends StatelessWidget {
  const _InvitationPreviewBox({required this.preview});

  final CompanyInvitationPreview preview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final enabledFeatures = preview.features.entries
        .where((entry) => entry.value)
        .map((entry) => _registrationFeatureLabel(l, entry.key))
        .join(', ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryColor(context).withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.primaryColor(context).withValues(alpha: 0.24),
        ),
        borderRadius: AppRadius.large,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _InfoChip(label: l.invitationValid, value: preview.planName),
          _InfoChip(label: l.userLimit, value: preview.userLimit.toString()),
          _InfoChip(
            label: l.storageLimitMb,
            value: preview.storageLimitMb.toString(),
          ),
          _InfoChip(
            label: l.expiresAt,
            value: preview.expiresAt == null
                ? l.notAvailable
                : MaterialLocalizations.of(context).formatShortDate(
                    preview.expiresAt!,
                  ),
          ),
          if (enabledFeatures.isNotEmpty)
            _InfoChip(label: l.features, value: enabledFeatures),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in rows.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 170,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: AppColors.textSecondaryColor(context),
                      ),
                    ),
                  ),
                  Expanded(child: Text(_isolate(entry.value))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepActions extends StatelessWidget {
  const _StepActions({
    required this.onBack,
    required this.onNext,
    required this.saving,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppButton(
          label: l.back,
          icon: Icons.arrow_back,
          variant: AppButtonVariant.secondary,
          onPressed: saving ? null : onBack,
        ),
        AppButton(
          label: l.next,
          icon: Icons.arrow_forward,
          onPressed: saving ? null : onNext,
        ),
      ],
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        if (!wide) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      side: BorderSide(color: AppColors.borderColor(context)),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.errorColor(context).withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.errorColor(context).withValues(alpha: 0.28),
        ),
        borderRadius: AppRadius.large,
      ),
      child: Text(message),
    );
  }
}

String _isolate(String value) {
  final clean = value.trim();
  return clean.isEmpty ? clean : '\u2068$clean\u2069';
}

String _localizedInviteMessage(
  AppLocalizations l,
  CompanyRegistrationState state,
) {
  final message = state.message?.trim();
  if (message != null && message.isNotEmpty) {
    return _localizedRegistrationError(l, message);
  }
  final status = state.preview?.status;
  return switch (status) {
    'expired' => l.invitationExpired,
    'used' => l.invitationAlreadyUsed,
    'revoked' => l.invitationRevoked,
    _ => l.invitationInvalid,
  };
}

String _localizedRegistrationError(AppLocalizations l, String key) {
  return switch (key) {
    'invitation-invalid' => l.registrationInvitationInvalid,
    'invitation-expired' => l.registrationInvitationExpired,
    'invitation-used' => l.registrationInvitationUsed,
    'invitation-revoked' => l.registrationInvitationRevoked,
    'invitation-limit-reached' => l.registrationInvitationLimitReached,
    'admin-email-already-exists' => l.adminEmailAlreadyExists,
    'company-id-already-exists' => l.companyNameAlreadyRegistered,
    'invalid-admin-email' => l.invalidEmail,
    'weak-password' => l.weakPassword,
    'email-password-auth-disabled' => l.emailPasswordAuthDisabled,
    'unable-to-create-admin' => l.unableToCreateAdminUser,
    'unable-to-create-company' => l.unableToCreateWorkspace,
    'unable-to-create-workspace' => l.unableToCreateWorkspace,
    'unable-to-complete-registration' => l.unableToCompleteRegistration,
    'registration-conflict' => l.registrationConflict,
    'registration-already-started-or-conflict' => l.registrationConflict,
    AppErrorMessages.unableToConnect => l.unableToConnect,
    AppErrorMessages.permissionDenied => l.permissionDenied,
    _ => l.unableToCompleteRegistration,
  };
}

String _registrationFeatureLabel(AppLocalizations l, String feature) {
  return switch (feature) {
    'leads' => l.leads,
    'clients' => l.clients,
    'properties' => l.properties,
    'tasks' => l.tasks,
    'appointments' => l.appointments,
    'deals' => l.deals,
    'reports' => l.reports,
    'auditLogs' => l.auditLogs,
    'notifications' => l.notifications,
    _ => feature,
  };
}
