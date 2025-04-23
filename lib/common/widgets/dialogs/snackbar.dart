import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<void> showClipboardSnackbar(BuildContext context, String message) async {
  if (!context.mounted) return;

  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      // Android 13 (API level 33) and above already display a snackbar when copying to clipboard
      return;
    }
  }

  if (!context.mounted) return;
  final snackBar = SnackBar(
    content: Center(
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    ),
    duration: const Duration(milliseconds: 1500),
    backgroundColor: Theme.of(context).colorScheme.surface,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
