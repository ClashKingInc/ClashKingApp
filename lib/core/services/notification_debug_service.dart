import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationDebugService {
  static const MethodChannel _channel = MethodChannel(
    'clashking/notification_debug',
  );

  static bool get isSupportedPlatform => !kIsWeb && Platform.isIOS;

  Future<Map<String, dynamic>> showSample(NotificationSample sample) async {
    if (!isSupportedPlatform) {
      throw PlatformException(code: 'unsupported', message: null);
    }

    final result = await _channel.invokeMapMethod<String, dynamic>(
      'showSample',
      sample.toPayload(),
    );
    return result ?? <String, dynamic>{};
  }
}

class NotificationSample {
  const NotificationSample({
    required this.id,
    required this.label,
    required this.group,
    required this.title,
    required this.body,
    required this.assetUrl,
  });

  final String id;
  final String label;
  final String group;
  final String title;
  final String body;
  final String assetUrl;

  Map<String, dynamic> toPayload() {
    return {
      'sampleId': id,
      'title': title,
      'body': body,
      'assetUrl': assetUrl,
      'assetUrls': [assetUrl],
      'threadIdentifier': group,
    };
  }
}
