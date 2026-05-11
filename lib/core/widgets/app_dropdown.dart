import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
    this.enabled = true,
    this.validator,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabelBuilder;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        final theme = Theme.of(context);
        final selectedLabel = itemLabelBuilder(field.value ?? value);

        return PopupMenuButton<T>(
          enabled: enabled,
          tooltip: label,
          elevation: 10,
          color: theme.colorScheme.surface,
          surfaceTintColor: theme.colorScheme.surface,
          position: PopupMenuPosition.under,
          offset: const Offset(0, 8),
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
            side: BorderSide(color: theme.dividerColor),
          ),
          onSelected: (selected) {
            field.didChange(selected);
            onChanged(selected);
          },
          itemBuilder: (context) {
            return [
              for (final item in items)
                PopupMenuItem<T>(
                  value: item,
                  height: 38,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    itemLabelBuilder(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ];
          },
          child: InputDecorator(
            isEmpty: false,
            decoration: InputDecoration(
              labelText: label,
              errorText: field.errorText,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.large,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.large,
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.large,
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              enabled: enabled,
            ),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: enabled ? null : theme.disabledColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: enabled
                        ? theme.iconTheme.color
                        : theme.disabledColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
