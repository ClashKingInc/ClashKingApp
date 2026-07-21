import 'dart:typed_data';

import 'package:clashkingapp/features/game_assets/data/game_asset_actions.dart';
import 'package:clashkingapp/features/game_assets/models/game_asset_manifest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('save downloads bytes and preserves the hosted filename', () async {
    String? savedName;
    Uint8List? savedBytes;
    final actions = PlatformGameAssetActions(
      client: MockClient((request) async {
        expect(request.url, _asset.url);
        return http.Response.bytes([1, 2, 3], 200);
      }),
      saveBytes: ({required fileName, required bytes}) async {
        savedName = fileName;
        savedBytes = bytes;
        return '/downloads/$fileName';
      },
    );

    final path = await actions.save(_asset);

    expect(savedName, 'archer queen.webp');
    expect(savedBytes, [1, 2, 3]);
    expect(path, '/downloads/archer queen.webp');
  });

  test('save rejects failed asset responses', () {
    final actions = PlatformGameAssetActions(
      client: MockClient((_) async => http.Response('not found', 404)),
    );

    expect(actions.save(_asset), throwsA(isA<GameAssetActionException>()));
  });
}

final _asset = GameAsset(
  path: 'skins/archer queen.webp',
  category: 'skins',
  displayName: 'Archer Queen',
  extension: 'webp',
  url: Uri.parse('https://assets.clashk.ing/skins/archer%20queen.webp'),
);
