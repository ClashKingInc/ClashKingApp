import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import ts from 'typescript';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
// Generate the landing's tiny modules from the native app's authoritative
// parser. No React, Expo, API client or account state enters the public site.
export async function prepareAppLanding() {
  const directory = join(root, 'public', 'landing');
  await mkdir(directory, { recursive: true });
  for (const [source, target] of [
    ['src/navigation/route-manifest.ts', 'route-manifest.js'],
    ['src/core/deep-links/app-link.ts', 'app-link.js'],
  ]) {
    const input = await readFile(join(root, source), 'utf8');
    const output = ts.transpileModule(input, {
      compilerOptions: { target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.ES2022 },
    }).outputText;
    await writeFile(
      join(directory, target),
      '// Generated from ' +
        source +
        '. Do not edit.\n' +
        output.replace("'../../navigation/route-manifest'", "'./route-manifest.js'"),
    );
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url))
  await prepareAppLanding();
