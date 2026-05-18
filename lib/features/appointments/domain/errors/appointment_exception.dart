class AppointmentException implements Exception {
  const AppointmentException(this.message);

  final String message;

  @override
  String toString() => message;
}
