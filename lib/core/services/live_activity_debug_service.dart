import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LiveActivityDebugService {
  static const MethodChannel _channel = MethodChannel(
    'clashking/live_activity_debug',
  );

  static bool get isSupportedPlatform => !kIsWeb && Platform.isIOS;

  Future<Map<String, dynamic>> start() => _invoke('start');

  Future<Map<String, dynamic>> update() => _invoke('update');

  Future<Map<String, dynamic>> end() => _invoke('end');

  Future<Map<String, dynamic>> status() => _invoke('status');

  Future<Map<String, dynamic>> _invoke(String method) async {
    if (!isSupportedPlatform) {
      throw PlatformException(
        code: 'unsupported',
        message: 'Live Activities are only available on iOS.',
      );
    }

    final result = await _channel.invokeMapMethod<String, dynamic>(method);
    return result ?? <String, dynamic>{};
  }
}
