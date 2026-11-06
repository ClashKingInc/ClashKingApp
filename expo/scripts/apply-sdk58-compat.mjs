import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const packageRoot = path.join(root, 'node_modules/react-native-draggable-flatlist');
const version = JSON.parse(fs.readFileSync(path.join(packageRoot, 'package.json'), 'utf8')).version;
if (version !== '4.0.3')
  throw new Error(`Review draggable-flatlist SDK 58 compatibility for ${version}`);

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
    .replace(
      'import { FlatList, Gesture, GestureDetector }',
      'import { LegacyFlatList as FlatList, Gesture, GestureDetector }',
    )
    .replace(
      /import \{\n  FlatList,\n  Gesture,/,
      'import {\n  LegacyFlatList as FlatList,\n  Gesture,',
    );
  if (source.includes('InteractionManager'))
    throw new Error(`Unpatched InteractionManager in ${relative}`);
  fs.writeFileSync(file, source);
}
console.log('Applied draggable-flatlist 4.0.3 compatibility for RN 0.88.');

// Home opts into manual activation on Android. With interruption disabled on
// the nested native list, an ordinary 8px scroll otherwise activates the drag
// recognizer before any card is held and cancels vertical/horizontal scrolling.
// Keep this source-entry patch reproducible; Metro uses the package's
// react-native entry, and other lists retain their existing gesture behavior.
const dragSource = path.join(packageRoot, 'src/components/DraggableFlatList.tsx');
let drag = fs.readFileSync(dragSource, 'utf8');
if (!drag.includes('// CK Android hold gate')) {
  const anchor = '  const panGesture = Gesture.Pan()';
  if (!drag.includes(anchor)) throw new Error('Missing draggable-flatlist gesture patch anchor');
  drag = drag.replace(
    anchor,
    `  // CK Android hold gate
  const holdOriginX = useSharedValue(0);
  const holdOriginY = useSharedValue(0);
  const panGesture = Gesture.Pan()
    .manualActivation(props.androidHoldToDrag === true)
    .onTouchesMove((event, manager) => {
      if (!props.androidHoldToDrag) return;
      if (activeIndexAnim.value >= 0) {
        manager.activate();
        return;
      }
      const touch = event.allTouches[0];
      if (touch && (Math.abs(touch.absoluteX - holdOriginX.value) > 8 ||
        Math.abs(touch.absoluteY - holdOriginY.value) > 8)) manager.fail();
    })
    .onFinalize((_event, success) => {
      if (!props.androidHoldToDrag || success) return;
      isTouchActiveNative.value = false;
      runOnJS(onContainerTouchEnd)();
      if (activeIndexAnim.value >= 0) {
        runOnJS(onRelease)(activeIndexAnim.value);
        runOnJS(onDragEnd)({ from: activeIndexAnim.value, to: spacerIndexAnim.value });
      }
    })`,
  );
  drag = drag.replace(
    '.onTouchesDown(() => {',
    `.onTouchesDown((event) => {
      const touch = event.allTouches[0];
      if (touch) {
        holdOriginX.value = touch.absoluteX;
        holdOriginY.value = touch.absoluteY;
      }`,
  );
  fs.writeFileSync(dragSource, drag);
}
for (const relative of ['src/types.ts', 'lib/typescript/types.d.ts']) {
  const file = path.join(packageRoot, relative);
  const source = fs.readFileSync(file, 'utf8');
  if (!source.includes('androidHoldToDrag?: boolean;')) {
    if (!source.includes('activationDistance?: number;'))
      throw new Error(`Missing drag type anchor: ${relative}`);
    fs.writeFileSync(
      file,
      source.replace(
        'activationDistance?: number;',
        'activationDistance?: number;\n    androidHoldToDrag?: boolean;',
      ),
    );
  }
}

// A held card may be released before the manual pan ever becomes ACTIVE.
// Explicitly clear that pickup; waiting for Pan.onEnd would leave activeKey
// set and the list's scrollEnabled false for all subsequent touches.
let releaseSource = fs.readFileSync(dragSource, 'utf8');
if (!releaseSource.includes('// CK release unactivated pickup')) {
  const anchor = '  const onContainerTouchEnd = () => {\n    isTouchActiveNative.value = false;';
  if (!releaseSource.includes(anchor)) throw new Error('Missing draggable release patch anchor');
  releaseSource = releaseSource.replace(
    anchor,
    `${anchor}
    // CK release unactivated pickup
    if (props.androidHoldToDrag && activeIndexAnim.value >= 0 && !disabled.value) {
      const index = activeIndexAnim.value;
      onRelease(index);
      onDragEnd({ from: index, to: index });
      reset();
    }`,
  );
  fs.writeFileSync(dragSource, releaseSource);
}

// Worklets must capture the boolean, never the React props object (which also
// contains elements/Fiber owners that cannot be copied to the UI runtime).
let workletSource = fs.readFileSync(dragSource, 'utf8');
const booleanCapture = '  const androidHoldToDrag = props.androidHoldToDrag === true;';
if (!workletSource.includes(booleanCapture)) {
  workletSource = workletSource.replaceAll('props.androidHoldToDrag', 'androidHoldToDrag');
  workletSource = workletSource.replace(
    '  const gestureDisabled = useSharedValue(false);',
    `${booleanCapture}\n  const gestureDisabled = useSharedValue(false);`,
  );
  fs.writeFileSync(dragSource, workletSource);
}

// Fabric may omit onLayout when equal-size keyed cells swap positions. Refresh
// cached measurements after release/index changes for the next drag. Transform
// cleanup belongs to the synchronous layout handoff below, not this callback.
const cellSource = path.join(packageRoot, 'src/components/CellRendererComponent.tsx');
let cell = fs.readFileSync(cellSource, 'utf8');
if (!cell.includes('// CK Fabric settled-cell measurement')) {
  const measurement = '      size.value = cellSize;\n      offset.value = cellOffset;';
  const effect = `  useEffect(() => {
    if (isWeb) {
      // onLayout isn't called on web when the cell index changes, so we manually re-measure
      requestAnimationFrame(() => {
        onCellLayout();
      });
    }
  }, [index, onCellLayout]);`;
  if (!cell.includes(measurement) || !cell.includes(effect))
    throw new Error('Missing Fabric cell measurement patch anchor');
  cell = cell
    .replace(
      measurement,
      `      // CK Fabric settled-cell measurement
      runOnUI((nextSize: number, nextOffset: number) => {
        "worklet";
        size.value = nextSize;
        offset.value = nextOffset;
      })(cellSize, cellOffset);`,
    )
    .replace(
      '    heldTanslate.value = 0;\n    updateCellMeasurements();',
      '    updateCellMeasurements();',
    )
    .replace(
      effect,
      `  useEffect(() => {
    // Refresh cached offsets for the next pickup even when Fabric skips onLayout.
    if (!isWeb && activeKey) return;
    const frame = requestAnimationFrame(() => onCellLayout());
    return () => cancelAnimationFrame(frame);
  }, [index, activeKey, onCellLayout]);`,
    );
  fs.writeFileSync(cellSource, cell);
}

// Fabric commits a reordered cell's layout before an asynchronous worklet can
// discard its previous drag transform. Holding that transform (or clearing it
// later in an idle callback) briefly applies the movement twice. Gate it on the
// UI runtime synchronously from the layout effect, so release and layout share
// the commit. Keep every list/cell mounted to preserve scroll and child state.
cell = fs.readFileSync(cellSource, 'utf8');
if (!cell.includes('// CK Fabric synchronous transform handoff')) {
  const start = cell.indexOf('  const animStyle = useAnimatedStyle(');
  const end = cell.indexOf('\n  const updateCellMeasurements', start);
  if (start < 0 || end < 0) throw new Error('Missing Fabric transform patch anchor');
  cell = cell.slice(0, start) + `  // CK Fabric synchronous transform handoff
  const dragging = useSharedValue(false);
  useLayoutEffect(() => {
    executeOnUIRuntimeSync((value: boolean) => {
      "worklet";
      dragging.value = value;
    })(activeKey !== null);
  }, [activeKey, dragging]);
  const animStyle = useAnimatedStyle(() => ({
    transform: [horizontalAnim.value
      ? { translateX: dragging.value ? translate.value : 0 }
      : { translateY: dragging.value ? translate.value : 0 }],
  }));
` + cell.slice(end);
  cell = cell
    .replace('useEffect, useMemo', 'useEffect, useLayoutEffect, useMemo')
    .replace('  const heldTanslate = useSharedValue(0);\n', '')
    .replace('        heldTanslate.value = 0;\n', '')
    .replace('    // Releasing in the original slot needs this too: the final hover offset can\n    // be zero without ever replacing the last nonzero held translation.',
      '    // Refresh cached offsets for the next pickup even when Fabric skips onLayout.');
  if (!cell.includes('  executeOnUIRuntimeSync,'))
    cell = cell.replace('  runOnUI,', '  runOnUI,\n  executeOnUIRuntimeSync,');
  fs.writeFileSync(cellSource, cell);
}
