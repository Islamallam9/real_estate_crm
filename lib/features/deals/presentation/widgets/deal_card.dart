import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/deal.dart';

class DealCard extends StatelessWidget {
  const DealCard({
    super.key,
    required this.deal,
    required this.onTap,
    this.onEdit,
    this.onUpdateStage,
    this.onArchive,
    this.onRestore,
    this.isArchivedView = false,
  });

  final Deal deal;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onUpdateStage;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final bool isArchivedView;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      color: AppColors.cardSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor(context)),
            borderRadius: AppRadius.large,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? null
                : AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dealTitle(l, deal),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (isArchivedView || deal.isArchived) ...[
                    AppStatusBadge(
                      label: l.archived,
                      tone: AppStatusTone.neutral,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  AppStatusBadge(
                    label: dealStageLabel(l, deal.stage),
                    tone: dealStageTone(deal.stage),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _fallback(deal.propertyTitle, l.notAvailable),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _MetaChip(label: l.expectedValue, value: _formatMoney(context, deal.expectedValue)),
                  _MetaChip(label: l.commission, value: _formatMoney(context, deal.commission)),
                  _MetaChip(label: l.assignedAgent, value: _fallback(deal.assignedToName, l.unassigned)),
                ],
              ),
              if (onEdit != null ||
                  onUpdateStage != null ||
                  onArchive != null ||
                  onRestore != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    if (onUpdateStage != null)
                      TextButton.icon(
                        onPressed: onUpdateStage,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: Text(l.updateStage),
                      ),
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l.edit),
                      ),
                    if (onArchive != null)
                      TextButton.icon(
                        onPressed: onArchive,
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: Text(l.archive),
                      ),
                    if (onRestore != null)
                      TextButton.icon(
                        onPressed: onRestore,
                        icon: const Icon(Icons.unarchive_outlined, size: 18),
                        label: Text(l.restore),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          '$label: $value',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondaryColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String dealStageLabel(AppLocalizations l, DealStage stage) {
  switch (stage) {
    case DealStage.newDeal:
      return l.newDealStage;
    case DealStage.qualified:
      return l.qualified;
    case DealStage.proposal:
      return l.proposal;
    case DealStage.negotiation:
      return l.negotiation;
    case DealStage.won:
      return l.won;
    case DealStage.lost:
      return l.lost;
  }
}

AppStatusTone dealStageTone(DealStage stage) {
  switch (stage) {
    case DealStage.won:
      return AppStatusTone.success;
    case DealStage.lost:
      return AppStatusTone.error;
    case DealStage.negotiation:
    case DealStage.proposal:
      return AppStatusTone.warning;
    case DealStage.qualified:
      return AppStatusTone.info;
    case DealStage.newDeal:
      return AppStatusTone.neutral;
  }
}

String _dealTitle(AppLocalizations l, Deal deal) {
  final client = deal.clientName.trim();
  final property = deal.propertyTitle.trim();
  if (client.isEmpty && property.isEmpty) {
    return l.deal;
  }
  if (client.isEmpty) {
    return property;
  }
  if (property.isEmpty) {
    return client;
  }
  return '$client - $property';
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _formatMoney(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(localeName).format(value);
}
