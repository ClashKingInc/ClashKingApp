import 'dart:convert';
import 'dart:io';

void main() {
  // Define the paths to your ARB files
  const enPath = 'lib/l10n/app_en.arb';
  const enUsPath = 'lib/l10n/app_en_US.arb';
  const enGbPath = 'lib/l10n/app_en_GB.arb';

  // Load the ARB files
  final enFile = File(enPath);
  final enUsFile = File(enUsPath);
  final enGbFile = File(enGbPath);

  if (!enFile.existsSync()) {
    print('The base en.arb file does not exist. Please check the file path.');
    return;
  }

  // Decode the JSON content of each ARB file
  final enJson = json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final enUsJson = enUsFile.existsSync()
      ? (json.decode(enUsFile.readAsStringSync()) as Map<dynamic, dynamic>).cast<String, dynamic>()
      : <String, dynamic>{};
  final enGbJson = enGbFile.existsSync()
      ? (json.decode(enGbFile.readAsStringSync()) as Map<dynamic, dynamic>).cast<String, dynamic>()
      : <String, dynamic>{};

  // Function to update a specific ARB file
  void updateArbFile(Map<String, dynamic> targetJson, File file) {
    bool updated = false;

    enJson.forEach((key, value) {
      if (!targetJson.containsKey(key)) {
        targetJson[key] = value;
        updated = true;
      }
    });

    if (updated) {
      file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(targetJson));
      print('${file.path} has been updated.');
    } else {
      print('${file.path} is already up-to-date.');
    }
  }

  // Update the en_US and en_GB ARB files
  updateArbFile(enUsJson, enUsFile);
  updateArbFile(enGbJson, enGbFile);
}
