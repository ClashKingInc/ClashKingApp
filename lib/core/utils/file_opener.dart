import 'package:url_launcher/url_launcher.dart';

Future<void> openLocalFile(String filePath) async {
  final uri = Uri.file(filePath);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
