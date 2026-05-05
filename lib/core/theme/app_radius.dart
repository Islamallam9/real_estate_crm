import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;

  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
}
