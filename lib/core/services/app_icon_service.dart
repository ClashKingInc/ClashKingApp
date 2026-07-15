import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppIconService {
  static const MethodChannel _channel = MethodChannel('clashking/app_icon');

  static const String christmasIconName = 'AppIconChristmas';
  static const String blackWhiteIconName = 'AppIconBlackWhite';
  static const String darkLogoIconName = 'AppIconDarkLogo';

  static const List<AppIconOption> options = [
    AppIconOption(
      labelKey: 'default',
      iconName: null,
      previewAsset: 'assets/icons/app_icon_ios_default.png',
    ),
    AppIconOption(
      labelKey: 'christmas',
      iconName: christmasIconName,
      previewAsset: 'assets/icons/app_icon_christmas.png',
    ),
    AppIconOption(
      labelKey: 'black_white',
      iconName: blackWhiteIconName,
      previewAsset: 'assets/icons/app_icon_black_white.png',
    ),
    AppIconOption(
      labelKey: 'dark_mode',
      iconName: darkLogoIconName,
      previewAsset: 'assets/icons/app_icon_dark_logo.png',
    ),
  ];

  static bool get isSupportedPlatform => !kIsWeb && Platform.isIOS;

  Future<bool> supportsAlternateIcons() async {
    if (!isSupportedPlatform) return false;

    try {
      return await _channel.invokeMethod<bool>('supportsAlternateIcons') ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String?> getAlternateIconName() async {
    if (!isSupportedPlatform) return null;

    try {
      return await _channel.invokeMethod<String>('getAlternateIconName');
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> setAlternateIconName(String? iconName) async {
    if (!isSupportedPlatform) {
      throw PlatformException(code: 'unsupported', message: null);
    }

    await _channel.invokeMethod<void>('setAlternateIconName', iconName);
  }

  AppIconOption optionForName(String? iconName) {
    return options.firstWhere(
      (option) => option.iconName == iconName,
      orElse: () => options.first,
    );
  }
}

class AppIconOption {
  const AppIconOption({
    required this.labelKey,
    required this.iconName,
    required this.previewAsset,
  });

  final String labelKey;
  final String? iconName;
  final String previewAsset;
}
