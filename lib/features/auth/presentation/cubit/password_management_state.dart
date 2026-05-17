import 'package:equatable/equatable.dart';

enum PasswordManagementStatus { initial, saving, success, failure }

class PasswordManagementState extends Equatable {
  const PasswordManagementState({
    this.status = PasswordManagementStatus.initial,
    this.message,
  });

  final PasswordManagementStatus status;
  final String? message;

  PasswordManagementState copyWith({
    PasswordManagementStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return PasswordManagementState(
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, message];
}
