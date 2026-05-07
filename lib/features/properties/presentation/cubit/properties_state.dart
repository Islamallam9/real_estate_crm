import 'package:equatable/equatable.dart';

import '../../domain/entities/property.dart';

enum PropertiesStatus { initial, loading, loaded, saving, saved, empty, failure }

enum PropertiesAction { none, createProperty, updateProperty }

class PropertiesState extends Equatable {
  const PropertiesState({
    required this.status,
    this.properties = const [],
    this.message,
    this.lastAction = PropertiesAction.none,
  });

  const PropertiesState.initial()
    : status = PropertiesStatus.initial,
      properties = const [],
      message = null,
      lastAction = PropertiesAction.none;

  final PropertiesStatus status;
  final List<Property> properties;
  final String? message;
  final PropertiesAction lastAction;

  PropertiesState copyWith({
    PropertiesStatus? status,
    List<Property>? properties,
    String? message,
    PropertiesAction? lastAction,
    bool clearMessage = false,
    bool clearLastAction = false,
  }) {
    return PropertiesState(
      status: status ?? this.status,
      properties: properties ?? this.properties,
      message: clearMessage ? null : message ?? this.message,
      lastAction: clearLastAction
          ? PropertiesAction.none
          : lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [status, properties, message, lastAction];
}
