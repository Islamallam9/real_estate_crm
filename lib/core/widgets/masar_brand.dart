import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    return SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(
        'assets/branding/masar_mark.svg',
        fit: fit,
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
    return SizedBox(
      height: height,
      child: SvgPicture.asset(
        'assets/branding/masar_logo.svg',
        fit: fit,
      ),
    );
  }
}