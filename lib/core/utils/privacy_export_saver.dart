import 'privacy_export_saver_io.dart'
    if (dart.library.html) 'privacy_export_saver_web.dart';

Future<void> savePrivacyExport({
  required String fileName,
  required String data,
}) {
  return savePrivacyExportFile(fileName: fileName, data: data);
}
