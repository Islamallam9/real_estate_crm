import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/intelligence/property_match_evaluator.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../properties/data/datasources/properties_remote_data_source.dart';
import '../../../properties/data/models/property_model.dart';
import '../../../properties/data/repositories/property_repository_impl.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/usecases/find_available_properties_for_matching_usecase.dart';
import '../../../properties/presentation/widgets/property_labels.dart';

class MatchingPropertiesCard extends StatefulWidget {
  const MatchingPropertiesCard({
    super.key,
    required this.companyId,
    required this.preferredLocation,
    required this.preferredPropertyType,
    required this.budgetMin,
    required this.budgetMax,
    this.isClient = false,
  });

  final String companyId;
  final String preferredLocation;
  final String preferredPropertyType;
  final num? budgetMin;
  final num? budgetMax;
  final bool isClient;

  @override
  State<MatchingPropertiesCard> createState() => _MatchingPropertiesCardState();
}

class _MatchingPropertiesCardState extends State<MatchingPropertiesCard> {
  Future<List<_PropertyMatchViewData>>? _future;
  String _requestKey = '';

  @override
  void initState() {
    super.initState();
    _refreshIfNeeded(force: true);
  }

  @override
  void didUpdateWidget(covariant MatchingPropertiesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshIfNeeded();
  }

  void _refreshIfNeeded({bool force = false}) {
    final key = [
      widget.companyId,
      widget.preferredLocation.trim(),
      widget.preferredPropertyType.trim(),
      widget.budgetMin?.toString() ?? '',
      widget.budgetMax?.toString() ?? '',
    ].join('|');
    if (!force && key == _requestKey) {
      return;
    }
    _requestKey = key;
    _future = _loadMatches();
  }

  Future<List<_PropertyMatchViewData>> _loadMatches() async {
    final request = PropertyMatchRequest(
      preferredLocation: widget.preferredLocation,
      preferredPropertyType: widget.preferredPropertyType,
      budgetMin: widget.budgetMin,
      budgetMax: widget.budgetMax,
    );
    if (widget.companyId.trim().isEmpty || !request.hasUsablePreferences) {
      return const <_PropertyMatchViewData>[];
    }

    final repository = PropertyRepositoryImpl(
      remoteDataSource: FirestorePropertiesRemoteDataSource(),
    );
    final properties = await FindAvailablePropertiesForMatchingUseCase(
      repository,
    )(companyId: widget.companyId, limit: 120);

    final byId = <String, Property>{
      for (final property in properties) property.id: property,
    };
    final matches = PropertyMatchEvaluator.evaluate(
      request: request,
      candidates: properties.map(_candidateFromProperty).toList(growable: false),
      limit: 3,
    );

    return matches
        .map((match) {
          final property = byId[match.candidate.id];
          if (property == null) {
            return null;
          }
          return _PropertyMatchViewData(property: property, match: match);
        })
        .whereType<_PropertyMatchViewData>()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final request = PropertyMatchRequest(
      preferredLocation: widget.preferredLocation,
      preferredPropertyType: widget.preferredPropertyType,
      budgetMin: widget.budgetMin,
      budgetMax: widget.budgetMax,
    );

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
                  Icons.real_estate_agent_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.matchingPropertiesTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.isClient
                          ? l.matchingPropertiesClientSubtitle
                          : l.matchingPropertiesLeadSubtitle,
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
          if (!request.hasUsablePreferences)
            _EmptyMatchingState(message: l.matchingPropertiesAddPreferences)
          else
            FutureBuilder<List<_PropertyMatchViewData>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _EmptyMatchingState(
                    message: localizeErrorMessage(
                      l,
                      snapshot.error?.toString() ??
                          l.matchingPropertiesLoadFailed,
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
                final matches = snapshot.data ?? const <_PropertyMatchViewData>[];
                if (matches.isEmpty) {
                  return _EmptyMatchingState(
                    message: l.matchingPropertiesNoMatches,
                  );
                }
                return Column(
                  children: [
                    for (var index = 0; index < matches.length; index++) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.sm),
                      _PropertyMatchTile(data: matches[index]),
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

class _PropertyMatchTile extends StatelessWidget {
  const _PropertyMatchTile({required this.data});

  final _PropertyMatchViewData data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final property = data.property;
    final priceText = _formatMoney(context, property.price);
    final meta = [
      propertyTypeLabel(l, property.propertyType),
      if (property.location.trim().isNotEmpty) property.location.trim(),
      if (property.compound.trim().isNotEmpty) property.compound.trim(),
    ].join(' • ');

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
                      property.title.trim().isEmpty
                          ? l.propertyDetails
                          : property.title.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      meta,
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
              AppStatusBadge(
                label: '${data.match.score}%',
                tone: AppStatusTone.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(label: priceText, tone: AppStatusTone.neutral),
              for (final reason in data.match.reasons.take(3))
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
              label: l.viewProperty,
              icon: Icons.open_in_new_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(RouteNames.propertyDetails(property.id)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMatchingState extends StatelessWidget {
  const _EmptyMatchingState({required this.message, this.action});

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

class _PropertyMatchViewData {
  const _PropertyMatchViewData({required this.property, required this.match});

  final Property property;
  final PropertyMatchResult match;
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

String _reasonLabel(AppLocalizations l, String reason) {
  return switch (reason) {
    'sameCompound' => l.propertyMatchSameCompound,
    'sameLocation' => l.propertyMatchSameLocation,
    'samePropertyType' => l.propertyMatchSameType,
    'withinBudget' => l.propertyMatchWithinBudget,
    'closeToBudget' => l.propertyMatchCloseToBudget,
    'availableNow' => l.propertyMatchAvailableNow,
    _ => l.matchingPropertiesTitle,
  };
}

String _formatMoney(BuildContext context, num value) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.compactCurrency(
    locale: locale,
    symbol: '',
    decimalDigits: 0,
  ).format(value).trim();
}
