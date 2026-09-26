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

test('compiled StatsRoot invalidates the StatsScreen element when the store revision changes', () => {
  const output = compile('src/features/stats/presentation/stats-root.tsx');

  expect(output).toContain('useSyncExternalStore');
  expect(output).toContain("'use no memo'");
  expect(output).toContain('revision={revision}');
});

test('chart preferences read current per-page state without compiler memoization', () => {
  const output = compile('src/features/stats/presentation/stats-chart-preferences.tsx');
  for (const name of ['StatsChartPreferencesProvider', 'StatsChartSettings']) {
    const start = output.indexOf(`function ${name}`);
    expect(start).toBeGreaterThanOrEqual(0);
    expect(output.slice(start, start + 700)).toContain("'use no memo'");
  }
});

test('compiler leaves mutable StatsProvider readers unmemoized', () => {
  const output = compile('src/features/stats/presentation/stats-screen.tsx');
  const readers = [
    'StatsScreen',
    'StatsSectionContent',
    'ItemsSection',
    'BattleFilters',
    'BattleFiltersCore',
    'LegendFilters',
  ];

  readers.forEach((name) => {
    const start = output.indexOf(`function ${name}`);
    expect(start).toBeGreaterThanOrEqual(0);
    expect(output.slice(start, start + 700)).toContain("'use no memo'");
  });
});

test('World metadata readers invalidate with the mutable game-data store', () => {
  const output = compile('src/features/stats/presentation/world-stats-sections.tsx');
  for (const name of ['usePlayerLeagues', 'useLocalizedCwlLeagues']) {
    const start = output.indexOf(`function ${name}`);
    expect(start).toBeGreaterThanOrEqual(0);
    expect(output.slice(start, start + 700)).toContain("'use no memo'");
  }
});
