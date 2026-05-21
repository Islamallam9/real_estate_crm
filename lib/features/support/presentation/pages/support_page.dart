import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/masar_refresh_indicator.dart';
import '../../../../core/utils/external_link_opener.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../core/widgets/masar_tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/datasources/support_remote_data_source.dart';
import '../../data/repositories/support_repository_impl.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/support_ticket_draft.dart';
import '../../domain/usecases/create_feedback_usecase.dart';
import '../../domain/usecases/create_support_ticket_usecase.dart';
import '../../domain/usecases/watch_my_support_tickets_usecase.dart';
import '../cubit/support_cubit.dart';
import '../cubit/support_state.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static Widget withDependencies() {
    final repository = SupportRepositoryImpl(
      remoteDataSource: FirebaseSupportRemoteDataSource(),
    );
    return BlocProvider(
      create: (_) => SupportCubit(
        createSupportTicketUseCase: CreateSupportTicketUseCase(repository),
        createFeedbackUseCase: CreateFeedbackUseCase(repository),
        watchMySupportTicketsUseCase: WatchMySupportTicketsUseCase(repository),
      ),
      child: const SupportPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return CrmAppShell(
      selectedItem: CrmNavigationItem.support,
      title: l.supportCenter,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final profile = authState.userProfile;
          final user = authState.user;
          if (authState.status == AuthStatus.initial ||
              authState.status == AuthStatus.loading) {
            return const AppLoading();
          }
          if (profile == null || user == null) {
            return AppEmptyState(
              icon: Icons.support_agent_outlined,
              title: l.supportCenter,
              message: l.missingCompanyProfile,
            );
          }
          final company = authState.companyMetadata;
          final companyName = company == null
              ? profile.companyId
              : (company.displayName.trim().isEmpty
                  ? company.name
                  : company.displayName);

          return _SupportBody(
            companyId: profile.companyId,
            companyName: companyName,
            userId: user.uid,
            userName: profile.fullName,
            userEmail: profile.email.isEmpty ? user.email ?? '' : profile.email,
            userRole: RoleConstants.toValue(profile.role),
          );
        },
      ),
    );
  }
}

class _SupportBody extends StatefulWidget {
  const _SupportBody({
    required this.companyId,
    required this.companyName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });

  final String companyId;
  final String companyName;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;

  @override
  State<_SupportBody> createState() => _SupportBodyState();
}

class _SupportBodyState extends State<_SupportBody> {
  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().watchMyTickets(widget.userId);
  }

  @override
  void didUpdateWidget(covariant _SupportBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      context.read<SupportCubit>().watchMyTickets(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocListener<SupportCubit, SupportState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SupportStatus.failure &&
          current.message != null,
      listener: (context, state) {
        AppFeedback.error(context, state.message ?? l.errorOccurred);
      },
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SupportIntroCard(),
            const SizedBox(height: AppSpacing.sm),
            _SupportTabBar(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: BlocBuilder<SupportCubit, SupportState>(
                builder: (context, state) {
                  final contextData = _contextData();
                  return TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _SupportTabScroll(
                        child: _SupportTicketForm(
                          key: const ValueKey('support-ticket-form'),
                          contextData: contextData,
                          isSaving: state.isSavingSupport,
                        ),
                      ),
                      _SupportTabScroll(
                        child: _FeedbackForm(
                          key: const ValueKey('feedback-form'),
                          contextData: contextData,
                          isSaving: state.isSavingFeedback,
                        ),
                      ),
                      _SupportTabScroll(
                        child: _MyRequestsList(state: state),
                      ),
                      const _SupportTabScroll(
                        child: _ContactActionsPanel(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TicketContextData _contextData() {
    return _TicketContextData(
      companyId: widget.companyId,
      companyName: widget.companyName,
      userId: widget.userId,
      userName: widget.userName,
      userEmail: widget.userEmail,
      userRole: widget.userRole,
      currentRoute: GoRouterState.of(context).uri.toString(),
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      deviceInfo: defaultTargetPlatform.name,
    );
  }
}

class _SupportIntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Panel(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor(context).withValues(alpha: .12),
              borderRadius: AppRadius.large,
            ),
            child: Icon(
              Icons.support_agent_outlined,
              color: AppColors.primaryColor(context),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.supportCenter,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.supportCenterSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return MasarTabBar(
      compact: true,
      fullWidth: true,
      tabs: [
        MasarTabItem(label: l.requestTypeSupport, icon: Icons.support_agent_outlined),
        MasarTabItem(label: l.requestTypeFeedback, icon: Icons.rate_review_outlined),
        MasarTabItem(label: l.myRequests, icon: Icons.inbox_outlined),
        MasarTabItem(label: l.contactSupport, icon: Icons.alternate_email_outlined),
      ],
    );
  }
}

class _SupportTabScroll extends StatelessWidget {
  const _SupportTabScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const MasarRefreshPhysics(parent: BouncingScrollPhysics()),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        bottom: AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: child,
    );
  }
}

class _SupportTicketForm extends StatefulWidget {
  const _SupportTicketForm({
    super.key,
    required this.contextData,
    required this.isSaving,
  });

  final _TicketContextData contextData;
  final bool isSaving;

  @override
  State<_SupportTicketForm> createState() => _SupportTicketFormState();
}

class _SupportTicketFormState extends State<_SupportTicketForm>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = SupportCategory.accountLogin;
  String _priority = SupportTicketPriority.normal;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await context.read<SupportCubit>().createSupportTicket(
          SupportTicketDraft(
            companyId: widget.contextData.companyId,
            companyName: widget.contextData.companyName,
            userId: widget.contextData.userId,
            userName: widget.contextData.userName,
            userEmail: widget.contextData.userEmail,
            userRole: widget.contextData.userRole,
            type: SupportTicketType.support,
            category: _category,
            priority: _priority,
            title: _titleController.text.trim(),
            message: _messageController.text.trim(),
            appVersion: AppConstants.appVersion,
            appBuildNumber: AppConstants.appBuildNumber,
            platform: widget.contextData.platform,
            currentRoute: widget.contextData.currentRoute,
            deviceInfo: widget.contextData.deviceInfo,
          ),
        );
    if (!mounted || !success) {
      return;
    }
    _titleController.clear();
    _messageController.clear();
    setState(() {
      _category = SupportCategory.accountLogin;
      _priority = SupportTicketPriority.normal;
    });
    AppFeedback.success(context, AppLocalizations.of(context)!.supportTicketCreated);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    final textDirection = Directionality.of(context);
    return _Panel(
      title: l.contactSupport,
      subtitle: l.contactSupportSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _titleController,
              label: l.supportTitle,
              enabled: !widget.isSaving,
              textDirection: textDirection,
              textInputAction: TextInputAction.next,
              validator: (value) => _required(value, l),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppDropdown<String>(
              label: l.supportCategory,
              value: _category,
              enabled: !widget.isSaving,
              items: SupportCategory.values,
              itemLabelBuilder: (value) => supportCategoryLabel(l, value),
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppDropdown<String>(
              label: l.supportPriority,
              value: _priority,
              enabled: !widget.isSaving,
              items: SupportTicketPriority.values,
              itemLabelBuilder: (value) => supportPriorityLabel(l, value),
              onChanged: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _messageController,
              label: l.supportMessage,
              enabled: !widget.isSaving,
              textDirection: textDirection,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 4,
              maxLines: 5,
              validator: (value) => _required(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l.submitSupportRequest,
              icon: Icons.send_outlined,
              isLoading: widget.isSaving,
              onPressed: widget.isSaving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _FeedbackForm extends StatefulWidget {
  const _FeedbackForm({
    super.key,
    required this.contextData,
    required this.isSaving,
  });

  final _TicketContextData contextData;
  final bool isSaving;

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  int _rating = 5;
  String _category = FeedbackCategory.suggestion;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await context.read<SupportCubit>().createFeedback(
          SupportTicketDraft(
            companyId: widget.contextData.companyId,
            companyName: widget.contextData.companyName,
            userId: widget.contextData.userId,
            userName: widget.contextData.userName,
            userEmail: widget.contextData.userEmail,
            userRole: widget.contextData.userRole,
            type: SupportTicketType.feedback,
            category: _category,
            priority: SupportTicketPriority.normal,
            rating: _rating,
            title: '',
            message: _messageController.text.trim(),
            appVersion: AppConstants.appVersion,
            appBuildNumber: AppConstants.appBuildNumber,
            platform: widget.contextData.platform,
            currentRoute: widget.contextData.currentRoute,
            deviceInfo: widget.contextData.deviceInfo,
          ),
        );
    if (!mounted || !success) {
      return;
    }
    _messageController.clear();
    setState(() {
      _rating = 5;
      _category = FeedbackCategory.suggestion;
    });
    AppFeedback.success(context, AppLocalizations.of(context)!.feedbackSubmitted);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    final textDirection = Directionality.of(context);
    return _Panel(
      title: l.sendFeedback,
      subtitle: l.sendFeedbackSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<int>(
              label: l.feedbackRating,
              value: _rating,
              enabled: !widget.isSaving,
              items: const [1, 2, 3, 4, 5],
              itemLabelBuilder: (value) => '$value / 5',
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppDropdown<String>(
              label: l.feedbackCategory,
              value: _category,
              enabled: !widget.isSaving,
              items: FeedbackCategory.values,
              itemLabelBuilder: (value) => feedbackCategoryLabel(l, value),
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _messageController,
              label: l.feedbackMessage,
              enabled: !widget.isSaving,
              textDirection: textDirection,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 4,
              maxLines: 5,
              validator: (value) => _required(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l.submitFeedback,
              icon: Icons.rate_review_outlined,
              variant: AppButtonVariant.secondary,
              isLoading: widget.isSaving,
              onPressed: widget.isSaving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _MyRequestsList extends StatelessWidget {
  const _MyRequestsList({required this.state});

  final SupportState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (state.status == SupportStatus.loading) {
      return _Panel(title: l.myRequests, child: const AppLoading());
    }
    if (state.tickets.isEmpty) {
      return _Panel(
        title: l.myRequests,
        child: AppEmptyState(
          icon: Icons.inbox_outlined,
          title: l.supportNoRequestsTitle,
          message: l.supportNoRequestsMessage,
        ),
      );
    }
    return _Panel(
      title: l.myRequests,
      child: Column(
        children: [
          for (final ticket in state.tickets) ...[
            _TicketTile(ticket: ticket),
            if (ticket != state.tickets.last)
              const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = ticket.isFeedback
        ? '${l.requestTypeFeedback} ${ticket.rating == null ? '' : '(${ticket.rating}/5)'}'
        : ticket.title;
    final category = ticket.isFeedback
        ? feedbackCategoryLabel(l, ticket.category)
        : supportCategoryLabel(l, ticket.category);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ticket.isFeedback
              ? Icons.rate_review_outlined
              : Icons.support_agent_outlined,
          color: AppColors.primaryColor(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title.trim().isEmpty ? l.requestTypeSupport : title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  AppStatusBadge(
                    label: supportStatusLabel(l, ticket.status),
                    tone: supportStatusTone(ticket.status),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                ticket.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _InfoPill(label: l.requestType, value: ticket.isFeedback ? l.requestTypeFeedback : l.requestTypeSupport),
                  _InfoPill(label: l.supportCategory, value: category),
                  if (!ticket.isFeedback)
                    _InfoPill(label: l.supportPriority, value: supportPriorityLabel(l, ticket.priority)),
                  if (ticket.rating != null)
                    _InfoPill(label: l.feedbackRating, value: '${ticket.rating} / 5'),
                  _InfoPill(label: l.createdAt, value: _formatDate(context, ticket.createdAt)),
                  _InfoPill(label: l.updatedAt, value: _formatDate(context, ticket.updatedAt)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.selectedSurface(context).withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        child: Text(
          '$label: $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ContactActionsPanel extends StatelessWidget {
  const _ContactActionsPanel();

  static const String _supportMessage =
      'Hello Masar Support, I need help with my CRM workspace.';
  static final String _whatsAppUrl = Uri.https(
    'wa.me',
    '/201208090241',
    {
      'text': _supportMessage,
    },
  ).toString();
  static final String _emailUrl = Uri(
    scheme: 'mailto',
    path: 'islamallam9@outlook.com',
    queryParameters: {
      'subject': 'Masar CRM support request',
      'body': _supportMessage,
    },
  ).toString();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return _Panel(
      title: l.contactSupport,
      subtitle: l.supportCenterSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ContactActionCard(
            icon: Icons.chat_outlined,
            assetIconPath: 'assets/branding/whatsapp_icon.svg',
            title: l.whatsapp,
            value: '',
            onTap: () => _launchContactUrl(context, _whatsAppUrl),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactActionCard(
            icon: Icons.email_outlined,
            title: l.email,
            value: '',
            onTap: () => _launchContactUrl(context, _emailUrl),
          ),
        ],
      ),
    );
  }
}

class _ContactActionCard extends StatelessWidget {
  const _ContactActionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.assetIconPath,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final String? assetIconPath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.selectedSurface(context).withValues(alpha: 0.36),
      borderRadius: AppRadius.large,
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor(context)),
            borderRadius: AppRadius.large,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor(context).withValues(alpha: .12),
                  borderRadius: AppRadius.medium,
                ),
                child: assetIconPath == null
                    ? Icon(icon, color: AppColors.primaryColor(context))
                    : SvgPicture.asset(
                        assetIconPath!,
                        width: 24,
                        height: 24,
                        semanticsLabel: title,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.open_in_new_outlined,
                color: AppColors.textSecondaryColor(context),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({this.title, this.subtitle, required this.child});

  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _TicketContextData {
  const _TicketContextData({
    required this.companyId,
    required this.companyName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.currentRoute,
    required this.platform,
    required this.deviceInfo,
  });

  final String companyId;
  final String companyName;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final String currentRoute;
  final String platform;
  final String deviceInfo;
}

String? _required(String? value, AppLocalizations l) {
  return (value ?? '').trim().isEmpty ? l.requiredField : null;
}

String _formatDate(BuildContext context, DateTime? value) {
  if (value == null) {
    return AppLocalizations.of(context)!.notAvailable;
  }
  return intl.DateFormat.yMd(Localizations.localeOf(context).toString())
      .add_jm()
      .format(value.toLocal());
}

Future<void> _launchContactUrl(BuildContext context, String url) async {
  final l = AppLocalizations.of(context)!;
  try {
    final launched = kIsWeb
        ? await openExternalLink(url)
        : await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
    if (!launched && context.mounted) {
      AppFeedback.error(context, l.actionFailed);
    }
  } catch (_) {
    if (context.mounted) {
      AppFeedback.error(context, l.actionFailed);
    }
  }
}

String supportCategoryLabel(AppLocalizations l, String value) {
  return switch (value) {
    SupportCategory.accountLogin => l.supportCategoryAccountLogin,
    SupportCategory.usersPermissions => l.supportCategoryUsersPermissions,
    SupportCategory.leads => l.leads,
    SupportCategory.clients => l.clients,
    SupportCategory.properties => l.properties,
    SupportCategory.tasks => l.tasks,
    SupportCategory.deals => l.deals,
    SupportCategory.notifications => l.notifications,
    SupportCategory.appointments => l.appointments,
    SupportCategory.billingSubscription => l.supportCategoryBillingSubscription,
    SupportCategory.bug => l.supportCategoryBug,
    _ => l.other,
  };
}

String feedbackCategoryLabel(AppLocalizations l, String value) {
  return switch (value) {
    FeedbackCategory.suggestion => l.feedbackCategorySuggestion,
    FeedbackCategory.uiImprovement => l.feedbackCategoryUiImprovement,
    FeedbackCategory.missingFeature => l.feedbackCategoryMissingFeature,
    FeedbackCategory.confusingBehavior => l.feedbackCategoryConfusingBehavior,
    FeedbackCategory.performance => l.feedbackCategoryPerformance,
    _ => l.feedbackCategoryGeneralFeedback,
  };
}

String supportPriorityLabel(AppLocalizations l, String value) {
  return switch (value) {
    SupportTicketPriority.low => l.supportPriorityLow,
    SupportTicketPriority.urgent => l.supportPriorityUrgent,
    _ => l.supportPriorityNormal,
  };
}

String supportStatusLabel(AppLocalizations l, String value) {
  return switch (value) {
    SupportTicketStatus.inReview => l.supportStatusInReview,
    SupportTicketStatus.waitingForUser => l.supportStatusWaitingForUser,
    SupportTicketStatus.resolved => l.supportStatusResolved,
    SupportTicketStatus.closed => l.supportStatusClosed,
    _ => l.supportStatusOpen,
  };
}

AppStatusTone supportStatusTone(String status) {
  return switch (status) {
    SupportTicketStatus.open => AppStatusTone.warning,
    SupportTicketStatus.inReview => AppStatusTone.info,
    SupportTicketStatus.waitingForUser => AppStatusTone.neutral,
    SupportTicketStatus.resolved => AppStatusTone.success,
    SupportTicketStatus.closed => AppStatusTone.neutral,
    _ => AppStatusTone.neutral,
  };
}
