class DownloadedFileResult {
  const DownloadedFileResult({
    required this.success,
    this.fileName = '',
    this.displayPath = '',
    this.uri = '',
    this.mimeType = '',
  });

  final bool success;
  final String fileName;
  final String displayPath;
  final String uri;
  final String mimeType;

  bool get canOpenFile => uri.trim().isNotEmpty;
}
