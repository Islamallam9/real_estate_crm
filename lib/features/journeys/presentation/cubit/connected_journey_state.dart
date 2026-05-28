import 'package:equatable/equatable.dart';

import '../../domain/entities/connected_journey.dart';

enum ConnectedJourneyStatus { initial, loading, loaded, failure }

class ConnectedJourneyState extends Equatable {
  const ConnectedJourneyState({
    this.status = ConnectedJourneyStatus.initial,
    this.taskItems = const <JourneyItem>[],
    this.appointmentItems = const <JourneyItem>[],
    this.dealItems = const <JourneyItem>[],
    this.auditItems = const <JourneyItem>[],
    this.message = '',
  });

  final ConnectedJourneyStatus status;
  final List<JourneyItem> taskItems;
  final List<JourneyItem> appointmentItems;
  final List<JourneyItem> dealItems;
  final List<JourneyItem> auditItems;
  final String message;

  List<JourneyItem> get remoteItems => [
        ...taskItems,
        ...appointmentItems,
        ...dealItems,
        ...auditItems,
      ];

  ConnectedJourneyState copyWith({
    ConnectedJourneyStatus? status,
    List<JourneyItem>? taskItems,
    List<JourneyItem>? appointmentItems,
    List<JourneyItem>? dealItems,
    List<JourneyItem>? auditItems,
    String? message,
  }) {
    return ConnectedJourneyState(
      status: status ?? this.status,
      taskItems: taskItems ?? this.taskItems,
      appointmentItems: appointmentItems ?? this.appointmentItems,
      dealItems: dealItems ?? this.dealItems,
      auditItems: auditItems ?? this.auditItems,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        taskItems,
        appointmentItems,
        dealItems,
        auditItems,
        message,
      ];
}
