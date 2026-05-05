import 'package:flutter/material.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.itemLabel,
    this.value,
    this.label,
    this.hint,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final List<T> items;
  final String Function(T item) itemLabel;
  final T? value;
  final String? label;
  final String? hint;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      validator: validator,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(labelText: label, hintText: hint),
      items: items
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))),
          )
          .toList(),
    );
  }
}
