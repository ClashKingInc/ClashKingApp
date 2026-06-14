import 'package:open_filex/open_filex.dart';

Future<void> openLocalFile(String filePath) async {
  await OpenFilex.open(filePath);
}
