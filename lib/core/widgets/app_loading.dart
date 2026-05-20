import 'package:flutter/material.dart';

import 'masar_loading_view.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return MasarLoadingView(message: message, compact: true);
  }
}
