import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import ts from 'typescript';

const expoRoot = path.resolve(import.meta.dirname, '..');
const e2eRoot = path.resolve(expoRoot, '../e2e');
const sourceRoot = path.join(e2eRoot, 'tests');

const forbiddenPatterns = [
  [/\bFlutter\b/g, 'Flutter runtime reference'],
  [/\bCanvasKit\b/g, 'CanvasKit runtime reference'],
  [/flt-/g, 'Flutter renderer selector'],
  [/flutter\.access_token/g, 'Flutter-only storage key'],
  [/\bMyHomePage\b/g, 'Flutter widget name'],
  [/\bAddCocAccountPage\b/g, 'Flutter widget name'],
  [/\bCustomAppBar\b/g, 'Flutter widget name'],
  [/\bSettingsInfoScreen\b/g, 'Flutter widget name'],
  [/\bSemantics\(/g, 'Flutter semantics reference'],
  [/War\/League/g, 'stale Flutter navigation label'],
  [/getByText\(['"]Dashboard['"]/g, 'stale Flutter navigation label'],
];

const sourceFiles = fs
  .readdirSync(sourceRoot)
  .filter((file) => file.endsWith('.ts'))
  .sort();

const failures = [];
for (const file of sourceFiles) {
  const absolutePath = path.join(sourceRoot, file);
  const source = fs.readFileSync(absolutePath, 'utf8');

  for (const [pattern, description] of forbiddenPatterns) {
    if (pattern.test(source)) failures.push(`${file}: ${description}`);
    pattern.lastIndex = 0;
  }

  const result = ts.transpileModule(source, {
    fileName: absolutePath,
    reportDiagnostics: true,
    compilerOptions: {
      module: ts.ModuleKind.ESNext,
      target: ts.ScriptTarget.ES2022,
    },
  });

  for (const diagnostic of result.diagnostics ?? []) {
    if (diagnostic.category !== ts.DiagnosticCategory.Error) continue;
    const message = ts.flattenDiagnosticMessageText(diagnostic.messageText, '\n');
    failures.push(`${file}: ${message}`);
  }
}

if (failures.length > 0) {
  console.error(`Expo E2E structure check failed:\n${failures.join('\n')}`);
  process.exit(1);
}

console.log(`Expo E2E structure check passed (${sourceFiles.length} TypeScript files).`);
