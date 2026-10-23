import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const packageRoot = path.join(root, 'node_modules/react-native-draggable-flatlist');
const version = JSON.parse(fs.readFileSync(path.join(packageRoot, 'package.json'), 'utf8')).version;
if (version !== '4.0.3') throw new Error(`Review draggable-flatlist SDK 58 compatibility for ${version}`);

// This release still imports RN's removed InteractionManager. Keep the patch
// version-scoped and reproducible after npm ci. The legacy RNGH list preserves
// the gesture relationships used by its legacy Gesture.Pan implementation.
for (const relative of [
  'src/components/DraggableFlatList.tsx',
  'lib/module/components/DraggableFlatList.js',
  'lib/commonjs/components/DraggableFlatList.js',
]) {
  const file = path.join(packageRoot, relative);
  let source = fs.readFileSync(file, 'utf8');
  source = source
    .replace(/import \{ InteractionManager \} from "react-native";\n/g, '')
    .replace(/  InteractionManager,\n/g, '')
    .replaceAll('_reactNative.InteractionManager.runAfterInteractions(', 'requestIdleCallback(')
    .replaceAll('InteractionManager.runAfterInteractions(', 'requestIdleCallback(')
    .replaceAll('_reactNativeGestureHandler.FlatList', '_reactNativeGestureHandler.LegacyFlatList')
    .replace('import { FlatList, Gesture, GestureDetector }', 'import { LegacyFlatList as FlatList, Gesture, GestureDetector }')
    .replace(/import \{\n  FlatList,\n  Gesture,/, 'import {\n  LegacyFlatList as FlatList,\n  Gesture,');
  if (source.includes('InteractionManager')) throw new Error(`Unpatched InteractionManager in ${relative}`);
  fs.writeFileSync(file, source);
}
console.log('Applied draggable-flatlist 4.0.3 compatibility for RN 0.88.');
