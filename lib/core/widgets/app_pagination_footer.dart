import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

class AppPaginationFooter extends StatelessWidget {
  const AppPaginationFooter({
    super.key,
    required this.loadedCount,
    required this.pageSize,
    required this.isLoading,
    required this.onLoadMore,
    this.totalCount,
  });

  final int loadedCount;
  final int pageSize;
  final bool isLoading;
  final VoidCallback onLoadMore;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 640;
    final safeTotal = totalCount == null || totalCount! < loadedCount
        ? null
        : totalCount;
    final remainingCount = safeTotal == null
        ? null
        : (safeTotal - loadedCount).clamp(0, pageSize);
    final label =
        remainingCount == null ? l.more : '${l.more} +$remainingCount';
    final loadedText = safeTotal == null
        ? '$loadedCount ${l.records}'
        : '$loadedCount / $safeTotal ${l.records}';

    return Align(
      alignment: AlignmentDirectional.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? double.infinity : 380),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.selectedSurface(context),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: AppColors.primaryColor(context).withValues(alpha: 0.55),
            ),
          ),
          child: compact
              ? Row(
                  children: [
                    Expanded(child: _LoadedCountLabel(loadedText: loadedText)),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: label,
                      icon: Icons.expand_more_rounded,
                      variant: AppButtonVariant.primary,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : onLoadMore,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _LoadedCountLabel(loadedText: loadedText)),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: label,
                      icon: Icons.expand_more_rounded,
                      variant: AppButtonVariant.primary,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : onLoadMore,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LoadedCountLabel extends StatelessWidget {
  const _LoadedCountLabel({required this.loadedText});

  final String loadedText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.view_list_rounded,
          size: 18,
          color: AppColors.primaryColor(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            loadedText,
            maxLines: 2,
            softWrap: true,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryColor(context),
            ),
          ),
        ),
      ],
    );
  }
}
