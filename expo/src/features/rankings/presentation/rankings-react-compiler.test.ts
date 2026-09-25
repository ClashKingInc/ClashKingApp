import { transformFileSync } from '@babel/core';
import reactCompiler from 'babel-plugin-react-compiler';
import { createRequire } from 'node:module';
import path from 'node:path';

const transformTypescript = createRequire(__filename)('@babel/plugin-transform-typescript') as (
  ...args: never[]
) => unknown;

function compile(file: string): string {
  return (
    transformFileSync(path.join(process.cwd(), file), {
      babelrc: false,
      configFile: false,
      parserOpts: { sourceType: 'module', plugins: ['typescript', 'jsx'] },
      plugins: [
        [reactCompiler, {}],
        [transformTypescript, { isTSX: true }],
      ],
    })?.code ?? ''
  );
}

test('compiled RankingsRoot publishes the revision instead of caching mutable provider output', () => {
  const output = compile('src/features/rankings/presentation/rankings-root.tsx');
  const start = output.indexOf('function RankingsRoot');
  expect(start).toBeGreaterThanOrEqual(0);
  expect(output.slice(start, start + 500)).toContain("'use no memo'");
  expect(output).toContain('revision={revision}');
  expect(output).toContain('locationPreferences={locationPreferences}');
});

test('compiled Rankings screen and filters read current mutable provider fields', () => {
  const output = compile('src/features/rankings/presentation/rankings-screen.tsx');
  for (const name of [
    'RankingsScreen',
    'RankingControls',
    'RankingLocationPicker',
    'RankingDateSheet',
  ]) {
    const start = output.indexOf(`function ${name}`);
    expect(start).toBeGreaterThanOrEqual(0);
    expect(output.slice(start, start + 750)).toContain("'use no memo'");
  }
  expect(output).toContain('provider.location');
  expect(output).toContain('provider.result');
});
