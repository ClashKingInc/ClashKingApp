import {
  Player,
  PlayerClanOverview,
  type TodoProgressMetric,
  type WarMemberPresenceLike,
} from '../../player/models';
import { buildTodoHeaderSummary, buildTodoScreenModel } from './todo-model';

function player(input: {
  tag: string;
  name: string;
  clan?: string;
  lastOnline: string;
  progress: number;
}): Player {
  const value = Player.empty();
  value.tag = input.tag;
  value.name = input.name;
  value.clan = null;
  value.clanOverview = new PlayerClanOverview('', input.clan ?? '', 0, {
    small: '',
    medium: '',
    large: '',
  });
  value.lastOnline = new Date(input.lastOnline);
  value.getTodoProgressRatio = () => input.progress;
  value.getTodoProgressMetrics = () => [];
  return value;
}

describe('Todo screen model parity', () => {
  const presence = (): WarMemberPresenceLike => ({ attacksDone: 0, attacksAvailable: 0 });

  test('applies configuration, search, filter counts, and last-active sorting in Flutter order', () => {
    const alpha = player({
      tag: '#ALPHA',
      name: 'Alpha',
      clan: 'Kings',
      lastOnline: '2026-08-29T10:00:00.000Z',
      progress: 0.5,
    });
    const beta = player({
      tag: '#BETA',
      name: 'Beta',
      clan: 'Queens',
      lastOnline: '2026-08-29T12:00:00.000Z',
      progress: 1,
    });
    const hidden = player({
      tag: '#HIDDEN',
      name: 'Hidden',
      lastOnline: '2026-08-29T13:00:00.000Z',
      progress: 0,
    });
    const unrelated = player({
      tag: '#OTHER',
      name: 'Other',
      lastOnline: '2026-08-29T14:00:00.000Z',
      progress: 0,
    });
    const model = buildTodoScreenModel({
      players: [alpha, beta, hidden, unrelated],
      linkedTags: new Set(['ALPHA', '#BETA', '#HIDDEN']),
      bookmarkedTags: new Set(['#BETA', '#OTHER']),
      isShown: (tag) => tag !== '#HIDDEN',
      presenceFor: presence,
      query: '',
      filter: 'all',
    });

    expect(model.visiblePlayers.map((value) => value.tag)).toEqual(['#OTHER', '#BETA', '#ALPHA']);
    expect(model.filterCounts).toEqual({
      all: 3,
      mine: 2,
      needsAction: 2,
      done: 1,
      bookmarked: 2,
    });

    const clanSearch = buildTodoScreenModel({
      players: [alpha, beta],
      linkedTags: new Set(['#ALPHA', '#BETA']),
      bookmarkedTags: new Set(),
      isShown: () => true,
      presenceFor: presence,
      query: 'king',
      filter: 'needs_action',
    });
    expect(clanSearch.visiblePlayers.map((value) => value.tag)).toEqual(['#ALPHA']);
    expect(clanSearch.filterCounts.all).toBe(1);
  });

  test('builds header progress with weighted progress fields but counts each task once', () => {
    const first = player({
      tag: '#ONE',
      name: 'One',
      lastOnline: '2026-08-29T10:00:00.000Z',
      progress: 0,
    });
    const second = player({
      tag: '#TWO',
      name: 'Two',
      lastOnline: '2026-08-29T11:00:00.000Z',
      progress: 0,
    });
    first.seasonPass = [];
    second.seasonPass = [];
    Object.defineProperty(first, 'currentSeasonPoints', { value: 500 });
    Object.defineProperty(second, 'currentSeasonPoints', { value: 1000 });
    Object.defineProperty(first, 'seasonPassRatio', { value: 0.5 });
    Object.defineProperty(second, 'seasonPassRatio', { value: 1 });
    first.getTodoProgressMetrics = () =>
      [
        {
          label: 'legend_attacks',
          done: 4,
          total: 8,
          progressDone: 4,
          progressTotal: 8,
          progressRatio: 0.5,
        },
        {
          label: 'season_pass',
          done: 500,
          total: 1000,
          progressDone: 1,
          progressTotal: 2,
          progressRatio: 0.5,
        },
      ] as TodoProgressMetric[];
    second.getTodoProgressMetrics = () =>
      [
        {
          label: 'season_pass',
          done: 1000,
          total: 1000,
          progressDone: 2,
          progressTotal: 2,
          progressRatio: 1,
        },
      ] as TodoProgressMetric[];

    const summary = buildTodoHeaderSummary(
      [first, second],
      presence,
      new Date('2026-08-10T12:00:00.000Z'),
    );
    expect(summary.openTasks).toBe(1);
    expect(summary.completedTasks).toBe(1);
    expect(summary.metrics.get('season_pass')).toEqual({ done: 1500, total: 1676 });
    expect(summary.progressRatio).toBeCloseTo(7 / 12);
  });
});
