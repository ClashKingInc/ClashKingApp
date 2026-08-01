import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ClashKingFontService {
  static const _fontFamily = 'ClashKing';
  static final _fontUri = Uri.parse(
    'https://assets.clashk.ing/fonts/clashking.ttf',
  );
  static Future<void>? _load;

  static Future<void> load() => _load ??= _loadOnce();

  static Future<void> _loadOnce() async {
    try {
      final response = await http
          .get(_fontUri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw StateError('HTTP ${response.statusCode}');
      }
      await _register(response.bodyBytes);
    } catch (error) {
      debugPrint(
        'ClashKing font download failed; using system fallback: $error',
      );
    }
  }

  static Future<void> _register(Uint8List bytes) async {
    final loader = FontLoader(_fontFamily)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
