// Web-specific platform helpers using dart:html
import 'dart:typed_data';
import 'dart:html' as html;

void webPickFile({
  required String accept,
  required void Function(String fileName, Uint8List bytes) onPicked,
  void Function(String dataUrl)? onPickedDataUrl,
}) {
  final input = html.FileUploadInputElement()..accept = accept;
  input.click();
  input.onChange.listen((_) {
    final file = input.files?.first;
    if (file == null) return;

    if (onPickedDataUrl != null) {
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((_) {
        onPickedDataUrl(reader.result as String);
      });
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((_) {
      final bytes = Uint8List.fromList(reader.result as List<int>);
      onPicked(file.name, bytes);
    });
  });
}

void webDownloadFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
