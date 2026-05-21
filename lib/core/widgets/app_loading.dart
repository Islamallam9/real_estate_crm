import 'package:flutter/material.dart';

import 'app_shimmer.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AppShimmerLoading(message: message);
  }
}
