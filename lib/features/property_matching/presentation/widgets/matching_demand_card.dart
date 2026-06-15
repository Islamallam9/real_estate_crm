import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/intelligence/property_match_evaluator.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../clients/data/datasources/clients_remote_data_source.dart';
import '../../../clients/data/repositories/client_repository_impl.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../leads/data/datasources/leads_remote_data_source.dart';
import '../../../leads/data/repositories/leads_repository_impl.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../properties/data/models/property_model.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/presentation/widgets/property_labels.dart';

class MatchingDemandCard extends StatefulWidget {
  const MatchingDemandCard({
    super.key,
    required this.companyId,
    required this.property,
    required this.role,
    required this.currentUserId,
    required this.currentUserTeamId,
    required this.currentUserManagerId,
    required this.canViewLeads,
    required this.canViewClients,
  });

  final String companyId;
  final Property property;
  final UserRole role;
  final String currentUserId;
  final String currentUserTeamId;
  final String currentUserManagerId;
  final bool canViewLeads;
  final bool canViewClients;

  @override
  State<MatchingDemandCard> createState() => _MatchingDemandCardState();
}

class _MatchingDemandCardState extends State<MatchingDemandCard> {
  Future<List<_DemandMatchViewData>>? _future;
  String _requestKey = '';

  @override
  void initState() {
    super.initState();
    _refreshIfNeeded(force: true);
  }

  @override
  void didUpdateWidget(covariant MatchingDemandCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshIfNeeded();
  }

  void _refreshIfNeeded({bool force = false}) {
    final property = widget.property;
    final key = [
      widget.companyId,
      property.id,
      property.status.name,
      property.isArchived.toString(),
      property.location.trim(),
      property.compound.trim(),
      property.propertyType.name,
      property.price.toString(),
      widget.role.name,
      widget.currentUserId,
      widget.currentUserTeamId,
      widget.currentUserManagerId,
      widget.canViewLeads.toString(),
      widget.canViewClients.toString(),
    ].join('|');
    if (!force && key == _requestKey) {
      return;
    }
    _requestKey = key;
    _future = _loadMatches();
  }

  Future<List<_DemandMatchViewData>> _loadMatches() async {
    if (widget.companyId.trim().isEmpty ||
        widget.property.isArchived ||
        widget.property.status != PropertyStatus.available ||
        (!widget.canViewLeads && !widget.canViewClients)) {
      return const <_DemandMatchViewData>[];
    }

    final scope = _DemandQueryScope.fromRole(
      role: widget.role,
      currentUserId: widget.currentUserId,
      teamId: widget.currentUserTeamId,
      managerId: widget.currentUserManagerId,
    );
    final candidate = _candidateFromProperty(widget.property);
    final matches = <_DemandMatchViewData>[];

    if (widget.canViewClients) {
      final clientRepository = ClientRepositoryImpl(
        remoteDataSource: FirestoreClientsRemoteDataSource(),
      );
      final clients = await clientRepository.watchClients(
        companyId: widget.companyId,
        assignedTo: scope.assignedTo,
        managerId: scope.managerId,
        teamId: scope.teamId,
        archiveFilter: ArchiveFilter.active,
        limit: 120,
      ).first;
      for (final client in clients) {
        final match = _scoreClient(client, candidate);
        if (match != null) {
          matches.add(match);
        }
      }
    }

    if (widget.canViewLeads) {
      final leadRepository = LeadsRepositoryImpl(
        remoteDataSource: FirestoreLeadsRemoteDataSource(),
      );
      final leads = await leadRepository.watchLeads(
        companyId: widget.companyId,
        assignedTo: scope.assignedTo,
        managerId: scope.managerId,
        teamId: scope.teamId,
        archiveFilter: ArchiveFilter.active,
        limit: 120,
      ).first;
      for (final lead in leads.where(_isOpenLead)) {
        final match = _scoreLead(lead, candidate);
        if (match != null) {
          matches.add(match);
        }
      }
    }

    matches.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) {
        return score;
      }
      final typeRank = a.typeRank.compareTo(b.typeRank);
      if (typeRank != 0) {
        return typeRank;
      }
      return a.title.compareTo(b.title);
    });
    return matches.take(4).toList(growable: false);
  }

  _DemandMatchViewData? _scoreClient(
    Client client,
    PropertyMatchCandidate property,
  ) {
    final request = PropertyMatchRequest(
      preferredLocation: client.preferredLocation,
      preferredPropertyType: client.preferredPropertyType,
      budgetMin: client.budgetMin,
      budgetMax: client.budgetMax,
    );
    if (!request.hasUsablePreferences) {
      return null;
    }
    final result = PropertyMatchEvaluator.evaluate(
      request: request,
      candidates: [property],
      limit: 1,
      minimumScore: 25,
    );
    if (result.isEmpty) {
      return null;
    }
    final match = result.first;
    final score = (match.score + 6).clamp(0, 100).toInt();
    return _DemandMatchViewData(
      id: client.id,
      type: _DemandType.client,
      title: client.fullName.trim().isEmpty ? client.phone : client.fullName,
      subtitle: _demandPreferenceLine(
        location: client.preferredLocation,
        propertyType: client.preferredPropertyType,
        budgetMin: client.budgetMin,
        budgetMax: client.budgetMax,
      ),
      score: score,
      reasons: match.reasons,
    );
  }

  _DemandMatchViewData? _scoreLead(
    Lead lead,
    PropertyMatchCandidate property,
  ) {
    final request = PropertyMatchRequest(
      preferredLocation: lead.preferredLocation,
      preferredPropertyType: lead.preferredPropertyType,
      budgetMin: lead.budgetMin,
      budgetMax: lead.budgetMax,
    );
    if (!request.hasUsablePreferences) {
      return null;
    }
    final result = PropertyMatchEvaluator.evaluate(
      request: request,
      candidates: [property],
      limit: 1,
      minimumScore: 25,
    );
    if (result.isEmpty) {
      return null;
    }
    final match = result.first;
    final score = (match.score + _leadBusinessBoost(lead)).clamp(0, 100).toInt();
    return _DemandMatchViewData(
      id: lead.id,
      type: _DemandType.lead,
      title: lead.fullName.trim().isEmpty ? lead.phone : lead.fullName,
      subtitle: _demandPreferenceLine(
        location: lead.preferredLocation,
        propertyType: lead.preferredPropertyType,
        budgetMin: lead.budgetMin,
        budgetMax: lead.budgetMax,
      ),
      score: score,
      reasons: match.reasons,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final property = widget.property;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppRadius.large,
        border: Border.all(color: theme.dividerColor.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: AppRadius.medium,
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.matchingDemandTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l.matchingDemandSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (property.isArchived || property.status != PropertyStatus.available)
            _EmptyDemandState(message: l.matchingDemandUnavailableProperty)
          else if (!widget.canViewLeads && !widget.canViewClients)
            _EmptyDemandState(message: l.matchingDemandNoAccess)
          else
            FutureBuilder<List<_DemandMatchViewData>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _EmptyDemandState(
                    message: localizeErrorMessage(
                      l,
                      snapshot.error?.toString() ?? l.matchingDemandLoadFailed,
                    ),
                    action: AppButton(
                      label: l.tryAgain,
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        setState(() {
                          _future = _loadMatches();
                        });
                      },
                    ),
                  );
                }
                final matches = snapshot.data ?? const <_DemandMatchViewData>[];
                if (matches.isEmpty) {
                  return _EmptyDemandState(message: l.matchingDemandNoMatches);
                }
                return Column(
                  children: [
                    for (var index = 0; index < matches.length; index++) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.sm),
                      _DemandMatchTile(data: matches[index]),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DemandMatchTile extends StatelessWidget {
  const _DemandMatchTile({required this.data});

  final _DemandMatchViewData data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final route = switch (data.type) {
      _DemandType.lead => RouteNames.leadDetails(data.id),
      _DemandType.client => RouteNames.clientDetails(data.id),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context).withOpacity(0.72),
        borderRadius: AppRadius.medium,
        border: Border.all(color: theme.dividerColor.withOpacity(0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
                    label: data.type == _DemandType.client
                        ? l.matchingDemandClient
                        : l.matchingDemandLead,
                    tone: data.type == _DemandType.client
                        ? AppStatusTone.success
                        : AppStatusTone.info,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppStatusBadge(label: '${data.score}%', tone: AppStatusTone.info),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final reason in data.reasons.take(3))
                AppStatusBadge(
                  label: _reasonLabel(l, reason),
                  tone: AppStatusTone.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              label: l.viewDetails,
              icon: Icons.open_in_new_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(route),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDemandState extends StatelessWidget {
  const _EmptyDemandState({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context).withOpacity(0.72),
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.sm),
            action!,
          ],
        ],
      ),
    );
  }
}

class _DemandQueryScope {
  const _DemandQueryScope({this.assignedTo, this.managerId, this.teamId});

  final String? assignedTo;
  final String? managerId;
  final String? teamId;

  factory _DemandQueryScope.fromRole({
    required UserRole role,
    required String currentUserId,
    required String teamId,
    required String managerId,
  }) {
    final cleanUid = currentUserId.trim();
    final cleanTeamId = teamId.trim();
    final cleanManagerId = managerId.trim();
    return switch (role) {
      UserRole.admin => const _DemandQueryScope(),
      UserRole.manager => cleanTeamId.isNotEmpty
          ? _DemandQueryScope(teamId: cleanTeamId)
          : _DemandQueryScope(managerId: cleanUid),
      UserRole.salesAgent || UserRole.marketing || UserRole.viewer =>
        _DemandQueryScope(assignedTo: cleanUid.isNotEmpty ? cleanUid : '__none__'),
    };
  }
}

class _DemandMatchViewData {
  const _DemandMatchViewData({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.reasons,
  });

  final String id;
  final _DemandType type;
  final String title;
  final String subtitle;
  final int score;
  final List<String> reasons;

  int get typeRank => type == _DemandType.client ? 0 : 1;
}

enum _DemandType { lead, client }

bool _isOpenLead(Lead lead) {
  if (lead.isArchived) {
    return false;
  }
  return switch (lead.status) {
    LeadStatus.won || LeadStatus.lost => false,
    LeadStatus.newLead ||
    LeadStatus.contacted ||
    LeadStatus.interested ||
    LeadStatus.visitScheduled ||
    LeadStatus.negotiation => true,
  };
}

int _leadBusinessBoost(Lead lead) {
  final statusBoost = switch (lead.status) {
    LeadStatus.interested || LeadStatus.visitScheduled || LeadStatus.negotiation => 5,
    LeadStatus.contacted => 3,
    LeadStatus.newLead => 1,
    LeadStatus.won || LeadStatus.lost => 0,
  };
  final priorityBoost = switch (lead.priority) {
    LeadPriority.high => 4,
    LeadPriority.medium => 2,
    LeadPriority.low => 0,
  };
  return statusBoost + priorityBoost;
}

PropertyMatchCandidate _candidateFromProperty(Property property) {
  return PropertyMatchCandidate(
    id: property.id,
    title: property.title,
    propertyType: propertyTypeToValue(property.propertyType),
    price: property.price,
    location: property.location,
    compound: property.compound,
    status: propertyStatusToValue(property.status),
    isArchived: property.isArchived,
  );
}

String _demandPreferenceLine({
  required String location,
  required String propertyType,
  required num? budgetMin,
  required num? budgetMax,
}) {
  final parts = <String>[
    if (location.trim().isNotEmpty) location.trim(),
    if (propertyType.trim().isNotEmpty) propertyType.trim(),
  ];
  final budgetText = _budgetRangeText(budgetMin: budgetMin, budgetMax: budgetMax);
  if (budgetText.isNotEmpty) {
    parts.add(budgetText);
  }
  return parts.join(' • ');
}

String _budgetRangeText({required num? budgetMin, required num? budgetMax}) {
  final min = budgetMin != null && budgetMin > 0 ? budgetMin : null;
  final max = budgetMax != null && budgetMax > 0 ? budgetMax : null;
  if (min == null && max == null) {
    return '';
  }
  final formatter = NumberFormat.compactCurrency(symbol: '', decimalDigits: 0);
  if (min != null && max != null) {
    return '${formatter.format(min).trim()} - ${formatter.format(max).trim()}';
  }
  if (max != null) {
    return '≤ ${formatter.format(max).trim()}';
  }
  return '≥ ${formatter.format(min).trim()}';
}

String _reasonLabel(AppLocalizations l, String reason) {
  return switch (reason) {
    'sameCompound' => l.propertyMatchSameCompound,
    'sameLocation' => l.propertyMatchSameLocation,
    'samePropertyType' => l.propertyMatchSameType,
    'withinBudget' => l.propertyMatchWithinBudget,
    'closeToBudget' => l.propertyMatchCloseToBudget,
    'availableNow' => l.propertyMatchAvailableNow,
    _ => l.matchingDemandTitle,
  };
}
