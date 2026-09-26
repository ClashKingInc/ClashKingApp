import {
  gameDataState,
  resetGameDataStateForTesting,
} from '../../../core/game-data/game-data-state';
import {
  RankingAudience,
  RankingBoard,
  RankingEntry,
  RankingLeagueOption,
  RankingLocation,
  RankingPeriod,
  RankingResult,
  type RankingQuery,
} from '../models';
import { rankingLeagueOptionsFromGameData, RankingsProvider } from './rankings-provider';
import { RankingsRequestException, type RankingsServiceContract } from './rankings-service';

afterEach(resetGameDataStateForTesting);

test('Capital rejects non-Monday calendar dates and normalizes legacy archive selections', async () => {
  const service = new RecordingService();
  const provider = new RankingsProvider(service, { clock: () => new Date(2026, 8, 23) });
  await provider.openBoard(RankingBoard.clanCapital, false);
  await provider.selectDate(new Date(2026, 8, 22));
  expect(service.queries).toHaveLength(0);
  await provider.selectDate(new Date(2026, 8, 21));
  expect(service.queries.at(-1)).toMatchObject({
    period: RankingPeriod.history,
    historyDate: new Date(2026, 8, 21),
  });
  await provider.selectDate(provider.today);
  expect(service.queries.at(-1)?.period).toBe(RankingPeriod.current);
  provider.period = RankingPeriod.history;
  provider.historyDate = new Date(2026, 8, 20);
  await provider.reload();
  expect(service.queries.at(-1)?.historyDate).toEqual(new Date(2026, 8, 14));
});

test('builds every game-data tier except Legend League 1 in descending ID order', () => {
  gameDataState.playerLeagueData.leagues = {
    'Legend 1': { _id: 105000036, name: 'Legend League' },
    'Legend 2': { _id: 105000035, name: 'Legend League' },
    'Legend 3': { _id: 105000034, name: 'Legend League' },
    'Pekka 23': { _id: 105000033, name: 'P.E.K.K.A League 23' },
    invalid: { _id: '105000032oops', name: 'Invalid' },
  };
  const options = rankingLeagueOptionsFromGameData();
  expect(options.map((option) => option.id)).toEqual([105000035, 105000034, 105000033]);
  expect(options.map((option) => option.name)).toEqual([
    'Legend League 2',
    'Legend League 3',
    'P.E.K.K.A League 23',
  ]);
});

test('preserves board/filter behavior and matching village board across audiences', async () => {
  const service = new RecordingService();
  const provider = new RankingsProvider(service, {
    leagueOptions: [RankingLeagueOption.legendTwo, RankingLeagueOption.legendThree],
    clock: () => new Date(2026, 6, 20, 12),
  });
  await provider.initialize();
  expect(provider.historyDate).toEqual(new Date(2026, 6, 19));
  await provider.selectBoard(RankingBoard.playerBuilder);
  await provider.selectAudience(RankingAudience.clans);
  expect(provider.board).toBe(RankingBoard.clanBuilder);
  await provider.selectBoard(RankingBoard.clanDonations);
  expect(provider.location.name).toBe('United States');
  await provider.selectPeriod(RankingPeriod.history);
  expect(provider.period).toBe(RankingPeriod.current);
  await provider.selectAudience(RankingAudience.players);
  expect(provider.board).toBe(RankingBoard.playerHome);
});

test('maps daily navigation and calendar selection between live and history with one request each', async () => {
  const service = new RecordingService();
  const provider = new RankingsProvider(service, {
    leagueOptions: [RankingLeagueOption.legendTwo],
    clock: () => new Date(2026, 8, 23, 17),
  });
  await provider.initialize();
  const baseline = service.queries.length;

  await provider.selectDate(new Date(2026, 8, 22));
  expect(provider.period).toBe(RankingPeriod.history);
  expect(provider.historyDate).toEqual(new Date(2026, 8, 22));
  expect(service.queries).toHaveLength(baseline + 1);
  expect(service.queries.at(-1)).toMatchObject({
    period: RankingPeriod.history,
    historyDate: new Date(2026, 8, 22),
  });

  await provider.selectDate(new Date(2026, 8, 23));
  expect(provider.period).toBe(RankingPeriod.current);
  expect(service.queries).toHaveLength(baseline + 2);
  expect(service.queries.at(-1)).toMatchObject({ period: RankingPeriod.current });

  await provider.selectDate(new Date(2026, 8, 23));
  await provider.selectDate(new Date(2026, 8, 24));
  await provider.selectDate(new Date(2023, 8, 22));
  expect(service.queries).toHaveLength(baseline + 2);
});

test('does not offer daily selection for current-only boards', async () => {
  const service = new RecordingService();
  const provider = new RankingsProvider(service, { clock: () => new Date(2026, 8, 23) });
  await provider.initialize();
  await provider.openBoard(RankingBoard.playerTownHall);
  const baseline = service.queries.length;
  await provider.selectDate(new Date(2026, 8, 22));
  expect(provider.period).toBe(RankingPeriod.current);
  expect(service.queries).toHaveLength(baseline);
});

test('treats explicit and message-based not-found failures as empty results', async () => {
  for (const error of [
    new RankingsRequestException(404),
    new Error('No rankings found for selected filters.'),
  ]) {
    const provider = new RankingsProvider(new FailingService(error), {
      leagueOptions: [RankingLeagueOption.legendTwo],
    });
    await provider.initialize();
    expect(provider.error).toBeNull();
    expect(provider.result?.entries).toEqual([]);
    expect(provider.isLoading).toBe(false);
  }
});

test('ignores an older response that completes after a newer reload', async () => {
  const deferred: {
    query: RankingQuery;
    resolve: (result: RankingResult) => void;
  }[] = [];
  const service: RankingsServiceContract = {
    fetchLocations: async () => [RankingLocation.worldwide()],
    fetchRankings: (query) =>
      new Promise((resolve) => {
        deferred.push({ query, resolve });
      }),
  };
  const provider = new RankingsProvider(service, {
    leagueOptions: [RankingLeagueOption.legendTwo],
  });
  const older = provider.reload();
  provider.townHallLevel = 17;
  const newer = provider.reload();
  deferred[1]?.resolve(resultFor(deferred[1].query, '#NEW'));
  await newer;
  deferred[0]?.resolve(resultFor(deferred[0].query, '#OLD'));
  await older;
  expect(provider.result?.entries[0]?.tag).toBe('#NEW');
  expect(provider.isLoading).toBe(false);
});

test('loads locations before the initial location-only leaderboard', async () => {
  const service = new RecordingService();
  const provider = new RankingsProvider(service, {
    leagueOptions: [RankingLeagueOption.legendTwo],
  });
  provider.audience = RankingAudience.clans;
  provider.clanBoard = RankingBoard.clanDonations;

  await provider.initialize();

  expect(service.queries).toHaveLength(1);
  expect(service.queries[0]).toMatchObject({
    board: RankingBoard.clanDonations,
    location: expect.objectContaining({ id: 32000007 }),
  });
});

class RecordingService implements RankingsServiceContract {
  readonly queries: RankingQuery[] = [];
  async fetchLocations() {
    return [
      RankingLocation.worldwide(),
      new RankingLocation(32000007, 'United States', true, 'US'),
    ];
  }
  async fetchRankings(query: RankingQuery) {
    this.queries.push(query);
    return resultFor(query, query.board.isClan ? '#CLAN' : '#PLAYER');
  }
}

class FailingService implements RankingsServiceContract {
  constructor(private readonly failure: unknown) {}
  async fetchLocations() {
    return [RankingLocation.worldwide()];
  }
  async fetchRankings(_query: RankingQuery): Promise<RankingResult> {
    throw this.failure;
  }
}

function resultFor(query: RankingQuery, tag: string): RankingResult {
  return new RankingResult(
    [
      new RankingEntry(
        query.board.audience,
        1,
        2,
        tag,
        tag,
        '',
        6000,
        query.board.iconUrl,
        query.board.iconUrl,
        18,
      ),
    ],
    query.board.source,
    query.board.source === 'official' ? 200 : 500,
  );
}
