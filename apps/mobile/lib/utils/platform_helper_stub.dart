// Stub for non-web platforms (Android, iOS, Windows, etc.)
// These functions show "not available" messages on non-web platforms.

import 'dart:typed_data';

void webPickFile({
  required String accept,
  required void Function(String fileName, Uint8List bytes) onPicked,
  void Function(String dataUrl)? onPickedDataUrl,
}) {
  // Not available on non-web platforms
}

void webDownloadFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) {
  // Not available on non-web platforms
}
