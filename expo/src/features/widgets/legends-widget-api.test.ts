import { Effect } from 'effect';
import type { ContractApiService } from '../../core/api/contract-api';
import { fetchLegendsWidgetData } from './legends-widget-api';

function setup(tag = '#P') {
  const execute = jest.fn((endpoint, input) => {
    expect(endpoint.auth).toBe('public');
    if (endpoint === undefined) throw new Error('Missing endpoint');
    if ('day' in input.path)
      return Effect.succeed({
        tag,
        day: '2026-09-22',
        attackTrophies: 40,
        defenseTrophies: -20,
        trophies: 20,
        attacks: [{ trophies: 40, automatic: false, time: '20260922T120000.000Z' }],
        defenses: [{ trophies: -20, automatic: true }],
      });
    if ('tags' in input.body)
      return Effect.succeed({
        items: [{ tag: '#P', name: 'Chief', trophies: 5400, globalRank: 123 }],
      });
    return Effect.succeed({ seasonStart: '2026-08-31', seasonEnd: '2026-09-28' });
  });
  return { execute, api: { execute } as unknown as ContractApiService };
}

test('loads only public widget data without the authenticated player-detail fan-out', async () => {
  const { api, execute } = setup();
  const result = await fetchLegendsWidgetData(api, '#P', '2026-09-22');
  expect(execute).toHaveBeenCalledTimes(3);
  expect(result.currentDay?.trophyChange).toBe(20);
  expect(result.currentRank?.globalRank).toBe(123);
  expect(result.seasonStart).toBe('2026-08-31');
});

test('rejects another player snapshot rather than overwriting the selected player', async () => {
  const { api } = setup('#OTHER');
  await expect(fetchLegendsWidgetData(api, '#P', '2026-09-22')).rejects.toThrow('does not match');
});
