import { createTranslator } from '../../../i18n';
import { Player, requiredSeasonPassPoints } from '../../player/models/player';
import { PlayerClanOverview } from '../../player/models/player-support';
import type { RankedLeagueData } from '../../player/models/player-ranked';
import {
  UpgradeCategory,
  UpgradeQueue,
  type UpgradeTrackerSnapshot,
} from '../../upgrade-tracker/models';
import {
  buildHomeRankedModel,
  buildHomeTodoModel,
  buildHomeUpgradeModel,
} from './home-dashboard-model';

const t = createTranslator('en');

function player(tag: string, name: string): Player {
  const value = Player.empty();
  value.tag = tag;
  value.name = name;
  value.townHallLevel = 17;
  value.townHallPic = `town-hall:${tag}`;
  value.clanTag = '#CLAN';
  value.clanOverview = new PlayerClanOverview('#CLAN', 'Clan', 20, {
    small: '',
    medium: '',
    large: '',
  });
  return value;
}

describe('Home dashboard model parity', () => {
  test('builds per-account and combined to-do progress without denominator weighting', () => {
    const first = player('#ONE', 'One');
    const second = player('#TWO', 'Two');
    first.lastOnline = new Date('2026-08-15T11:30:00.000Z');
    second.lastOnline = new Date(0);
    const now = new Date('2026-08-15T12:00:00.000Z');
    const model = buildHomeTodoModel([first, second], { getWarCwlByTag: () => null }, t, 'fr', now);

    expect(model.accounts).toHaveLength(2);
    expect(model.accounts[0]?.status).toBe('Active 30 minutes ago');
    expect(model.accounts[1]?.status).toBe('Last active unavailable');
    expect(model.combined?.total).toBe(400);
    expect(model.combined?.status).toContain('One, Two');
    expect(model.accounts[0]?.metrics.find(({ kind }) => kind === 'seasonPass')?.detail).toContain(
      new Intl.NumberFormat('fr', { notation: 'compact' }).format(requiredSeasonPassPoints(now)),
    );
  });

  test('drops accounts with no ranked tier or history and preserves the live group counters', () => {
    const first = player('#ONE', 'Official name');
    const data = {
      playerName: 'Ranked name',
      currentTier: { smallIconUrl: 'tier-small', largeIconUrl: 'tier-large' },
      history: [],
      currentMember: {
        leagueTrophies: 1_234,
        attackWinCount: 3,
        attackLoseCount: 2,
        defenseWinCount: 4,
        defenseLoseCount: 1,
      },
      trophies: 900,
      currentRank: 7,
      currentMaxBattles: 10,
    } as unknown as RankedLeagueData;
    const model = buildHomeRankedModel([first], new Map([['#ONE', data]]));

    expect(model).toMatchObject({
      state: 'ready',
      accounts: [
        {
          name: 'Ranked name',
          tierIconUrl: 'tier-small',
          trophies: 1234,
          rank: 7,
          attacksDone: 5,
          defensesDone: 5,
          maxBattles: 10,
        },
      ],
    });
  });

  test('counts missing snapshots as zero completion and flags elapsed imported work', () => {
    const imported = player('#ONE', 'Imported');
    const missing = player('#TWO', 'Missing');
    const wall = { currentLevel: 17, targetLevel: 17, count: 2 };
    const started = {
      activeSeconds: 60,
      recurrentHelper: false,
      isComplete: false,
      count: 1,
      currentLevel: 1,
      targetLevel: 2,
    };
    const snapshot = {
      tag: '#ONE',
      name: 'Imported',
      townHallLevel: 17,
      capturedAt: new Date('2026-08-14T12:00:00.000Z'),
      buildPlan: () => [],
      itemsFor: (options: { queue?: string; category?: string }) => {
        if (options.category === UpgradeCategory.walls) return [wall];
        if (options.queue === UpgradeQueue.builders) return [started];
        if (options.queue) return [];
        return [started];
      },
      remainingActiveSeconds: () => 0,
      buildersFor: () => 2,
      overallSummary: () => ({ completion: 0.8 }),
    } as unknown as UpgradeTrackerSnapshot;
    const model = buildHomeUpgradeModel(
      [imported, missing],
      new Map([
        ['#ONE', snapshot],
        ['#TWO', null],
      ]),
      t,
      { now: new Date('2026-08-15T12:00:00.000Z') },
    );

    expect(model).toMatchObject({
      state: 'ready',
      combined: { completion: 0.4 },
      accounts: [{ needsUpdate: true, hasActionableQueueWork: true, wallsAtMax: 2 }],
      missingAccounts: [{ name: 'Missing', townHallLevel: 17 }],
    });
    if (model.state === 'ready') {
      expect(model.combined.status).toContain('Missing');
      expect(model.combined.status).toContain('Imported');
    }
  });
});
