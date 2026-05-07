class ClientException implements Exception {
  const ClientException(this.message);

  final String message;

  @override
  String toString() => message;
}
