import 'package:flutter_file_saver/flutter_file_saver.dart';

Future<void> savePrivacyExportFile({
  required String fileName,
  required String data,
}) {
  return FlutterFileSaver().writeFileAsString(fileName: fileName, data: data);
}
