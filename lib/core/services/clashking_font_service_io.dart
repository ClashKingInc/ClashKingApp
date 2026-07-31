import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ClashKingFontService {
  static const _fontFamily = 'ClashKing';
  static const _cacheLifetime = Duration(days: 7);
  static const _cacheFileName = 'clashking.ttf';
  static final _fontUri = Uri.parse(
    'https://assets.clashk.ing/fonts/clashking.ttf',
  );
  static Future<void>? _load;

  static Future<void> load() => _load ??= _loadOnce();

  static Future<void> _loadOnce() async {
    try {
      final cacheFile = await _cacheFile();
      if (await cacheFile.exists()) {
        await _register(await cacheFile.readAsBytes());
        if (await _isStale(cacheFile)) {
          unawaited(_refresh(cacheFile));
        }
        return;
      }

      final bytes = await _download();
      await _writeAtomically(cacheFile, bytes);
      await _register(bytes);
    } catch (error) {
      debugPrint('ClashKing font load failed; using system fallback: $error');
    }
  }

  static Future<File> _cacheFile() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/fonts');
    await directory.create(recursive: true);
    return File('${directory.path}/$_cacheFileName');
  }

  static Future<bool> _isStale(File file) async {
    final modified = await file.lastModified();
    return DateTime.now().difference(modified) >= _cacheLifetime;
  }

  static Future<void> _refresh(File cacheFile) async {
    try {
      await _writeAtomically(cacheFile, await _download());
    } catch (error) {
      debugPrint('ClashKing font cache refresh failed: $error');
    }
  }

  static Future<Uint8List> _download() async {
    final response = await http
        .get(_fontUri, headers: const {'User-Agent': 'ClashKing-App/1.0'})
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw StateError('HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  static Future<void> _writeAtomically(File cacheFile, Uint8List bytes) async {
    final pending = File('${cacheFile.path}.pending');
    await pending.writeAsBytes(bytes, flush: true);
    if (await cacheFile.exists()) {
      await cacheFile.delete();
    }
    await pending.rename(cacheFile.path);
  }

  static Future<void> _register(Uint8List bytes) async {
    final loader = FontLoader(_fontFamily)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
