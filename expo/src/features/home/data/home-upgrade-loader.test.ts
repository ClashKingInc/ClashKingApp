import type { UpgradeTrackerSnapshot } from '../../upgrade-tracker/models';
import { loadHomeUpgradeSnapshots } from './home-upgrade-loader';

test('home upgrade reload forwards refresh intent and retains failed accounts as missing', async () => {
  const alpha = { tag: '#AAA' } as UpgradeTrackerSnapshot;
  const load = jest.fn(async (tag: string, forceRefresh: boolean) => {
    expect(forceRefresh).toBe(true);
    if (tag === '#BBB') throw new Error('offline');
    return alpha;
  });

  const result = await loadHomeUpgradeSnapshots([{ tag: '#AAA' }, { tag: '#BBB' }], load, true);

  expect(load).toHaveBeenNthCalledWith(1, '#AAA', true);
  expect(load).toHaveBeenNthCalledWith(2, '#BBB', true);
  expect(result.get('#AAA')).toBe(alpha);
  expect(result.get('#BBB')).toBeNull();
});
