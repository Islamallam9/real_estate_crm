import 'package:flutter/material.dart';

import '../../../../core/widgets/app_dropdown.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../users/domain/entities/assignment_user_policy.dart';
import '../../../users/domain/entities/user_profile.dart';

class ClientAssignmentDropdown extends StatelessWidget {
  const ClientAssignmentDropdown({
    super.key,
    required this.users,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.includeAllOption = false,
    this.includeUnassignedOption = false,
    this.label,
  });

  final List<UserProfile> users;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final bool includeAllOption;
  final bool includeUnassignedOption;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = _clientAssigneeOptions(
      users,
      includeAllOption: includeAllOption,
      includeUnassignedOption: includeUnassignedOption,
    );

    return AppDropdown<_ClientAssigneeOption>(
      label: label ?? l.assignedTo,
      value: _ClientAssigneeOption.fromValue(value),
      items: options,
      itemLabelBuilder: (option) => option.isAll
          ? includeAllOption
                ? l.allAssignees
                : l.unassigned
          : _assigneeLabel(l, users, option.value),
      enabled: enabled,
      onChanged: (option) => onChanged(option.value),
    );
  }
}

class ClientAssignmentField extends StatelessWidget {
  const ClientAssignmentField({
    super.key,
    required this.users,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final List<UserProfile> users;
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClientAssignmentDropdown(
        users: users,
        value: value,
        enabled: enabled,
        includeUnassignedOption: true,
        onChanged: (uid) => onChanged(uid ?? ''),
      ),
    );
  }
}

class _ClientAssigneeOption {
  const _ClientAssigneeOption._({required this.value, required this.isAll});

  const _ClientAssigneeOption.all() : this._(value: null, isAll: true);

  const _ClientAssigneeOption.value(String value)
    : this._(value: value, isAll: false);

  factory _ClientAssigneeOption.fromValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty
        ? const _ClientAssigneeOption.all()
        : _ClientAssigneeOption.value(trimmed);
  }

  final String? value;
  final bool isAll;

  @override
  bool operator ==(Object other) {
    return other is _ClientAssigneeOption &&
        other.isAll == isAll &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(value, isAll);
}

List<_ClientAssigneeOption> _clientAssigneeOptions(
  List<UserProfile> users, {
  required bool includeAllOption,
  required bool includeUnassignedOption,
}) {
  final assignableUsers = users.where(_isAssignableUser).toList()
    ..sort((a, b) => a.fullName.compareTo(b.fullName));

  return [
    if (includeAllOption || includeUnassignedOption)
      const _ClientAssigneeOption.all(),
    for (final user in assignableUsers) _ClientAssigneeOption.value(user.uid),
  ];
}

bool _isAssignableUser(UserProfile user) {
  return AssignmentUserPolicy.canOwn(AssignableWorkType.client, user);
}

String _assigneeLabel(
  AppLocalizations localizations,
  List<UserProfile> users,
  String? uid,
) {
  final value = uid?.trim() ?? '';
  if (value.isEmpty) {
    return localizations.unassigned;
  }
  for (final user in users) {
    if (user.uid == value) {
      return user.fullName.trim().isEmpty ? user.email : user.fullName;
    }
  }
  return localizations.assignedUserUnavailable;
}
