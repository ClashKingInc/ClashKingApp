import 'package:clashkingapp/features/game_assets/models/game_asset_manifest.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

abstract interface class GameAssetActions {
  Future<void> copy(String value);

  Future<void> share(GameAsset asset, {Rect? origin});

  Future<String> save(GameAsset asset);
}

typedef GameAssetBytesSaver =
    Future<String> Function({
      required String fileName,
      required Uint8List bytes,
    });

class PlatformGameAssetActions implements GameAssetActions {
  PlatformGameAssetActions({
    http.Client? client,
    GameAssetBytesSaver? saveBytes,
    this.requestTimeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _saveBytes = saveBytes ?? _saveGameAssetBytes;

  static final PlatformGameAssetActions shared = PlatformGameAssetActions();

  final http.Client _client;
  final GameAssetBytesSaver _saveBytes;
  final Duration requestTimeout;

  @override
  Future<void> copy(String value) {
    return Clipboard.setData(ClipboardData(text: value));
  }

  @override
  Future<void> share(GameAsset asset, {Rect? origin}) async {
    await SharePlus.instance.share(
      ShareParams(
        uri: asset.url,
        subject: asset.displayName,
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Future<String> save(GameAsset asset) async {
    final response = await _client.get(asset.url).timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GameAssetActionException(
        'Asset download failed (${response.statusCode})',
      );
    }
    return _saveBytes(fileName: asset.fileName, bytes: response.bodyBytes);
  }
}

Future<String> _saveGameAssetBytes({
  required String fileName,
  required Uint8List bytes,
}) {
  return FlutterFileSaver().writeFileAsBytes(fileName: fileName, bytes: bytes);
}

class GameAssetActionException implements Exception {
  const GameAssetActionException(this.message);

  final String message;

  @override
  String toString() => message;
}
