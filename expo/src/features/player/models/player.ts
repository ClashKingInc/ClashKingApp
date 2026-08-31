import { ImageAssets } from '@/core/assets/image-assets';
import { gameDataState } from '@/core/game-data/game-data-state';
import { isPet, isSiegeMachine, isSuperTroop } from '@/core/game-data/game-data-service';
import {
  filterGameData,
  filterSpellGameData,
  generateCompleteItemList,
} from '../data/player-item-utils';
import { int, intMap, nestedIntMap, record, records, string, type JsonRecord } from './parsing';
import {
  PlayerBuilderBaseHero,
  PlayerBuilderBaseTroop,
  PlayerEquipment,
  PlayerHero,
  PlayerPet,
  PlayerSiegeMachine,
  PlayerSpell,
  PlayerSuperTroop,
  PlayerTroop,
} from './player-items';
import { PlayerLegendRanking, PlayerLegendStats } from './player-legend';
import {
  PlayerAchievement,
  PlayerClanGames,
  PlayerClanOverview,
  PlayerSeasonPass,
} from './player-support';
import { PlayerRankings } from './player-ranked';
import { PlayerWarStats, WarInfoSnapshot } from './player-war';

export class Player {
  name: string;
  tag: string;
  townHallLevel: number;
  townHallWeaponLevel: number;
  expLevel: number;
  trophies: number;
  bestTrophies: number;
  warStars: number;
  attackWins: number;
  defenseWins: number;
  builderHallLevel: number;
  builderBaseTrophies: number;
  bestBuilderBaseTrophies: number;
  builderBaseLeague: string;
  builderBaseLeagueUrl: string;
  achievements: PlayerAchievement[];
  clanTag: string;
  clan: unknown | null = null;
  clanOverview: PlayerClanOverview;
  role: string;
  warPreference: string;
  donations: number;
  donationsReceived: number;
  clanCapitalContributions: number;
  league: string;
  townHallPic: string;
  builderHallPic: string;
  leagueUrl: string;
  clanGamesPoint: PlayerClanGames[] = [];
  seasonPass: PlayerSeasonPass[] = [];
  lastOnline: Date = new Date(0);
  heroes: PlayerHero[];
  bbHeroes: PlayerBuilderBaseHero[];
  troops: PlayerTroop[];
  superTroops: PlayerSuperTroop[];
  bbTroops: PlayerBuilderBaseTroop[];
  spells: PlayerSpell[];
  equipments: PlayerEquipment[];
  siegeMachines: PlayerSiegeMachine[];
  pets: PlayerPet[];
  legendsBySeason: PlayerLegendStats | null = null;
  legendRanking: PlayerLegendRanking[] = [];
  rankings: PlayerRankings | null = null;
  warStats: PlayerWarStats | null = null;
  warData: WarInfoSnapshot | null = null;
  goldBySeason: Record<string, number> = {};
  darkElixirBySeason: Record<string, number> = {};
  activityBySeason: Record<string, number> = {};
  attackWinsBySeason: Record<string, number> = {};
  seasonTrophiesBySeason: Record<string, number> = {};
  donationsBySeason: Record<string, Record<string, number>> = {};
  constructor(input: {
    name: string;
    tag: string;
    townHallLevel: number;
    townHallWeaponLevel: number;
    expLevel: number;
    trophies: number;
    bestTrophies: number;
    warStars: number;
    attackWins: number;
    defenseWins: number;
    builderHallLevel: number;
    builderBaseTrophies: number;
    bestBuilderBaseTrophies: number;
    builderBaseLeague: string;
    builderBaseLeagueUrl: string;
    achievements: PlayerAchievement[];
    clanTag: string;
    clanOverview: PlayerClanOverview;
    role: string;
    warPreference: string;
    donations: number;
    donationsReceived: number;
    clanCapitalContributions: number;
    league: string;
    townHallPic: string;
    builderHallPic: string;
    leagueUrl: string;
    heroes: PlayerHero[];
    bbHeroes: PlayerBuilderBaseHero[];
    troops: PlayerTroop[];
    superTroops: PlayerSuperTroop[];
    bbTroops: PlayerBuilderBaseTroop[];
    spells: PlayerSpell[];
    equipments: PlayerEquipment[];
    siegeMachines: PlayerSiegeMachine[];
    pets: PlayerPet[];
  }) {
    Object.assign(this, input);
    this.name = input.name;
    this.tag = input.tag;
    this.townHallLevel = input.townHallLevel;
    this.townHallWeaponLevel = input.townHallWeaponLevel;
    this.expLevel = input.expLevel;
    this.trophies = input.trophies;
    this.bestTrophies = input.bestTrophies;
    this.warStars = input.warStars;
    this.attackWins = input.attackWins;
    this.defenseWins = input.defenseWins;
    this.builderHallLevel = input.builderHallLevel;
    this.builderBaseTrophies = input.builderBaseTrophies;
    this.bestBuilderBaseTrophies = input.bestBuilderBaseTrophies;
    this.builderBaseLeague = input.builderBaseLeague;
    this.builderBaseLeagueUrl = input.builderBaseLeagueUrl;
    this.achievements = input.achievements;
    this.clanTag = input.clanTag;
    this.clanOverview = input.clanOverview;
    this.role = input.role;
    this.warPreference = input.warPreference;
    this.donations = input.donations;
    this.donationsReceived = input.donationsReceived;
    this.clanCapitalContributions = input.clanCapitalContributions;
    this.league = input.league;
    this.townHallPic = input.townHallPic;
    this.builderHallPic = input.builderHallPic;
    this.leagueUrl = input.leagueUrl;
    this.heroes = input.heroes;
    this.bbHeroes = input.bbHeroes;
    this.troops = input.troops;
    this.superTroops = input.superTroops;
    this.bbTroops = input.bbTroops;
    this.spells = input.spells;
    this.equipments = input.equipments;
    this.siegeMachines = input.siegeMachines;
    this.pets = input.pets;
  }
  get donationRatio() {
    return this.donationsReceived === 0
      ? '0.0'
      : (this.donations / this.donationsReceived).toFixed(2);
  }
  get warPreferenceImage() {
    return this.warPreference === 'in' ? ImageAssets.warPreferenceIn : ImageAssets.warPreferenceOut;
  }
  get currentLegendSeason() {
    return this.legendsBySeason?.currentSeasonAt() ?? null;
  }
  get currentSeasonKey() {
    const now = new Date();
    return `${now.getFullYear().toString().padStart(4, '0')}-${(now.getMonth() + 1).toString().padStart(2, '0')}`;
  }
  get currentSeasonPoints() {
    return this.seasonPass.find((item) => item.season === this.currentSeasonKey)?.points ?? 0;
  }
  get currentClanGamesPoints() {
    return this.clanGamesPoint.find((item) => item.season === this.currentSeasonKey)?.points ?? 0;
  }
  get seasonPassRatio() {
    const required = requiredSeasonPassPoints();
    return required <= 0 ? 0 : Math.min(this.currentSeasonPoints / required, 1);
  }
  get seasonPassPointLeft() {
    return Math.trunc(
      Math.max(0, Math.min(2600, requiredSeasonPassPoints() - this.currentSeasonPoints)),
    );
  }
  get clanGamesRatio() {
    const required = clanGamesDailyTarget();
    return required <= 0 ? 0 : Math.min(this.currentClanGamesPoints / required, 1);
  }
  get clanGamesPointLeft() {
    return Math.trunc(
      Math.max(0, Math.min(4000, clanGamesDailyTarget() - this.currentClanGamesPoints)),
    );
  }
  getBestTrophiesSeason() {
    return reduceOrNull(this.legendRanking, (a, b) => (a.trophies > b.trophies ? a : b));
  }
  getBestGlobalRankSeason() {
    return reduceOrNull(this.legendRanking, (a, b) => (a.rank < b.rank ? a : b));
  }
  getLastSeason() {
    return this.legendRanking[0] ?? null;
  }
  getBestAttackWinsSeason() {
    return reduceOrNull(this.legendRanking, (a, b) => (a.attackWins > b.attackWins ? a : b));
  }
  getTodoProgressRatio(memberCwl: WarMemberPresenceLike) {
    const metrics = this.getTodoProgressMetrics(memberCwl);
    if (!metrics.length) return 1;
    const done = metrics.reduce(
      (sum, metric) => sum + Math.max(0, Math.min(metric.progressTotal, metric.progressDone)),
      0,
    );
    const total = metrics.reduce((sum, metric) => sum + metric.progressTotal, 0);
    return total === 0 ? 1 : Math.max(0, Math.min(1, done / total));
  }
  getTodoProgressMetrics(memberCwl: WarMemberPresenceLike, now = new Date()): TodoProgressMetric[] {
    const metrics: TodoProgressMetric[] = [];
    if (this.league === 'Legend League' && this.currentLegendSeason?.currentDay)
      metrics.push(
        new TodoProgressMetric(
          'legend_attacks',
          this.currentLegendSeason.currentDay.totalAttacks,
          8,
        ),
      );
    const clan = this.clan as ClanWarStateLike | null;
    const currentWar = clan?.warCwl?.warInfo ?? (this.warData as TodoWarLike | null);
    const inCwl = clan?.warCwl?.isInCwl === true;
    if (currentWar?.state === 'inWar' && currentWar.isPlayerInWar(this.tag, this.clanTag))
      metrics.push(
        new TodoProgressMetric(
          inCwl ? 'cwl_attacks' : 'war_attacks',
          currentWar.getAttacksDoneByPlayer(this.tag, this.clanTag),
          currentWar.attacksPerMember ?? (inCwl ? 1 : 2),
        ),
      );
    else if (inCwl && isInCwlWindow(now) && memberCwl.attacksAvailable > 0)
      metrics.push(
        new TodoProgressMetric('cwl_attacks', memberCwl.attacksDone, memberCwl.attacksAvailable),
      );
    if (isInClanGamesWindow(now)) {
      const required = requiredClanGamesPoints(now);
      const total = required > 0 ? required : 4000;
      metrics.push(
        new TodoProgressMetric(
          'clan_games',
          this.currentClanGamesPoints,
          total,
          Math.max(0, Math.min(1, this.currentClanGamesPoints / total)) * 2,
          2,
        ),
      );
    }
    const seasonRequired = requiredSeasonPassPoints(now),
      seasonRatio =
        seasonRequired <= 0
          ? 1
          : Math.max(0, Math.min(1, this.currentSeasonPoints / seasonRequired));
    metrics.push(
      new TodoProgressMetric(
        'season_pass',
        this.currentSeasonPoints,
        seasonRequired,
        seasonRatio * 2,
        2,
      ),
    );
    return metrics;
  }
  static fromJson(json: JsonRecord): Player {
    try {
      const league = record(json.leagueTier ?? json.league),
        heroes = records(json.heroes),
        troops = records(json.troops),
        home = (item: JsonRecord) => item.village === 'home',
        builder = (item: JsonRecord) => item.village === 'builderBase';
      const heroData = record(gameDataState.heroesData.heroes),
        troopData = record(gameDataState.troopsData.troops);
      return new Player({
        name: string(json.name, 'Unknown'),
        tag: string(json.tag, 'Unknown'),
        townHallLevel: int(json.townHallLevel),
        townHallWeaponLevel: int(json.townHallWeaponLevel),
        expLevel: int(json.expLevel),
        trophies: intString(json.trophies),
        bestTrophies: intString(json.bestTrophies),
        warStars: intString(json.warStars),
        attackWins: int(json.attackWins),
        defenseWins: int(json.defenseWins),
        builderHallLevel: int(json.builderHallLevel),
        builderBaseTrophies: intString(json.builderBaseTrophies),
        bestBuilderBaseTrophies: intString(json.bestBuilderBaseTrophies),
        builderBaseLeague: leagueName(json.builderBaseLeague),
        builderBaseLeagueUrl: ImageAssets.getBuilderBaseLeagueImage(json.builderBaseLeague),
        achievements: records(json.achievements).map(PlayerAchievement.fromJson),
        clanTag: string(record(json.clan).tag),
        clanOverview: json.clan
          ? PlayerClanOverview.fromJson(record(json.clan))
          : PlayerClanOverview.empty(),
        role: string(json.role),
        warPreference: string(json.warPreference),
        donations: intString(json.donations),
        donationsReceived: intString(json.donationsReceived),
        clanCapitalContributions: intString(json.clanCapitalContributions),
        league: string(league.name, 'Unranked'),
        townHallPic: ImageAssets.townHall(int(json.townHallLevel)),
        builderHallPic: ImageAssets.builderHall(int(json.builderHallLevel)),
        leagueUrl: ImageAssets.getLeagueImage(string(league.name, 'Unranked')),
        heroes: generateCompleteItemList({
          jsonList: heroes.filter(home),
          gameData: filterGameData(heroData, (_, v) => v.type === 'hero'),
          factory: PlayerHero.fromRaw,
        }),
        bbHeroes: generateCompleteItemList({
          jsonList: heroes.filter(builder),
          gameData: filterGameData(heroData, (_, v) => v.type === 'bb-hero'),
          factory: PlayerBuilderBaseHero.fromRaw,
        }),
        troops: generateCompleteItemList({
          jsonList: troops.filter(
            (item) =>
              home(item) &&
              !isSuperTroop(string(item.name)) &&
              !isSiegeMachine(string(item.name)) &&
              !isPet(string(item.name)),
          ),
          gameData: filterGameData(
            troopData,
            (key, v) =>
              v.type === 'troop' && !isSuperTroop(key) && !isSiegeMachine(key) && !isPet(key),
          ),
          factory: PlayerTroop.fromRaw,
        }),
        superTroops: generateCompleteItemList({
          jsonList: troops.filter((item) => home(item) && isSuperTroop(string(item.name))),
          gameData: filterGameData(troopData, (key, v) => v.type === 'troop' && isSuperTroop(key)),
          factory: PlayerSuperTroop.fromRaw,
        }),
        siegeMachines: generateCompleteItemList({
          jsonList: troops.filter((item) => home(item) && isSiegeMachine(string(item.name))),
          gameData: filterGameData(
            troopData,
            (key, v) => v.type === 'siege-machine' && isSiegeMachine(key),
          ),
          factory: PlayerSiegeMachine.fromRaw,
        }),
        pets: generateCompleteItemList({
          jsonList: troops.filter((item) => home(item) && isPet(string(item.name))),
          gameData: record(gameDataState.petsData.pets),
          factory: PlayerPet.fromRaw,
        }),
        bbTroops: generateCompleteItemList({
          jsonList: troops.filter(builder),
          gameData: filterGameData(troopData, (_, v) => v.type === 'bb-troop'),
          factory: PlayerBuilderBaseTroop.fromRaw,
          nameMatcher: (name, item) =>
            (name === 'Baby Dragon 2' && item.name === 'Baby Dragon') || name === item.name,
        }),
        spells: generateCompleteItemList({
          jsonList: Array.isArray(json.spells) ? json.spells : null,
          gameData: filterSpellGameData(gameDataState.spellsData.spells),
          factory: PlayerSpell.fromRaw,
        }),
        equipments: generateCompleteItemList({
          jsonList: Array.isArray(json.heroEquipment) ? json.heroEquipment : null,
          gameData: record(gameDataState.gearsData.gears),
          factory: PlayerEquipment.fromRaw,
        }),
      });
    } catch {
      return Player.empty();
    }
  }
  static empty() {
    const player = new Player({
      name: 'Unknown',
      tag: 'Unknown',
      townHallLevel: 0,
      townHallWeaponLevel: 0,
      expLevel: 0,
      trophies: 0,
      bestTrophies: 0,
      warStars: 0,
      attackWins: 0,
      defenseWins: 0,
      builderHallLevel: 0,
      builderBaseTrophies: 0,
      bestBuilderBaseTrophies: 0,
      builderBaseLeague: 'Unranked',
      builderBaseLeagueUrl: ImageAssets.builderBaseStar,
      achievements: [],
      clanTag: '',
      clanOverview: PlayerClanOverview.empty(),
      role: '',
      warPreference: '',
      donations: 0,
      donationsReceived: 0,
      clanCapitalContributions: 0,
      league: '',
      townHallPic: ImageAssets.townHall(1),
      builderHallPic: ImageAssets.builderHall(1),
      leagueUrl: '',
      heroes: [],
      bbHeroes: [],
      troops: [],
      superTroops: [],
      bbTroops: [],
      spells: [],
      equipments: [],
      siegeMachines: [],
      pets: [],
    });
    player.lastOnline = new Date();
    return player;
  }
  enrichWithFullStats(json: JsonRecord) {
    this.clanGamesPoint = Object.entries(record(json.clan_games)).map(([season, value]) =>
      PlayerClanGames.fromJson(season, record(value)),
    );
    this.seasonPass = Object.entries(record(json.season_pass)).map(
      ([season, value]) => new PlayerSeasonPass(season, int(value)),
    );
    this.lastOnline =
      typeof json.last_online === 'number' ? new Date(json.last_online * 1000) : new Date(0);
    this.legendsBySeason = json.legends_by_season
      ? PlayerLegendStats.fromJson(record(json.legends_by_season))
      : null;
    this.legendRanking = records(json.legend_eos_ranking).map(PlayerLegendRanking.fromJson);
    this.rankings = json.rankings ? PlayerRankings.fromJson(record(json.rankings)) : null;
    this.goldBySeason = intMap(json.gold);
    this.darkElixirBySeason = intMap(json.dark_elixir);
    this.activityBySeason = intMap(json.activity);
    this.attackWinsBySeason = intMap(json.attack_wins);
    this.seasonTrophiesBySeason = intMap(json.season_trophies);
    this.donationsBySeason = nestedIntMap(json.donations);
    const currentWar = record(record(json.war_data).currentWarInfo);
    this.warData = Object.keys(currentWar).length
      ? WarInfoSnapshot.fromJson(currentWar).reorderForUser(this.tag)
      : null;
  }
}

export interface WarMemberPresenceLike {
  attacksAvailable: number;
  attacksDone: number;
}
interface TodoWarLike {
  state: string;
  attacksPerMember?: number | null;
  isPlayerInWar(tag: string, clanTag: string): boolean;
  getAttacksDoneByPlayer(tag: string, clanTag: string): number;
}
interface ClanWarStateLike {
  warCwl?: { warInfo?: TodoWarLike | null; isInCwl?: boolean };
}
export class TodoProgressMetric {
  constructor(
    readonly label: string,
    readonly done: number,
    readonly total: number,
    readonly progressDone = done,
    readonly progressTotal = total,
  ) {}
  get progressRatio() {
    return this.progressTotal === 0
      ? 1
      : Math.max(0, Math.min(1, this.progressDone / this.progressTotal));
  }
}
export function isInClanGamesWindow(now = new Date()) {
  const day = now.getUTCDate(),
    hour = now.getUTCHours();
  return (day === 22 && hour >= 8) || (day >= 23 && day <= 27) || (day === 28 && hour <= 8);
}
export function isInCwlWindow(now = new Date()) {
  const day = now.getUTCDate();
  return day >= 1 && day <= 12;
}
export function requiredSeasonPassPoints(now = new Date()) {
  const days = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  return Math.trunc((now.getDate() * 2600) / days);
}
export function requiredClanGamesPoints(now = new Date()) {
  const start = new Date(now.getFullYear(), now.getMonth(), 22, 8);
  return Math.trunc((Math.floor((now.getTime() - start.getTime()) / 86_400_000) * 4000) / 6);
}
function clanGamesDailyTarget(now = new Date()) {
  const start = new Date(now.getFullYear(), now.getMonth(), 22, 8);
  return 500 * (Math.floor((now.getTime() - start.getTime()) / 86_400_000) + 1);
}
function intString(value: unknown) {
  return typeof value === 'string'
    ? Number.parseInt(value.replaceAll(',', ''), 10) || 0
    : int(value);
}
function leagueName(value: unknown) {
  return string(record(value).name, 'Unranked');
}
function reduceOrNull<T>(items: T[], fn: (a: T, b: T) => T): T | null {
  if (items.length === 0) return null;
  let result: T = items[0]!;
  for (let index = 1; index < items.length; index += 1) result = fn(result, items[index]!);
  return result;
}
