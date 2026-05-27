import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/masar_loading_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import 'property_labels.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    required this.canEdit,
    required this.canDeactivate,
    required this.onDeactivate,
  });

  final Property property;
  final bool canEdit;
  final bool canDeactivate;
  final ValueChanged<Property> onDeactivate;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppColors.cardSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: () => context.go(RouteNames.propertyDetails(property.id)),
        borderRadius: AppRadius.large,
        child: Ink(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: _PropertyImageCarousel(property: property),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayText(localizations, property.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AppStatusBadge(
                                label: propertyStatusLabel(
                                  localizations,
                                  property.status,
                                ),
                                tone: propertyStatusTone(property.status),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _displayText(localizations, property.location),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MetaChip(
                          label: propertyTypeLabel(
                            localizations,
                            property.propertyType,
                          ),
                        ),
                        _MetaChip(
                          label: propertyListingTypeLabel(
                            localizations,
                            property.listingType,
                          ),
                        ),
                        _MetaChip(label: _formatNumber(context, property.price)),
                        if (property.area > 0)
                          _MetaChip(label: _formatNumber(context, property.area)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyImageCarousel extends StatefulWidget {
  const _PropertyImageCarousel({required this.property});

  final Property property;

  @override
  State<_PropertyImageCarousel> createState() => _PropertyImageCarouselState();
}

class _PropertyImageCarouselState extends State<_PropertyImageCarousel> {
  late final PageController _controller;
  var _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.property.imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .take(5)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final carouselHeight = (constraints.maxWidth * 0.58)
            .clamp(118.0, 170.0)
            .toDouble();

        return ClipRRect(
          borderRadius: AppRadius.medium,
          child: SizedBox(
            height: carouselHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (images.isEmpty)
                  ColoredBox(
                    color: AppColors.appBackground(context),
                    child: Icon(
                      Icons.real_estate_agent_outlined,
                      size: 40,
                      color: AppColors.textMutedColor(context),
                    ),
                  )
                else
                  PageView.builder(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return _PropertyCardNetworkImage(
                        imageUrl: images[index],
                      );
                    },
                  ),
                if (images.length > 1) ...[
                  PositionedDirectional(
                    start: AppSpacing.sm,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ImageArrowButton(
                        icon: Icons.chevron_left,
                        onPressed: () {
                          final nextIndex = _currentIndex == 0
                              ? images.length - 1
                              : _currentIndex - 1;
                          _controller.animateToPage(
                            nextIndex,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: AppSpacing.sm,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ImageArrowButton(
                        icon: Icons.chevron_right,
                        onPressed: () {
                          final nextIndex = _currentIndex == images.length - 1
                              ? 0
                              : _currentIndex + 1;
                          _controller.animateToPage(
                            nextIndex,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PropertyCardNetworkImage extends StatelessWidget {
  const _PropertyCardNetworkImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return ColoredBox(
            color: AppColors.appBackground(context),
            child: const Center(
              child: MasarLogoLoader(size: 30),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: AppColors.appBackground(context),
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.textMutedColor(context),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      memCacheWidth: 600,
      memCacheHeight: 420,
      placeholder: (context, url) => ColoredBox(
        color: AppColors.appBackground(context),
        child: const Center(
          child: MasarLogoLoader(size: 30),
        ),
      ),
      errorWidget: (context, url, error) => ColoredBox(
        color: AppColors.appBackground(context),
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textMutedColor(context),
        ),
      ),
    );
  }
}

class _ImageArrowButton extends StatelessWidget {
  const _ImageArrowButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondaryColor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _displayText(AppLocalizations localizations, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? localizations.notAvailable : trimmed;
}

String _formatNumber(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(localeName).format(value);
}
