import 'package:equatable/equatable.dart';

import '../../domain/entities/lead.dart';

enum LeadsStatus { initial, loading, loaded, saving, saved, empty, failure }

class LeadsState extends Equatable {
  const LeadsState({
    required this.status,
    this.leads = const [],
    this.selectedLead,
    this.message,
  });

  const LeadsState.initial()
    : status = LeadsStatus.initial,
      leads = const [],
      selectedLead = null,
      message = null;

  final LeadsStatus status;
  final List<Lead> leads;
  final Lead? selectedLead;
  final String? message;

  LeadsState copyWith({
    LeadsStatus? status,
    List<Lead>? leads,
    Lead? selectedLead,
    String? message,
    bool clearSelectedLead = false,
    bool clearMessage = false,
  }) {
    return LeadsState(
      status: status ?? this.status,
      leads: leads ?? this.leads,
      selectedLead: clearSelectedLead
          ? null
          : selectedLead ?? this.selectedLead,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, leads, selectedLead, message];
}
