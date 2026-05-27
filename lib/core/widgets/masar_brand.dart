import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _masarLogoSurface = Color(0xFFFFF8EA);
const _masarLogoBorder = Color(0xFFE6D8C1);

class MasarBrandMark extends StatelessWidget {
  const MasarBrandMark({
    super.key,
    this.size = 48,
    this.fit = BoxFit.contain,
  });

  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final padding = (size * 0.10).clamp(2.0, 8.0).toDouble();
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _masarLogoSurface,
          borderRadius: BorderRadius.circular(size * 0.26),
          border: Border.all(color: _masarLogoBorder),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: SvgPicture.asset(
            'assets/branding/masar_mark.svg',
            fit: fit,
          ),
        ),
      ),
    );
  }
}

class MasarBrandLogo extends StatelessWidget {
  const MasarBrandLogo({
    super.key,
    this.height = 44,
    this.fit = BoxFit.contain,
  });

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logo = SizedBox(
      height: height,
      child: SvgPicture.asset(
        'assets/branding/masar_logo.svg',
        fit: fit,
      ),
    );

    if (!isDark) {
      return logo;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _masarLogoSurface,
        borderRadius: BorderRadius.circular(height * 0.28),
        border: Border.all(color: _masarLogoBorder),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: (height * 0.22).clamp(8.0, 18.0).toDouble(),
          vertical: (height * 0.10).clamp(4.0, 10.0).toDouble(),
        ),
        child: logo,
      ),
    );
  }
}