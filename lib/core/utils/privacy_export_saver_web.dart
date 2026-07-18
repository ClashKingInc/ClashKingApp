import 'package:universal_html/html.dart' as html;

Future<void> savePrivacyExportFile({
  required String fileName,
  required String data,
}) async {
  final blob = html.Blob([data], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
