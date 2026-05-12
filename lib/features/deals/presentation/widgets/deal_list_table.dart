import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/deal.dart';
import 'deal_card.dart';

class DealListTable extends StatelessWidget {
  const DealListTable({
    super.key,
    required this.deals,
    required this.onOpen,
    this.onEdit,
    this.onUpdateStage,
    this.onArchive,
  });

  final List<Deal> deals;
  final ValueChanged<Deal> onOpen;
  final ValueChanged<Deal>? onEdit;
  final ValueChanged<Deal>? onUpdateStage;
  final ValueChanged<Deal>? onArchive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface(context),
                border: Border.all(color: AppColors.borderColor(context)),
                borderRadius: AppRadius.large,
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : AppShadows.card,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: AppColors.inputSurface(context),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        _Header(l.client, flex: 3),
                        _Header(l.property, flex: 3),
                        _Header(l.dealStage, flex: 2),
                        _Header(l.expectedValue, flex: 2),
                        _Header(l.assignedAgent, flex: 2),
                        _Header(l.closingDate, flex: 2),
                        _Header(l.actions, flex: 2),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.borderColor(context)),
                  ...List.generate(deals.length, (index) {
                    final deal = deals[index];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => onOpen(deal),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              AppSpacing.md,
                              AppSpacing.xs,
                              AppSpacing.md,
                              AppSpacing.xs,
                            ),
                            child: SizedBox(
                              height: 48,
                              child: Row(
                                children: [
                                  _Cell(
                                    _fallback(deal.clientName, l.notAvailable),
                                    flex: 3,
                                  ),
                                  _Cell(
                                    _fallback(deal.propertyTitle, l.notAvailable),
                                    flex: 3,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: AppStatusBadge(
                                        label: dealStageLabel(l, deal.stage),
                                        tone: dealStageTone(deal.stage),
                                      ),
                                    ),
                                  ),
                                  _Cell(
                                    '${_formatNumber(context, deal.expectedValue)} / ${_formatNumber(context, deal.commission)}',
                                    flex: 2,
                                  ),
                                  _Cell(
                                    _fallback(deal.assignedToName, l.unassigned),
                                    flex: 2,
                                  ),
                                  _Cell(
                                    _formatDate(context, deal.closingDate, l),
                                    flex: 2,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _ActionIcon(
                                            tooltip: l.viewDetails,
                                            icon: Icons.open_in_new,
                                            onPressed: () => onOpen(deal),
                                          ),
                                          if (onUpdateStage != null)
                                            _ActionIcon(
                                              tooltip: l.updateStage,
                                              icon: Icons.swap_horiz,
                                              onPressed: () => onUpdateStage!(deal),
                                            ),
                                          if (onEdit != null)
                                            _ActionIcon(
                                              tooltip: l.edit,
                                              icon: Icons.edit_outlined,
                                              onPressed: () => onEdit!(deal),
                                            ),
                                          if (onArchive != null)
                                            _ActionIcon(
                                              tooltip: l.archiveDeal,
                                              icon: Icons.archive_outlined,
                                              onPressed: () => onArchive!(deal),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (index != deals.length - 1)
                          Divider(
                            height: 1,
                            color: AppColors.borderColor(context),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );  }
}

class _Header extends StatelessWidget {
  const _Header(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondaryColor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _formatNumber(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(localeName).format(value);
}

String _formatDate(BuildContext context, DateTime? value, AppLocalizations l) {
  if (value == null) {
    return l.notAvailable;
  }
  return MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
}
