import assert from 'node:assert/strict';
import { test } from 'node:test';
import { disallowedAppContractImports, moduleSpecifiers } from './api-package-boundary.mjs';

for (const source of [
  "import { value } from '@clashking/api-contracts';",
  "import type { Value } from '@clashking/api-contracts/deferred-runtime';",
  "export * from '@clashking/api-contracts';",
  "export { value } from '@clashking/api-contracts/deferred-runtime';",
  "const promise = import('@clashking/api-contracts');",
  "const module = require('@clashking/api-contracts/deferred-runtime');",
  "type Value = import('@clashking/api-contracts').AnyEndpoint;",
]) {
  test(`rejects a non-Expo contract dependency: ${source}`, () => {
    assert.equal(disallowedAppContractImports(source).length, 1);
  });
}

test('allows the restricted Expo entry and the public browser-safe client', () => {
  assert.deepEqual(
    disallowedAppContractImports(`
    import { value } from '@clashking/api-contracts/expo';
    import type { AnyEndpoint } from '@clashking/api-contracts/expo';
    import { createApiClient } from '@clashking/api-client';
    const lazy = import('@clashking/api-contracts/expo');
  `),
    [],
  );
});

test('traces dynamic dependencies inside an installed contract graph too', () => {
  assert.deepEqual(
    moduleSpecifiers(`
    export * from './safe.js';
    const load = () => import('./deferred-runtime.js');
    const filesystem = require('node:fs');
  `),
    ['./safe.js', './deferred-runtime.js', 'node:fs'],
  );
});

test('does not treat prose or an unrelated package name as an import', () => {
  assert.deepEqual(
    disallowedAppContractImports(`
    const documentation = '@clashking/api-contracts';
    import value from '@clashking/api-contracts-extra';
  `),
    [],
  );
});
