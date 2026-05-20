import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../../data/datasources/support_remote_data_source.dart';
import '../../data/repositories/support_repository_impl.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/usecases/update_support_ticket_status_usecase.dart';
import '../../domain/usecases/watch_platform_support_tickets_usecase.dart';
import '../cubit/platform_support_inbox_cubit.dart';
import '../cubit/platform_support_inbox_state.dart';
import 'support_page.dart';

class PlatformSupportInboxPanel extends StatelessWidget {
  const PlatformSupportInboxPanel({super.key, required this.companies});

  final List<CompanyMetadata> companies;

  static Widget withDependencies({required List<CompanyMetadata> companies}) {
    final repository = SupportRepositoryImpl(
      remoteDataSource: FirebaseSupportRemoteDataSource(),
    );
    return BlocProvider(
      create: (_) => PlatformSupportInboxCubit(
        watchPlatformTicketsUseCase: WatchPlatformSupportTicketsUseCase(
          repository,
        ),
        updateTicketStatusUseCase: UpdateSupportTicketStatusUseCase(repository),
      )..watchTickets(),
      child: PlatformSupportInboxPanel(companies: companies),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocListener<PlatformSupportInboxCubit, PlatformSupportInboxState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == PlatformSupportInboxStatus.failure &&
          current.message != null,
      listener: (context, state) {
        AppFeedback.error(context, state.message ?? l.errorOccurred);
      },
      child: BlocBuilder<PlatformSupportInboxCubit, PlatformSupportInboxState>(
        builder: (context, state) {
          if (state.status == PlatformSupportInboxStatus.loading) {
            return _Panel(title: l.platformSupportInbox, child: const AppLoading());
          }
          return _PlatformSupportInboxContent(
            state: state,
            companies: companies,
          );
        },
      ),
    );
  }
}

class _PlatformSupportInboxContent extends StatefulWidget {
  const _PlatformSupportInboxContent({
    required this.state,
    required this.companies,
  });

  final PlatformSupportInboxState state;
  final List<CompanyMetadata> companies;

  @override
  State<_PlatformSupportInboxContent> createState() =>
      _PlatformSupportInboxContentState();
}

class _PlatformSupportInboxContentState
    extends State<_PlatformSupportInboxContent> {
  final _searchController = TextEditingController();
  String? _type;
  String? _status;
  String? _priority;
  String? _category;
  String? _companyId;
  SupportTicket? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tickets = _filteredTickets(widget.state.tickets);
    final selected = _selected == null
        ? (tickets.isEmpty ? null : tickets.first)
        : _firstOrNull(tickets.where((ticket) => ticket.id == _selected!.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          title: l.platformSupportInbox,
          child: _SupportKpis(tickets: widget.state.tickets),
        ),
        const SizedBox(height: AppSpacing.md),
        _Panel(
          child: _SupportFilters(
            searchController: _searchController,
            companies: widget.companies,
            type: _type,
            status: _status,
            priority: _priority,
            category: _category,
            companyId: _companyId,
            onChanged: () => setState(() {}),
            onTypeChanged: (value) => setState(() => _type = value),
            onStatusChanged: (value) => setState(() => _status = value),
            onPriorityChanged: (value) => setState(() => _priority = value),
            onCategoryChanged: (value) => setState(() => _category = value),
            onCompanyChanged: (value) => setState(() => _companyId = value),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 960;
            final list = _TicketsList(
              tickets: tickets,
              selectedId: selected?.id,
              onSelected: (ticket) => setState(() => _selected = ticket),
            );
            final details = _TicketDetailsPanel(ticket: selected);
            if (narrow) {
              return Column(
                children: [
                  list,
                  const SizedBox(height: AppSpacing.md),
                  details,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: list),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 4, child: details),
              ],
            );
          },
        ),
      ],
    );
  }

  List<SupportTicket> _filteredTickets(List<SupportTicket> tickets) {
    final query = _searchController.text.trim().toLowerCase();
    return tickets.where((ticket) {
      final matchesType = _type == null || ticket.type == _type;
      final matchesStatus = _status == null || ticket.status == _status;
      final matchesPriority = _priority == null || ticket.priority == _priority;
      final matchesCategory = _category == null || ticket.category == _category;
      final matchesCompany = _companyId == null || ticket.companyId == _companyId;
      final matchesSearch = query.isEmpty ||
          ticket.userName.toLowerCase().contains(query) ||
          ticket.userEmail.toLowerCase().contains(query) ||
          ticket.companyName.toLowerCase().contains(query) ||
          ticket.title.toLowerCase().contains(query) ||
          ticket.message.toLowerCase().contains(query);
      return matchesType &&
          matchesStatus &&
          matchesPriority &&
          matchesCategory &&
          matchesCompany &&
          matchesSearch;
    }).toList();
  }
}

class _SupportKpis extends StatelessWidget {
  const _SupportKpis({required this.tickets});

  final List<SupportTicket> tickets;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final open = tickets.where((ticket) => ticket.status == SupportTicketStatus.open).length;
    final urgent = tickets
        .where((ticket) => ticket.priority == SupportTicketPriority.urgent)
        .length;
    final feedback = tickets.where((ticket) => ticket.isFeedback).length;
    final resolved = tickets.where((ticket) {
      final date = ticket.resolvedAt ?? ticket.updatedAt;
      return date != null &&
          !date.isBefore(monthStart) &&
          (ticket.status == SupportTicketStatus.resolved ||
              ticket.status == SupportTicketStatus.closed);
    }).length;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _Kpi(label: l.supportOpenTickets, value: open.toString(), icon: Icons.inbox_outlined),
        _Kpi(label: l.supportUrgentTickets, value: urgent.toString(), icon: Icons.priority_high),
        _Kpi(label: l.supportFeedbackCount, value: feedback.toString(), icon: Icons.rate_review_outlined),
        _Kpi(label: l.supportResolvedThisMonth, value: resolved.toString(), icon: Icons.check_circle_outline),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 172,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor(context)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _SupportFilters extends StatelessWidget {
  const _SupportFilters({
    required this.searchController,
    required this.companies,
    required this.type,
    required this.status,
    required this.priority,
    required this.category,
    required this.companyId,
    required this.onChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
    required this.onCompanyChanged,
  });

  final TextEditingController searchController;
  final List<CompanyMetadata> companies;
  final String? type;
  final String? status;
  final String? priority;
  final String? category;
  final String? companyId;
  final VoidCallback onChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onCompanyChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final categoryItems = <String?>[
      null,
      ...SupportCategory.values,
      ...FeedbackCategory.values,
    ].toSet().toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 880;
        final fields = [
          AppSearchField(
            controller: searchController,
            hint: l.searchSupportRequests,
            onChanged: (_) => onChanged(),
            onClear: () {
              searchController.clear();
              onChanged();
            },
          ),
          AppDropdown<String?>(
            label: l.requestType,
            value: type,
            items: const [null, SupportTicketType.support, SupportTicketType.feedback],
            itemLabelBuilder: (value) => value == null
                ? l.allTypes
                : (value == SupportTicketType.feedback ? l.requestTypeFeedback : l.requestTypeSupport),
            onChanged: onTypeChanged,
          ),
          AppDropdown<String?>(
            label: l.status,
            value: status,
            items: const [null, ...SupportTicketStatus.values],
            itemLabelBuilder: (value) => value == null ? l.allStatuses : supportStatusLabel(l, value),
            onChanged: onStatusChanged,
          ),
          AppDropdown<String?>(
            label: l.priority,
            value: priority,
            items: const [null, ...SupportTicketPriority.values],
            itemLabelBuilder: (value) => value == null ? l.allPriorities : supportPriorityLabel(l, value),
            onChanged: onPriorityChanged,
          ),
          AppDropdown<String?>(
            label: l.supportCategory,
            value: category,
            items: categoryItems,
            itemLabelBuilder: (value) {
              if (value == null) {
                return l.allCategories;
              }
              if (FeedbackCategory.values.contains(value)) {
                return feedbackCategoryLabel(l, value);
              }
              return supportCategoryLabel(l, value);
            },
            onChanged: onCategoryChanged,
          ),
          AppDropdown<String?>(
            label: l.company,
            value: companyId,
            items: <String?>[null, ...companies.map((company) => company.id)],
            itemLabelBuilder: (value) {
              if (value == null) {
                return l.allCompanies;
              }
              final company = _firstOrNull(
                companies.where((item) => item.id == value),
              );
              if (company == null) {
                return value;
              }
              return company.displayName.trim().isEmpty
                  ? company.name
                  : company.displayName;
            },
            onChanged: onCompanyChanged,
          ),
        ];
        if (narrow) {
          return Column(
            children: [
              for (final field in fields) ...[
                field,
                if (field != fields.last) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(width: 260, child: fields[0]),
            for (final field in fields.skip(1)) SizedBox(width: 188, child: field),
          ],
        );
      },
    );
  }
}

class _TicketsList extends StatelessWidget {
  const _TicketsList({
    required this.tickets,
    required this.selectedId,
    required this.onSelected,
  });

  final List<SupportTicket> tickets;
  final String? selectedId;
  final ValueChanged<SupportTicket> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (tickets.isEmpty) {
      return _Panel(
        title: l.myRequests,
        child: AppEmptyState(
          icon: Icons.support_agent_outlined,
          title: l.supportNoRequestsTitle,
          message: l.supportNoRequestsMessage,
        ),
      );
    }
    return _Panel(
      title: l.myRequests,
      child: Column(
        children: [
          for (final ticket in tickets) ...[
            _TicketRow(
              ticket: ticket,
              selected: ticket.id == selectedId,
              onTap: () => onSelected(ticket),
            ),
            if (ticket != tickets.last) const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({
    required this.ticket,
    required this.selected,
    required this.onTap,
  });

  final SupportTicket ticket;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: selected
          ? AppColors.primaryColor(context).withValues(alpha: .08)
          : Colors.transparent,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
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
                    Text(
                      ticket.isFeedback ? l.sendFeedback : ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${ticket.companyName} - ${ticket.userName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppStatusBadge(
                    label: supportStatusLabel(l, ticket.status),
                    tone: supportStatusTone(ticket.status),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(context, ticket.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketDetailsPanel extends StatefulWidget {
  const _TicketDetailsPanel({required this.ticket});

  final SupportTicket? ticket;

  @override
  State<_TicketDetailsPanel> createState() => _TicketDetailsPanelState();
}

class _TicketDetailsPanelState extends State<_TicketDetailsPanel> {
  String? _status;

  @override
  void didUpdateWidget(covariant _TicketDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket?.id != widget.ticket?.id) {
      _status = widget.ticket?.status;
    }
  }

  Future<void> _updateStatus() async {
    final ticket = widget.ticket;
    final status = _status;
    if (ticket == null || status == null || status == ticket.status) {
      return;
    }
    final success = await context.read<PlatformSupportInboxCubit>().updateStatus(
          ticketId: ticket.id,
          status: status,
        );
    if (!mounted) {
      return;
    }
    if (success) {
      AppFeedback.success(context, AppLocalizations.of(context)!.supportStatusUpdated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ticket = widget.ticket;
    if (ticket == null) {
      return _Panel(
        title: l.supportDetails,
        child: AppEmptyState(
          icon: Icons.support_agent_outlined,
          title: l.supportNoRequestsTitle,
          message: l.supportNoRequestsMessage,
        ),
      );
    }
    final saving = context.select(
      (PlatformSupportInboxCubit cubit) =>
          cubit.state.activeTicketId == ticket.id &&
          cubit.state.status == PlatformSupportInboxStatus.saving,
    );
    final statusValue = _status ?? ticket.status;
    return _Panel(
      title: l.supportDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label: ticket.isFeedback ? l.requestTypeFeedback : l.requestTypeSupport,
                tone: AppStatusTone.info,
              ),
              AppStatusBadge(
                label: supportStatusLabel(l, ticket.status),
                tone: supportStatusTone(ticket.status),
              ),
              if (ticket.priority == SupportTicketPriority.urgent)
                AppStatusBadge(
                  label: supportPriorityLabel(l, ticket.priority),
                  tone: AppStatusTone.error,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            ticket.isFeedback ? l.sendFeedback : ticket.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(ticket.message),
          const SizedBox(height: AppSpacing.md),
          _DetailsGrid(ticket: ticket),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: l.status,
            value: statusValue,
            enabled: !saving,
            items: SupportTicketStatus.values,
            itemLabelBuilder: (value) => supportStatusLabel(l, value),
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.updateStatus,
            icon: Icons.done_outline,
            isLoading: saving,
            onPressed: saving ? null : _updateStatus,
          ),
        ],
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = [
      (l.company, ticket.companyName),
      (l.user, ticket.userName),
      (l.email, ticket.userEmail),
      (l.supportCategory, ticket.isFeedback ? feedbackCategoryLabel(l, ticket.category) : supportCategoryLabel(l, ticket.category)),
      (l.priority, supportPriorityLabel(l, ticket.priority)),
      if (ticket.rating != null) (l.feedbackRating, '${ticket.rating} / 5'),
      (l.appVersion, '${ticket.appVersion}+${ticket.appBuildNumber}'),
      (l.platform, ticket.platform),
      (l.currentRoute, ticket.currentRoute),
      (l.deviceInfo, ticket.deviceInfo),
      (l.createdAt, _formatDate(context, ticket.createdAt)),
      (l.updatedAt, _formatDate(context, ticket.updatedAt)),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final row in rows)
          _InfoChip(label: row.$1, value: row.$2.trim().isEmpty ? l.notAvailable : row.$2),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130, maxWidth: 240),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({this.title, required this.child});

  final String? title;
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
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime? value) {
  if (value == null) {
    return AppLocalizations.of(context)!.notAvailable;
  }
  return DateFormat.yMd(Localizations.localeOf(context).toString())
      .add_jm()
      .format(value.toLocal());
}

T? _firstOrNull<T>(Iterable<T> values) {
  final iterator = values.iterator;
  if (!iterator.moveNext()) {
    return null;
  }
  return iterator.current;
}
