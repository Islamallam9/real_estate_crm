import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../users/domain/entities/assignment_user_policy.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/appointment_related_record_option.dart';
import '../cubit/appointments_cubit.dart';
import '../cubit/appointments_state.dart';

class AppointmentForm extends StatefulWidget {
  const AppointmentForm({
    super.key,
    required this.companyId,
    required this.actorUid,
    required this.onSubmit,
    this.appointment,
    this.users = const [],
    this.canEditAssignment = false,
    this.canEditStatus = false,
    this.assignedTo = '',
    this.relatedRecordsAssignedTo,
    this.relatedRecordsManagerId,
    this.relatedRecordsTeamId,
    this.initialRelatedType,
    this.initialRelatedId = '',
    this.initialRelatedTitle = '',
    this.initialRelatedSubtitle = '',
    this.initialTitle = '',
    this.isSaving = false,
    this.submitLabel,
  });

  final String companyId;
  final String actorUid;
  final ValueChanged<Appointment> onSubmit;
  final Appointment? appointment;
  final List<UserProfile> users;
  final bool canEditAssignment;
  final bool canEditStatus;
  final String assignedTo;
  final String? relatedRecordsAssignedTo;
  final String? relatedRecordsManagerId;
  final String? relatedRecordsTeamId;
  final AppointmentRelatedType? initialRelatedType;
  final String initialRelatedId;
  final String initialRelatedTitle;
  final String initialRelatedSubtitle;
  final String initialTitle;
  final bool isSaving;
  final String? submitLabel;

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _outcomeNotesController = TextEditingController();
  final _cancellationReasonController = TextEditingController();

  AppointmentType _type = AppointmentType.meeting;
  AppointmentStatus _status = AppointmentStatus.scheduled;
  AppointmentOutcome _outcome = AppointmentOutcome.successfulMeeting;
  AppointmentRelatedType _relatedType = AppointmentRelatedType.general;
  DateTime? _date;
  TimeOfDay? _startTime;
  int _durationMinutes = 60;
  String _assignedTo = '';
  String _assignedToName = '';
  String _assignedToEmail = '';
  String _teamId = '';
  String _teamName = '';
  String _managerId = '';
  String _managerName = '';
  String _relatedId = '';
  String _relatedTitle = '';
  String _relatedSubtitle = '';

  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment;
    _assignedTo = appointment?.assignedTo ?? widget.assignedTo;
    _syncAssignedSnapshot();
    if (appointment == null) {
      final now = DateTime.now().add(const Duration(hours: 1));
      _date = DateTime(now.year, now.month, now.day);
      _startTime = TimeOfDay(hour: now.hour, minute: 0);
      _titleController.text = widget.initialTitle;
      _relatedType = widget.initialRelatedType ?? AppointmentRelatedType.general;
      _relatedId = widget.initialRelatedId.trim();
      _relatedTitle = widget.initialRelatedTitle.trim();
      _relatedSubtitle = widget.initialRelatedSubtitle.trim();
      if (_relatedType != AppointmentRelatedType.general) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _loadRelatedOptions(_relatedType);
        });
      }
      return;
    }

    _titleController.text = appointment.title;
    _locationController.text = appointment.location;
    _notesController.text = appointment.notes;
    _outcomeNotesController.text = appointment.outcomeNotes;
    _cancellationReasonController.text = appointment.cancellationReason;
    _type = appointment.type;
    _status = appointment.status;
    _outcome = appointment.outcome ?? AppointmentOutcome.successfulMeeting;
    _relatedType = appointment.relatedType;
    _durationMinutes = appointment.durationMinutes;
    _assignedToName = appointment.assignedToName;
    _assignedToEmail = appointment.assignedToEmail;
    _teamId = appointment.teamId;
    _teamName = appointment.teamName;
    _managerId = appointment.managerId;
    _managerName = appointment.managerName;
    _relatedId = appointment.relatedId;
    _relatedTitle = appointment.relatedTitle;
    _relatedSubtitle = appointment.relatedSubtitle;
    final scheduledAt = appointment.scheduledAt?.toLocal();
    if (scheduledAt != null) {
      _date = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
      _startTime = TimeOfDay.fromDateTime(scheduledAt);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadRelatedOptions(_relatedType);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _outcomeNotesController.dispose();
    _cancellationReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(context, l.appointmentDetails, [
            AppTextField(
              controller: _titleController,
              label: l.appointmentTitle,
              enabled: !widget.isSaving,
              validator: (value) => _requiredValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 640;
                final typeField = AppDropdown<AppointmentType>(
                  label: l.appointmentType,
                  value: _type,
                  items: AppointmentType.values,
                  itemLabelBuilder: (type) => appointmentTypeLabel(l, type),
                  enabled: !widget.isSaving,
                  onChanged: (value) => setState(() => _type = value),
                );
                final relatedTypeField = AppDropdown<AppointmentRelatedType>(
                  label: l.relatedType,
                  value: _relatedType,
                  items: AppointmentRelatedType.values,
                  itemLabelBuilder: (type) =>
                      appointmentRelatedTypeLabel(l, type),
                  enabled: !widget.isSaving,
                  onChanged: _onRelatedTypeChanged,
                );
                if (compact) {
                  return Column(
                    children: [
                      typeField,
                      const SizedBox(height: AppSpacing.md),
                      relatedTypeField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: typeField),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: relatedTypeField),
                  ],
                );
              },
            ),
            _RelatedRecordPicker(
              type: _relatedType,
              value: _relatedId,
              selectedTitle: _relatedTitle,
              selectedSubtitle: _relatedSubtitle,
              enabled: !widget.isSaving,
              onChanged: (record) {
                setState(() {
                  _relatedId = record?.id ?? '';
                  _relatedTitle = record?.title ?? '';
                  _relatedSubtitle = record?.subtitle ?? '';
                });
              },
            ),
            if (widget.canEditAssignment) ...[
              const SizedBox(height: AppSpacing.md),
              AppDropdown<_AppointmentAssigneeOption>(
                label: l.assignedUser,
                value: _AppointmentAssigneeOption.fromValue(_assignedTo),
                items: _appointmentAssigneeOptions(
                  widget.users,
                  actorUid: widget.actorUid,
                  managerId: widget.relatedRecordsManagerId,
                  teamId: widget.relatedRecordsTeamId,
                ),
                itemLabelBuilder: (option) => option.isUnassigned
                    ? l.unassigned
                    : _assigneeLabel(l, widget.users, option.value),
                enabled: !widget.isSaving,
                onChanged: (option) {
                  setState(() {
                    _assignedTo = option.value ?? '';
                    _syncAssignedSnapshot();
                  });
                },
              ),
            ],
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.appointmentSchedule, [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 640;
                final dateButton = OutlinedButton.icon(
                  onPressed: widget.isSaving ? null : _pickDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(_dateLabel(l)),
                  ),
                );
                final timeButton = OutlinedButton.icon(
                  onPressed: widget.isSaving ? null : _pickStartTime,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(_timeLabel(l)),
                  ),
                );
                final durationField = AppDropdown<int>(
                  label: l.duration,
                  value: _durationMinutes,
                  items: const [15, 30, 45, 60, 90, 120],
                  itemLabelBuilder: (value) => l.durationMinutes(value),
                  enabled: !widget.isSaving,
                  onChanged: (value) =>
                      setState(() => _durationMinutes = value),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      dateButton,
                      const SizedBox(height: AppSpacing.md),
                      timeButton,
                      const SizedBox(height: AppSpacing.md),
                      durationField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: dateButton),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: timeButton),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: durationField),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _locationController,
              label: l.location,
              enabled: !widget.isSaving,
            ),
            if (widget.canEditStatus) ...[
              const SizedBox(height: AppSpacing.md),
              AppDropdown<AppointmentStatus>(
                label: l.status,
                value: _status,
                items: AppointmentStatus.values,
                itemLabelBuilder: (status) =>
                    appointmentStatusLabel(l, status),
                enabled: !widget.isSaving,
                onChanged: (value) => setState(() => _status = value),
              ),
            ],
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.appointmentNotes, [
            AppTextField(
              controller: _notesController,
              label: l.notes,
              enabled: !widget.isSaving,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _outcomeNotesController,
              label: l.outcomeNotes,
              enabled: !widget.isSaving,
              maxLines: 3,
            ),
            if (widget.canEditStatus &&
                _status == AppointmentStatus.completed) ...[
              const SizedBox(height: AppSpacing.md),
              AppDropdown<AppointmentOutcome>(
                label: l.appointmentOutcome,
                value: _outcome,
                items: AppointmentOutcome.values,
                itemLabelBuilder: (outcome) => appointmentOutcomeLabel(l, outcome),
                enabled: !widget.isSaving,
                onChanged: (value) => setState(() => _outcome = value),
              ),
            ],
            if (widget.canEditStatus &&
                _status == AppointmentStatus.cancelled) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _cancellationReasonController,
                label: l.cancellationReason,
                enabled: !widget.isSaving,
                maxLines: 3,
              ),
            ],
          ]),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.submitLabel ?? l.saveAppointment,
            isLoading: widget.isSaving,
            onPressed: widget.isSaving ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _startTime = picked);
    }
  }

  String _dateLabel(AppLocalizations l) {
    final date = _date;
    if (date == null) {
      return l.selectAppointmentDate;
    }
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _timeLabel(AppLocalizations l) {
    final time = _startTime;
    if (time == null) {
      return l.selectStartTime;
    }
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  String? _requiredValidator(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.requiredField;
    }
    return null;
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    final date = _date;
    final startTime = _startTime;
    final l = AppLocalizations.of(context)!;
    if (date == null || startTime == null) {
      AppFeedback.warning(context, l.appointmentDateRequired);
      return;
    }
    if (_durationMinutes <= 0) {
      AppFeedback.warning(context, l.appointmentDurationRequired);
      return;
    }
    final assignedTo = widget.canEditAssignment
        ? _assignedTo
        : widget.appointment?.assignedTo ?? widget.assignedTo;
    if (assignedTo.trim().isEmpty) {
      AppFeedback.warning(context, l.appointmentAssigneeRequired);
      return;
    }
    if (_relatedType != AppointmentRelatedType.general &&
        _relatedId.trim().isEmpty) {
      AppFeedback.warning(context, l.relatedRecordRequired);
      return;
    }

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endAt = scheduledAt.add(Duration(minutes: _durationMinutes));
    if (!endAt.isAfter(scheduledAt)) {
      AppFeedback.warning(context, l.appointmentEndAfterStartRequired);
      return;
    }

    final previous = widget.appointment;
    final selectedAssignee = _selectedAssignee();
    final assignedToName = selectedAssignee?.fullName ?? _assignedToName;
    final assignedToEmail = selectedAssignee?.email ?? _assignedToEmail;
    final teamId = selectedAssignee?.teamId ?? _teamId;
    final teamName = selectedAssignee?.teamName ?? _teamName;
    final managerId = selectedAssignee?.managerId ?? _managerId;
    final managerName = selectedAssignee?.managerName ?? _managerName;
    final selectedRelatedRecord = _selectedRelatedRecordFromState();
    final relatedTitle = selectedRelatedRecord?.title ?? _relatedTitle;
    final relatedSubtitle = selectedRelatedRecord?.subtitle ?? _relatedSubtitle;

    widget.onSubmit(
      Appointment(
        id: previous?.id ?? '',
        companyId: widget.companyId,
        title: _titleController.text.trim(),
        type: _type,
        status: widget.canEditStatus
            ? _status
            : previous?.status ?? AppointmentStatus.scheduled,
        scheduledAt: scheduledAt,
        endAt: endAt,
        durationMinutes: _durationMinutes,
        assignedTo: assignedTo.trim(),
        assignedToName: assignedTo.trim().isEmpty ? '' : assignedToName.trim(),
        assignedToEmail:
            assignedTo.trim().isEmpty ? '' : assignedToEmail.trim(),
        teamId: assignedTo.trim().isEmpty ? '' : teamId.trim(),
        teamName: assignedTo.trim().isEmpty ? '' : teamName.trim(),
        managerId: assignedTo.trim().isEmpty ? '' : managerId.trim(),
        managerName: assignedTo.trim().isEmpty ? '' : managerName.trim(),
        relatedType: _relatedType,
        relatedId: _relatedType == AppointmentRelatedType.general
            ? ''
            : _relatedId.trim(),
        relatedTitle: _relatedType == AppointmentRelatedType.general
            ? ''
            : relatedTitle.trim(),
        relatedSubtitle: _relatedType == AppointmentRelatedType.general
            ? ''
            : relatedSubtitle.trim(),
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
        outcome: _status == AppointmentStatus.completed ? _outcome : null,
        outcomeNotes: _outcomeNotesController.text.trim(),
        cancellationReason: _cancellationReasonController.text.trim(),
        createdAt: previous?.createdAt,
        createdBy: previous?.createdBy ?? widget.actorUid,
        updatedAt: DateTime.now(),
        updatedBy: widget.actorUid,
        completedAt: previous?.completedAt,
        completedBy: previous?.completedBy ?? '',
        cancelledAt: previous?.cancelledAt,
        cancelledBy: previous?.cancelledBy ?? '',
        missedAt: previous?.missedAt,
        missedBy: previous?.missedBy ?? '',
        rescheduledFrom: previous?.rescheduledFrom,
        previousScheduledAt: previous?.previousScheduledAt,
        previousEndAt: previous?.previousEndAt,
      ),
    );
  }

  AppointmentRelatedRecordOption? _selectedRelatedRecordFromState() {
    if (_relatedId.trim().isEmpty) {
      return null;
    }
    final state = context.read<AppointmentsCubit>().state;
    if (state.relatedRecordsType != _relatedType) {
      return null;
    }
    for (final option in state.relatedRecordOptions) {
      if (option.id == _relatedId.trim()) {
        return option;
      }
    }
    return null;
  }

  UserProfile? _selectedAssignee() {
    final uid = _assignedTo.trim();
    if (uid.isEmpty) {
      return null;
    }
    for (final user in widget.users) {
      if (user.uid == uid) {
        return user;
      }
    }
    return null;
  }

  void _syncAssignedSnapshot() {
    final user = _selectedAssignee();
    if (user == null) {
      if (_assignedTo.trim().isEmpty) {
        _assignedToName = '';
        _assignedToEmail = '';
        _teamId = '';
        _teamName = '';
        _managerId = '';
        _managerName = '';
      }
      return;
    }
    _assignedToName = user.fullName;
    _assignedToEmail = user.email;
    _teamId = user.teamId;
    _teamName = user.teamName;
    _managerId = user.managerId;
    _managerName = user.managerName;
  }

  void _onRelatedTypeChanged(AppointmentRelatedType value) {
    setState(() {
      _relatedType = value;
      _relatedId = '';
      _relatedTitle = '';
      _relatedSubtitle = '';
    });
    _loadRelatedOptions(value);
  }

  void _loadRelatedOptions(AppointmentRelatedType type) {
    final cubit = context.read<AppointmentsCubit>();
    if (type == AppointmentRelatedType.general) {
      cubit.clearRelatedRecordOptions();
      return;
    }
    cubit.loadRelatedRecordOptions(
      companyId: widget.companyId,
      type: type,
      assignedTo: widget.relatedRecordsAssignedTo,
      managerId: widget.relatedRecordsManagerId,
      teamId: widget.relatedRecordsTeamId,
    );
  }
}

class _RelatedRecordPicker extends StatelessWidget {
  const _RelatedRecordPicker({
    required this.type,
    required this.value,
    required this.selectedTitle,
    required this.selectedSubtitle,
    required this.onChanged,
    required this.enabled,
  });

  final AppointmentRelatedType type;
  final String value;
  final String selectedTitle;
  final String selectedSubtitle;
  final ValueChanged<AppointmentRelatedRecordOption?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (type == AppointmentRelatedType.general) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: BlocBuilder<AppointmentsCubit, AppointmentsState>(
        buildWhen: (previous, current) =>
            previous.relatedRecordsStatus != current.relatedRecordsStatus ||
            previous.relatedRecordOptions != current.relatedRecordOptions ||
            previous.relatedRecordsType != current.relatedRecordsType,
        builder: (context, state) {
          if (state.relatedRecordsStatus ==
                  AppointmentRelatedRecordsStatus.loading ||
              (state.relatedRecordsType != type &&
                  state.relatedRecordsStatus !=
                      AppointmentRelatedRecordsStatus.initial)) {
            return _RelatedRecordLoading(label: l.relatedRecord);
          }
          if (state.relatedRecordsStatus ==
              AppointmentRelatedRecordsStatus.failure) {
            return Text(
              localizeErrorMessage(l, state.relatedRecordsMessage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.errorColor(context),
                  ),
            );
          }

          final options = _relatedRecordOptions(
            state.relatedRecordOptions,
            selectedId: value,
            selectedType: type,
            selectedTitle: selectedTitle,
            selectedSubtitle: selectedSubtitle,
          );
          final selectedOption = _relatedRecordSelectionFor(value, options);
          if (state.relatedRecordsStatus ==
                  AppointmentRelatedRecordsStatus.empty &&
              value.trim().isEmpty) {
            return Text(
              _emptyRelatedRecordsLabel(l, type),
              style: Theme.of(context).textTheme.bodySmall,
            );
          }
          return AppDropdown<_RelatedRecordSelection>(
            key: ValueKey('${type.name}-${selectedOption.record?.id ?? ''}'),
            label: l.relatedRecord,
            value: selectedOption,
            items: options,
            itemLabelBuilder: (option) => option.isPlaceholder
                ? l.selectRelatedRecord
                : _relatedRecordLabel(l, option.record),
            enabled: enabled && options.length > 1,
            onChanged: (option) => onChanged(option.record),
          );
        },
      ),
    );
  }
}

class _RelatedRecordLoading extends StatelessWidget {
  const _RelatedRecordLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      child: const SizedBox(
        height: 28,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _RelatedRecordSelection {
  const _RelatedRecordSelection._({
    required this.record,
    required this.isPlaceholder,
  });

  const _RelatedRecordSelection.placeholder()
      : this._(record: null, isPlaceholder: true);

  const _RelatedRecordSelection.value(AppointmentRelatedRecordOption record)
      : this._(record: record, isPlaceholder: false);

  final AppointmentRelatedRecordOption? record;
  final bool isPlaceholder;

  @override
  bool operator ==(Object other) {
    return other is _RelatedRecordSelection &&
        other.isPlaceholder == isPlaceholder &&
        other.record?.id == record?.id;
  }

  @override
  int get hashCode => Object.hash(record?.id, isPlaceholder);
}

List<_RelatedRecordSelection> _relatedRecordOptions(
  List<AppointmentRelatedRecordOption> records, {
  required String selectedId,
  required AppointmentRelatedType selectedType,
  required String selectedTitle,
  required String selectedSubtitle,
}) {
  final sortedRecords = [...records]
    ..sort((a, b) => a.title.compareTo(b.title));
  return [
    const _RelatedRecordSelection.placeholder(),
    for (final record in sortedRecords) _RelatedRecordSelection.value(record),
  ];
}

_RelatedRecordSelection _relatedRecordSelectionFor(
  String selectedId,
  List<_RelatedRecordSelection> options,
) {
  final trimmed = selectedId.trim();
  if (trimmed.isEmpty) {
    return const _RelatedRecordSelection.placeholder();
  }
  for (final option in options) {
    if (option.record?.id == trimmed) {
      return option;
    }
  }
  return const _RelatedRecordSelection.placeholder();
}

class _AppointmentAssigneeOption {
  const _AppointmentAssigneeOption._({
    required this.value,
    required this.isUnassigned,
  });

  const _AppointmentAssigneeOption.unassigned()
      : this._(value: null, isUnassigned: true);

  const _AppointmentAssigneeOption.value(String value)
      : this._(value: value, isUnassigned: false);

  factory _AppointmentAssigneeOption.fromValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty
        ? const _AppointmentAssigneeOption.unassigned()
        : _AppointmentAssigneeOption.value(trimmed);
  }

  final String? value;
  final bool isUnassigned;

  @override
  bool operator ==(Object other) {
    return other is _AppointmentAssigneeOption &&
        other.isUnassigned == isUnassigned &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(value, isUnassigned);
}

List<_AppointmentAssigneeOption> _appointmentAssigneeOptions(
  List<UserProfile> users, {
  String actorUid = '',
  String? managerId,
  String? teamId,
}) {
  final actorId = actorUid.trim();
  final managerScopeId = managerId?.trim() ?? '';
  final managerTeamId = teamId?.trim() ?? '';
  final isManagerScoped = actorId.isNotEmpty &&
      managerScopeId.isNotEmpty &&
      actorId == managerScopeId;
  final assignableUsers = AssignmentUserPolicy.assignableUsersFor(
    AssignableWorkType.appointment,
    users,
  );
  final scopedUsers = isManagerScoped
      ? assignableUsers.where((user) {
          return user.uid == actorId ||
              user.managerId == actorId ||
              (managerTeamId.isNotEmpty && user.teamId == managerTeamId);
        }).toList()
      : assignableUsers;
  return [
    const _AppointmentAssigneeOption.unassigned(),
    for (final user in scopedUsers)
      _AppointmentAssigneeOption.value(user.uid),
  ];
}

String _assigneeLabel(
  AppLocalizations l,
  List<UserProfile> users,
  String? uid,
) {
  final value = uid?.trim() ?? '';
  if (value.isEmpty) {
    return l.unassigned;
  }
  for (final user in users) {
    if (user.uid == value) {
      return user.fullName.trim().isEmpty ? user.email : user.fullName;
    }
  }
  return l.assignedUserUnavailable;
}

String _emptyRelatedRecordsLabel(
  AppLocalizations l,
  AppointmentRelatedType type,
) {
  return switch (type) {
    AppointmentRelatedType.lead => l.noLeadsFound,
    AppointmentRelatedType.client => l.noClientsFound,
    AppointmentRelatedType.property => l.noPropertiesFound,
    AppointmentRelatedType.deal => l.noDealsAvailable,
    AppointmentRelatedType.general => l.noData,
  };
}

String _relatedRecordLabel(
  AppLocalizations l,
  AppointmentRelatedRecordOption? record,
) {
  if (record == null) {
    return l.selectRelatedRecord;
  }
  final title = record.title.trim();
  final subtitle = record.subtitle.trim();
  if (title.isEmpty) {
    return l.relatedRecordUnavailable;
  }
  return subtitle.isEmpty ? title : '$title - $subtitle';
}

String appointmentTypeLabel(AppLocalizations l, AppointmentType type) {
  return switch (type) {
    AppointmentType.call => l.appointmentTypeCall,
    AppointmentType.meeting => l.appointmentTypeMeeting,
    AppointmentType.propertyViewing => l.appointmentTypePropertyViewing,
    AppointmentType.siteVisit => l.appointmentTypeSiteVisit,
    AppointmentType.contractMeeting => l.appointmentTypeContractMeeting,
    AppointmentType.reservationMeeting =>
      l.appointmentTypeReservationMeeting,
    AppointmentType.followUp => l.appointmentTypeFollowUp,
    AppointmentType.other => l.appointmentTypeOther,
  };
}

String appointmentStatusLabel(AppLocalizations l, AppointmentStatus status) {
  return switch (status) {
    AppointmentStatus.scheduled => l.appointmentStatusScheduled,
    AppointmentStatus.completed => l.appointmentStatusCompleted,
    AppointmentStatus.cancelled => l.appointmentStatusCancelled,
    AppointmentStatus.missed => l.appointmentStatusMissed,
    AppointmentStatus.rescheduled => l.appointmentStatusRescheduled,
  };
}

String appointmentOutcomeLabel(AppLocalizations l, AppointmentOutcome outcome) {
  return switch (outcome) {
    AppointmentOutcome.successfulMeeting => l.appointmentOutcomeSuccessfulMeeting,
    AppointmentOutcome.noAnswer => l.appointmentOutcomeNoAnswer,
    AppointmentOutcome.clientPostponed => l.appointmentOutcomeClientPostponed,
    AppointmentOutcome.clientNotInterested =>
      l.appointmentOutcomeClientNotInterested,
    AppointmentOutcome.followUpNeeded => l.appointmentOutcomeFollowUpNeeded,
    AppointmentOutcome.dealOpportunity => l.appointmentOutcomeDealOpportunity,
    AppointmentOutcome.other => l.appointmentOutcomeOther,
  };
}

String appointmentRelatedTypeLabel(
  AppLocalizations l,
  AppointmentRelatedType type,
) {
  return switch (type) {
    AppointmentRelatedType.lead => l.lead,
    AppointmentRelatedType.client => l.client,
    AppointmentRelatedType.property => l.property,
    AppointmentRelatedType.deal => l.deal,
    AppointmentRelatedType.general => l.general,
  };
}
