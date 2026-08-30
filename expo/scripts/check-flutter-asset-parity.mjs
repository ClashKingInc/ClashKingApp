import { readdirSync, readFileSync } from 'node:fs';
import { basename, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const expoRoot = resolve(scriptDirectory, '..');

compareDirectory('../assets/icons', 'assets/clashking/icons', new Set(['ic_stat_clashking.png']));
compareDirectory('../fonts', 'assets/clashking/fonts');
compareDirectory('../web/icons', 'public/icons');
compareFile(
  '../android/app/src/main/res/drawable-xxxhdpi/ic_stat_clashking.png',
  'assets/clashking/icons/ic_stat_clashking.png',
);

function compareDirectory(sourceRelative, targetRelative, permittedTargetExtras = new Set()) {
  const sourceRoot = resolve(expoRoot, sourceRelative);
  const targetRoot = resolve(expoRoot, targetRelative);
  const sourceFiles = files(sourceRoot);
  const targetFiles = files(targetRoot).filter((file) => !permittedTargetExtras.has(file));
  assertEqual(`${sourceRelative} file names`, sourceFiles, targetFiles);
  for (const file of sourceFiles) {
    compareFile(resolve(sourceRoot, file), resolve(targetRoot, file));
  }
}

function compareFile(sourcePath, targetPath) {
  const source = resolve(expoRoot, sourcePath);
  const target = resolve(expoRoot, targetPath);
  if (!readFileSync(source).equals(readFileSync(target))) {
    throw new Error(`${basename(target)} differs from ${source}.`);
  }
}

function files(root) {
  return readdirSync(root, { withFileTypes: true })
    .filter((entry) => entry.isFile())
    .map((entry) => entry.name)
    .sort((left, right) => left.localeCompare(right));
}

function assertEqual(label, expected, actual) {
  if (JSON.stringify(expected) !== JSON.stringify(actual)) {
    throw new Error(
      `${label} differ. Expected ${JSON.stringify(expected)}, received ${JSON.stringify(actual)}.`,
    );
  }
}
