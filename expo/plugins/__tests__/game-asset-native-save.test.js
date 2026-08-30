'use strict';

/* global __dirname */

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const expoRoot = path.resolve(__dirname, '../..');

test('Game Assets retains Flutter native save-picker semantics', () => {
  const android = fs.readFileSync(
    path.join(
      expoRoot,
      'modules/clashking-native/android/src/main/java/com/clashking/nativebridge/ClashKingNativeModule.kt',
    ),
    'utf8',
  );
  assert.match(android, /Intent\(Intent\.ACTION_CREATE_DOCUMENT\)/);
  assert.match(android, /putExtra\(Intent\.EXTRA_TITLE, input\.fileName\)/);
  assert.match(android, /source\.inputStream\(\).*inputStream\.copyTo\(output\)/s);
  assert.match(android, /Uri\.parse\(destination\)\.path \?: destination/);
  assert.match(android, /check\(result is FileSaveResult\.Saved\) \{ "CANCELLED" \}/);

  const ios = fs.readFileSync(
    path.join(expoRoot, 'modules/clashking-native/ios/ClashKingNativeModule.swift'),
    'utf8',
  );
  assert.match(ios, /UIDocumentPickerViewController\(forExporting: \[sourceURL\], asCopy: true\)/);
  assert.match(ios, /func documentPickerWasCancelled/);
  assert.match(ios, /context\.promise\.reject\(NativeParityError\.fileSaveCancelled\)/);

  const contract = fs.readFileSync(
    path.join(expoRoot, 'modules/clashking-native/index.ts'),
    'utf8',
  );
  assert.match(contract, /saveFile\(options: SaveFileOptions\): Promise<string>/);
});
