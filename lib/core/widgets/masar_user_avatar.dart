import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MasarUserAvatar extends StatelessWidget {
  const MasarUserAvatar({
    super.key,
    required this.name,
    this.photoUrl = '',
    this.cacheKey = '',
    this.radius = 18,
  });

  final String name;
  final String photoUrl;
  final String cacheKey;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cleanUrl = photoUrl.trim();
    final displayUrl = _cacheSafeUrl(cleanUrl, cacheKey);
    final fallback = _MasarUserInitialAvatar(
      initial: _initialFor(name),
      radius: radius,
    );

    if (displayUrl.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          displayUrl,
          key: ValueKey(displayUrl),
          fit: BoxFit.cover,
          gaplessPlayback: false,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return fallback;
          },
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

class _MasarUserInitialAvatar extends StatelessWidget {
  const _MasarUserInitialAvatar({required this.initial, required this.radius});

  final String initial;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryColor(context).withValues(alpha: 0.18),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primaryColor(context),
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

String _cacheSafeUrl(String url, String cacheKey) {
  final cleanUrl = url.trim();
  if (cleanUrl.isEmpty) {
    return '';
  }

  final cleanKey = cacheKey.trim();
  if (cleanKey.isEmpty) {
    return cleanUrl;
  }

  final separator = cleanUrl.contains('?') ? '&' : '?';
  return '$cleanUrl${separator}masarProfileVersion=${Uri.encodeComponent(cleanKey)}';
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.characters.first.toUpperCase();
}
