import { ImageAssets } from '../../../core/assets/image-assets';
import { gameDataState } from '../../../core/game-data/game-data-state';
import {
  RankingAudience,
  RankingBoard,
  rankingBoards,
  RankingLeagueOption,
  RankingLocation,
  RankingPeriod,
  RankingResult,
  RankingSource,
  type RankingAudienceValue,
  type RankingBoardValue,
  type RankingPeriodValue,
} from '../models';
import { RankingsRequestException, type RankingsServiceContract } from './rankings-service';

export class RankingsProvider {
  readonly leagueOptions: readonly RankingLeagueOption[];
  audience: RankingAudienceValue = RankingAudience.players;
  playerBoard: RankingBoardValue = RankingBoard.playerHome;
  clanBoard: RankingBoardValue = RankingBoard.clanHome;
  period: RankingPeriodValue = RankingPeriod.current;
  location = RankingLocation.worldwide();
  locations: readonly RankingLocation[] = [RankingLocation.worldwide()];
  selectedLeague: RankingLeagueOption;
  historyDate: Date;
  townHallLevel = 18;
  result: RankingResult | null = null;
  error: unknown = null;
  locationError: unknown = null;
  isLoading = false;
  isLoadingLocations = false;

  private requestGeneration = 0;
  private readonly listeners = new Set<() => void>();

  constructor(
    private readonly service: RankingsServiceContract,
    options: {
      readonly leagueOptions?: readonly RankingLeagueOption[];
      readonly clock?: () => Date;
    } = {},
  ) {
    this.leagueOptions = options.leagueOptions ?? rankingLeagueOptionsFromGameData();
    this.selectedLeague = this.leagueOptions[0] ?? RankingLeagueOption.legendTwo;
    const now = (options.clock ?? (() => new Date()))();
    this.historyDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
  }

  get board(): RankingBoardValue {
    return this.audience === RankingAudience.players ? this.playerBoard : this.clanBoard;
  }

  get boards(): readonly RankingBoardValue[] {
    return rankingBoards.filter((board) => board.audience === this.audience);
  }

  subscribe(listener: () => void): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  dispose(): void {
    this.requestGeneration += 1;
    this.listeners.clear();
  }

  async initialize(): Promise<void> {
    // Worldwide is the initial Flutter-compatible selection, so its leaderboard can load
    // immediately instead of waiting on the much larger location catalogue request.
    const initialRankings = this.reload();
    this.isLoadingLocations = true;
    this.locationError = null;
    this.notifyListeners();
    try {
      const fetchedLocations = await this.service.fetchLocations();
      this.locations = fetchedLocations.filter(
        (item) => item.isWorldwide || item.hasValidCountryCode,
      );
      if (this.locations.length === 0) this.locations = [RankingLocation.worldwide()];
      this.location =
        this.locations.find((item) => item.isWorldwide) ??
        this.locations[0] ??
        RankingLocation.worldwide();
    } catch (error) {
      this.locationError = error;
    } finally {
      this.isLoadingLocations = false;
      this.notifyListeners();
    }
    await initialRankings;
  }

  async reload(): Promise<void> {
    const selectedBoard = this.board;
    if (
      selectedBoard.supportsLocation &&
      !selectedBoard.supportsWorldwide &&
      this.location.isWorldwide
    ) {
      const replacement = this.locations.find((item) => !item.isWorldwide);
      if (replacement === undefined) {
        this.result = emptyResultFor(selectedBoard);
        this.error = null;
        this.notifyListeners();
        return;
      }
      this.location = replacement;
    }

    const generation = ++this.requestGeneration;
    this.isLoading = true;
    this.error = null;
    this.notifyListeners();
    try {
      const result = await this.service.fetchRankings({
        board: selectedBoard,
        location: this.location,
        period: this.period,
        historyDate: this.historyDate,
        townHallLevel: this.townHallLevel,
        leagueTier: this.selectedLeague,
      });
      if (generation !== this.requestGeneration) return;
      this.result = result;
    } catch (error) {
      if (generation !== this.requestGeneration) return;
      if (isNoDataException(error)) {
        this.result = emptyResultFor(selectedBoard);
        this.error = null;
      } else {
        this.result = null;
        this.error = error;
      }
    } finally {
      if (generation === this.requestGeneration) {
        this.isLoading = false;
        this.notifyListeners();
      }
    }
  }

  async selectAudience(value: RankingAudienceValue): Promise<void> {
    if (this.audience === value) return;
    const matchingBoard = matchingBoardForAudience(this.board, value);
    if (value === RankingAudience.players) this.playerBoard = matchingBoard;
    else this.clanBoard = matchingBoard;
    this.audience = value;
    this.period = RankingPeriod.current;
    this.notifyListeners();
    await this.reload();
  }

  async selectBoard(value: RankingBoardValue): Promise<void> {
    if (value.audience !== this.audience || this.board === value) return;
    if (this.audience === RankingAudience.players) this.playerBoard = value;
    else this.clanBoard = value;
    if (!value.supportsHistory) this.period = RankingPeriod.current;
    this.notifyListeners();
    await this.reload();
  }

  async selectLocation(value: RankingLocation): Promise<void> {
    if (this.location.equals(value) || (value.isWorldwide && !this.board.supportsWorldwide)) return;
    this.location = value;
    this.notifyListeners();
    await this.reload();
  }

  async selectPeriod(value: RankingPeriodValue): Promise<void> {
    if (this.period === value || (value === RankingPeriod.history && !this.board.supportsHistory)) {
      return;
    }
    this.period = value;
    this.notifyListeners();
    await this.reload();
  }

  async selectHistoryDate(value: Date): Promise<void> {
    const normalized = new Date(value.getFullYear(), value.getMonth(), value.getDate());
    if (this.historyDate.getTime() === normalized.getTime()) return;
    this.historyDate = normalized;
    this.notifyListeners();
    await this.reload();
  }

  async selectTownHall(value: number): Promise<void> {
    if (this.townHallLevel === value) return;
    this.townHallLevel = value;
    this.notifyListeners();
    await this.reload();
  }

  async selectLeague(value: RankingLeagueOption): Promise<void> {
    if (this.selectedLeague.id === value.id) return;
    this.selectedLeague = value;
    this.notifyListeners();
    await this.reload();
  }

  private notifyListeners(): void {
    for (const listener of this.listeners) listener();
  }
}

export function rankingLeagueOptionsFromGameData(): readonly RankingLeagueOption[] {
  const rawLeagues = gameDataState.playerLeagueData.leagues;
  if (!isRecord(rawLeagues)) return defaultLeagueOptions();

  const optionsById = new Map<number, RankingLeagueOption>();
  for (const [key, raw] of Object.entries(rawLeagues)) {
    if (!isRecord(raw)) continue;
    const id = intValue(raw._id ?? raw.id);
    if (id === null || id < 105000000 || id === RankingLeagueOption.legendOne.id) continue;
    const rawName = String(raw.name ?? key).trim();
    const name =
      id === 105000035 ? 'Legend League 2' : id === 105000034 ? 'Legend League 3' : rawName;
    if (name.length === 0) continue;
    optionsById.set(id, new RankingLeagueOption(id, name, ImageAssets.getLeagueImage(name)));
  }
  const options = [...optionsById.values()].sort((a, b) => b.id - a.id);
  return options.length === 0 ? defaultLeagueOptions() : options;
}

function defaultLeagueOptions(): readonly RankingLeagueOption[] {
  return [RankingLeagueOption.legendTwo, RankingLeagueOption.legendThree];
}

function emptyResultFor(board: RankingBoardValue): RankingResult {
  return new RankingResult([], board.source, board.source === RankingSource.official ? 200 : 500);
}

function matchingBoardForAudience(
  board: RankingBoardValue,
  audience: RankingAudienceValue,
): RankingBoardValue {
  if (audience === RankingAudience.players) {
    return board === RankingBoard.clanBuilder
      ? RankingBoard.playerBuilder
      : RankingBoard.playerHome;
  }
  return board === RankingBoard.playerBuilder ? RankingBoard.clanBuilder : RankingBoard.clanHome;
}

function isNoDataException(error: unknown): boolean {
  if (error instanceof RankingsRequestException && error.isNoData) return true;
  const message = String(error).toLowerCase();
  return (
    message.includes('no data') ||
    message.includes('no ranking') ||
    message.includes('not found') ||
    message.includes('404')
  );
}

function intValue(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  const text = String(value ?? '');
  if (!/^[+-]?\d+$/.test(text)) return null;
  return Number.parseInt(text, 10);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
