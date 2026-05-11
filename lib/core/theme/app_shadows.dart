import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const subtle = [
    BoxShadow(color: Color(0x0F10243D), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const card = [
    BoxShadow(color: Color(0x0A10243D), blurRadius: 12, offset: Offset(0, 6)),
  ];

  static const shell = [
    BoxShadow(color: Color(0x2410243D), blurRadius: 28, offset: Offset(0, 16)),
  ];
}
