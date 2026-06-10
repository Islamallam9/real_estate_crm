import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'app_status_badge.dart';

class ModuleKpiCardData {
  const ModuleKpiCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    this.subtitle,
    this.onTap,
    this.selected = false,
    this.loading = false,
    this.error = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final AppStatusTone tone;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool selected;
  final bool loading;
  final bool error;
}

class ModuleKpiStrip extends StatelessWidget {
  const ModuleKpiStrip({
    super.key,
    required this.cards,
    this.cardWidth = 172,
    this.cardHeight = 104,
    this.scrollable = true,
  });

  final List<ModuleKpiCardData> cards;
  final double cardWidth;
  final double cardHeight;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!scrollable) {
      return SizedBox(
        height: cardHeight,
        child: Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(
                child: SizedBox(
                  height: cardHeight,
                  child: ModuleKpiCard(data: cards[index]),
                ),
              ),
              if (index != cards.length - 1)
                const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        primary: false,
        itemCount: cards.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: ModuleKpiCard(data: cards[index]),
          );
        },
      ),
    );
  }
}

class ModuleKpiCard extends StatelessWidget {
  const ModuleKpiCard({super.key, required this.data});

  final ModuleKpiCardData data;

  @override
  Widget build(BuildContext context) {
    final toneColor = moduleKpiToneColor(context, data.tone);
    final borderColor = data.selected
        ? toneColor.withValues(alpha: 0.72)
        : toneColor.withValues(alpha: 0.24);
    final isLoadingValue = data.loading || data.value.trim() == '…';
    final card = Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: data.selected
            ? toneColor.withValues(alpha: 0.08)
            : AppColors.cardSurface(context),
        border: Border.all(color: borderColor),
        borderRadius: AppRadius.large,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.medium,
            ),
            child: Icon(data.icon, color: toneColor, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (isLoadingValue)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: toneColor,
                    ),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      data.value,
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: data.error
                                ? AppColors.errorColor(context)
                                : AppColors.textPrimaryColor(context),
                          ),
                    ),
                  ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    data.label,
                    maxLines: data.subtitle == null ? 3 : 2,
                    softWrap: true,
                    overflow: TextOverflow.fade,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                  ),
                ),
                if (data.subtitle != null) ...[
                  const SizedBox(height: 1),
                  Flexible(
                    child: Text(
                      data.subtitle!,
                      maxLines: 1,
                      softWrap: true,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (data.onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: data.onTap,
        child: card,
      ),
    );
  }
}

Color moduleKpiToneColor(BuildContext context, AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.success => AppColors.successColor(context),
    AppStatusTone.warning => AppColors.warningColor(context),
    AppStatusTone.error => AppColors.errorColor(context),
    AppStatusTone.info => AppColors.infoColor(context),
    AppStatusTone.neutral => AppColors.textSecondaryColor(context),
  };
}
