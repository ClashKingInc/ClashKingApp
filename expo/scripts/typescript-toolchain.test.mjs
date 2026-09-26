import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { test } from 'node:test';

const require = createRequire(import.meta.url);
const expoRoot = path.resolve(import.meta.dirname, '..');
const manifest = JSON.parse(readFileSync(path.join(expoRoot, 'package.json'), 'utf8'));

test('keeps TypeScript 6 compiler APIs available for Expo and lint tooling', () => {
  const compiler = require('typescript');
  assert.equal(manifest.devDependencies.typescript, '6.0.3');
  assert.equal(compiler.version, '6.0.3');
  assert.equal(typeof compiler.createProgram, 'function');
  assert.match(compiler.transpileModule('const value: number = 1;', {}).outputText, /value = 1/u);
});

test('uses the TypeScript 7 alias for real semantic application checking', () => {
  assert.equal(manifest.devDependencies.typescript7, 'npm:typescript@7.0.2');
  assert.equal(require('typescript7/package.json').version, '7.0.2');
  assert.match(
    manifest.scripts.typecheck,
    /node \.\/node_modules\/typescript7\/bin\/tsc --noEmit$/u,
  );
  assert.doesNotMatch(manifest.scripts.typecheck, /--noCheck/u);
  const directory = mkdtempSync(path.join(tmpdir(), 'clashking-ts7-semantic-'));
  try {
    const fixture = path.join(directory, 'semantic-error.ts');
    writeFileSync(fixture, 'export const count: number = "not a number";\n');
    const result = spawnSync(
      process.execPath,
      [
        path.join(expoRoot, 'node_modules/typescript7/bin/tsc'),
        '--ignoreConfig',
        '--noEmit',
        '--skipLibCheck',
        '--pretty',
        'false',
        fixture,
      ],
      { cwd: expoRoot, encoding: 'utf8' },
    );
    assert.notEqual(result.status, 0);
    assert.match(result.stdout, /TS2322/u);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
