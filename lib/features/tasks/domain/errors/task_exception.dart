class TaskException implements Exception {
  const TaskException(this.message);

  final String message;

  @override
  String toString() => message;
}
