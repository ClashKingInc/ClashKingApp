import type { CocAccountLink } from '../../auth/models';
import { WarCwl, WarInfo } from '../../war/models';
import type { ClanService } from '../data';
import { Clan, ClanJoinLeave, ClanWarLog, ClanWarStats, ClanWarStatsFilter } from '../models';
import {
  buildClanInfoPresentationModel,
  clanInfoStateKey,
  clanGameUrl,
  loadClanJoinLeave,
  loadClanWarLog,
  loadClanWarStats,
  loadMoreClanJoinLeave,
} from './clan-root-state';

function clan(): Clan {
  return Clan.fromJson({
    tag: '#CLAN',
    name: 'Clan',
    badgeUrls: { medium: 'badge', large: 'badge' },
    memberList: [],
  });
}

describe('clan root state', () => {
  it('uses a canonical clan tag as the detail-state identity', () => {
    expect(clanInfoStateKey(' abc ')).toBe('#ABC');
    expect(clanInfoStateKey('#DEF')).not.toBe(clanInfoStateKey('#ABC'));
  });

  it('matches Flutter war action precedence and canonical linked-account highlighting', () => {
    const current = clan();
    const war = new WarCwl('#CLAN', true, true, new WarInfo('inWar'), null, []);
    const model = buildClanInfoPresentationModel({
      clan: current,
      bookmarked: true,
      accounts: [{ playerTag: ' abc ' } as CocAccountLink],
      war,
    });

    expect(model.bookmarked).toBe(true);
    expect(model.activeUserTags).toEqual(new Set(['#ABC']));
    expect(model.ongoingWar).toBe('cwl');
    expect(model.hasCwlLeagueData).toBe(false);
  });

  it('builds the localized official clan-profile handoff URL', () => {
    expect(clanGameUrl('#2ABC', 'pt_BR')).toBe(
      'https://link.clashofclans.com/pt?action=OpenClanProfile&tag=%232ABC',
    );
  });

  it('returns Flutter empty state when join/leave is unavailable and appends through service', async () => {
    const current = clan();
    const page = new ClanJoinLeave('#CLAN', 2, 1, []);
    const service = {
      loadJoinLeaveForClan: jest.fn(async () => undefined),
      loadMoreJoinLeaveForClan: jest.fn(async (target: Clan) => {
        target.joinLeave = page;
        return true;
      }),
    } as unknown as ClanService;

    await expect(loadClanJoinLeave(service, current)).resolves.toEqual(ClanJoinLeave.empty());
    await expect(loadMoreClanJoinLeave(service, current, ClanJoinLeave.empty())).resolves.toBe(
      page,
    );
  });

  it('loads the API war log and links it to the clan', async () => {
    const current = clan();
    const log = new ClanWarLog([], '#CLAN');
    const loadWarLogData = jest.fn(async () => [log]);
    const service = { loadWarLogData } as unknown as ClanService;

    await expect(loadClanWarLog(service, current)).resolves.toBe(log);
    expect(loadWarLogData).toHaveBeenCalledWith(['#CLAN'], {
      throwOnError: false,
    });
    expect(current.clanWarLog).toBe(log);
  });

  it('uses Flutter bulk loading for initial stats and filtered loading for range changes', async () => {
    const current = clan();
    const initial = new ClanWarStats([], '#CLAN', []);
    const filtered = new ClanWarStats([], '#CLAN', []);
    const loadClanWarStatsData = jest.fn(async () => [initial]);
    const loadClanWarStatsWithFilter = jest.fn(async () => filtered);
    const service = {
      loadClanWarStatsData,
      loadClanWarStatsWithFilter,
    } as unknown as ClanService;

    await expect(loadClanWarStats(service, current, new ClanWarStatsFilter())).resolves.toBe(
      initial,
    );
    expect(current.clanWarStats).toBe(initial);
    expect(loadClanWarStatsWithFilter).not.toHaveBeenCalled();

    const range = new ClanWarStatsFilter({ limit: 25 });
    await expect(loadClanWarStats(service, current, range)).resolves.toBe(filtered);
    expect(loadClanWarStatsWithFilter).toHaveBeenCalledWith('#CLAN', range);
  });
});
