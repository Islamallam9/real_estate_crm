import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'downloaded_file_result.dart';

const _fileDownloaderChannel = MethodChannel('masarcrm/file_downloader');

Future<DownloadedFileResult> downloadBytesImpl({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  if (!Platform.isAndroid) {
    return const DownloadedFileResult(success: false);
  }

  File? tempFile;
  try {
    tempFile = await _writeTempExportFile(fileName: fileName, bytes: bytes);
    final response = await _fileDownloaderChannel.invokeMethod<Object?>(
      'saveFileToDownloads',
      <String, Object>{
        'fileName': fileName,
        'mimeType': mimeType,
        'sourcePath': tempFile.path,
      },
    );
    return _downloadedFileFromResponse(response, fileName, mimeType);
  } on MissingPluginException {
    // Older installed native shell: keep a compatibility fallback, but the
    // release APK must still be rebuilt for the durable Android saver.
    return _downloadWithLegacyByteChannel(
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
    );
  } on PlatformException {
    return const DownloadedFileResult(success: false);
  } catch (_) {
    return const DownloadedFileResult(success: false);
  } finally {
    try {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {
      // Best-effort cleanup only.
    }
  }
}

Future<DownloadedFileResult> _downloadWithLegacyByteChannel({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  try {
    final response = await _fileDownloaderChannel.invokeMethod<Object?>(
      'saveToDownloads',
      <String, Object>{
        'fileName': fileName,
        'mimeType': mimeType,
        'bytes': bytes,
      },
    );
    return _downloadedFileFromResponse(response, fileName, mimeType);
  } catch (_) {
    return const DownloadedFileResult(success: false);
  }
}

DownloadedFileResult _downloadedFileFromResponse(
  Object? response,
  String fileName,
  String mimeType,
) {
  if (response is Map) {
    final data = Map<String, Object?>.from(response);
    return DownloadedFileResult(
      success: data['success'] == true,
      fileName: data['fileName'] as String? ?? fileName,
      displayPath: data['displayPath'] as String? ?? '',
      uri: data['uri'] as String? ?? '',
      mimeType: data['mimeType'] as String? ?? mimeType,
    );
  }
  return DownloadedFileResult(
    success: response == true,
    fileName: fileName,
    displayPath: 'Downloads / Masar CRM / $fileName',
    mimeType: mimeType,
  );
}

Future<File> _writeTempExportFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  final safeName = fileName
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final tempName = '${suffix}_${safeName.isEmpty ? 'masar-export.xlsx' : safeName}';
  final tempFile = File('${Directory.systemTemp.path}/$tempName');
  await tempFile.writeAsBytes(bytes, flush: true);
  return tempFile;
}

Future<bool> openDownloadedFileImpl(DownloadedFileResult file) async {
  if (!Platform.isAndroid || file.uri.trim().isEmpty) {
    return false;
  }
  try {
    return await _fileDownloaderChannel.invokeMethod<bool>(
          'openDownloadedFile',
          <String, Object>{
            'uri': file.uri,
            'mimeType': file.mimeType,
          },
        ) ??
        false;
  } on PlatformException {
    return false;
  } catch (_) {
    return false;
  }
}

Future<bool> openDownloadsLocationImpl([DownloadedFileResult? file]) async {
  if (!Platform.isAndroid) {
    return false;
  }
  try {
    final args = file == null
        ? null
        : <String, Object>{
            'uri': file.uri,
            'mimeType': file.mimeType,
            'displayPath': file.displayPath,
          };
    return await _fileDownloaderChannel.invokeMethod<bool>(
          'openDownloadsLocation',
          args,
        ) ??
        false;
  } on PlatformException {
    return false;
  } catch (_) {
    return false;
  }
}
