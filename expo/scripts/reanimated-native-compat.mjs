import fs from 'node:fs';
import path from 'node:path';
import { parse } from '@babel/parser';
import traverseModule from '@babel/traverse';

const traverse = traverseModule.default;
const dependencyIndex = {
  useAnimatedStyle: 1,
  useAnimatedProps: 1,
  useDerivedValue: 1,
  useAnimatedReaction: 2,
  useAnimatedScrollHandler: 1,
};

// Reanimated 4.7 ignores dependency arrays on native and warns in development.
// Match imported hooks with the parser so multiline callbacks, nested arrays and
// TypeScript generics are preserved. Keep dependencies for shared web sources.
export function patchReanimatedDependencies(source, nativeOnly) {
  const ast = parse(source, { sourceType: 'module', plugins: ['typescript', 'jsx'] });
  const edits = [];
  traverse(ast, {
    CallExpression({ node, scope }) {
      if (node.callee.type !== 'Identifier') return;
      const binding = scope.getBinding(node.callee.name);
      if (
        !binding?.path.isImportSpecifier() ||
        binding.path.parent.source.value !== 'react-native-reanimated'
      )
        return;
      const index = dependencyIndex[binding.path.node.imported.name];
      const dependencies = node.arguments[index];
      if (index === undefined || !dependencies || dependencies.type !== 'ArrayExpression') return;
      edits.push({
        start: dependencies.start,
        end: dependencies.end,
        text: nativeOnly
          ? 'undefined'
          : `CKReanimatedPlatform.OS === 'web' ? ${source.slice(dependencies.start, dependencies.end)} : undefined`,
      });
    },
  });
  for (const edit of edits.sort((a, b) => b.start - a.start)) {
    source = source.slice(0, edit.start) + edit.text + source.slice(edit.end);
  }
  if (edits.length && !nativeOnly) {
    source = `import { Platform as CKReanimatedPlatform } from 'react-native';\n${source}`;
  }
  return source;
}

export function applyReanimatedNativeCompat(root) {
  for (const [name, version, directories, nativeOnly] of [
    ['react-native-drawer-layout', '4.2.12', ['src', 'lib/module'], true],
    ['react-native-draggable-flatlist', '4.0.3', ['src'], false],
  ]) {
    const packageRoot = path.join(root, 'node_modules', name);
    const installed = JSON.parse(fs.readFileSync(path.join(packageRoot, 'package.json'), 'utf8'));
    if (installed.version !== version) {
      throw new Error(`Review ${name} Reanimated native compatibility for ${installed.version}`);
    }
    for (const directory of directories) {
      for (const entry of fs.readdirSync(path.join(packageRoot, directory), { recursive: true })) {
        if (!/\.[jt]sx?$/.test(entry) || (nativeOnly && !/\.native\.[jt]sx?$/.test(entry)))
          continue;
        const file = path.join(packageRoot, directory, entry);
        const source = fs.readFileSync(file, 'utf8');
        const patched = patchReanimatedDependencies(source, nativeOnly);
        if (patched !== source) fs.writeFileSync(file, patched);
      }
    }
  }
}
