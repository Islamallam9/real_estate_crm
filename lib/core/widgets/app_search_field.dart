import 'package:flutter/material.dart';

import 'app_text_field.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onClear,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint,
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      suffixIcon: onClear == null
          ? null
          : IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close),
              onPressed: onClear,
            ),
    );
  }
}
