import {
  BookmarksAddEndpoint,
  BookmarksDeleteEndpoint,
  BookmarksListEndpoint,
  BookmarksOrderEndpoint,
} from '@clashking/api-contracts/expo';
import { ApiResponseError, ResponseDecodeError } from '@clashking/api-client';
import { Effect } from 'effect';

import { UnauthorizedException, type ContractApiService } from '../api/contract-api';
import type { Clan } from '../../features/clan/models';
import type { Player } from '../../features/player/models/player';

export type BookmarkType = 'player' | 'clan';
export type BookmarkListener = () => void;

export class BookmarkHttpException extends Error {
  constructor(
    readonly status: number,
    readonly action: 'load' | 'create' | 'delete' | 'reorder',
    readonly url: string,
  ) {
    super(
      action === 'load'
        ? `Failed to load bookmarks (${status})`
        : `Failed to ${action} bookmark (${status})`,
    );
    this.name = 'BookmarkHttpException';
  }
}

export class BookmarkFormatException extends Error {
  constructor() {
    super('Invalid bookmarks payload');
    this.name = 'BookmarkFormatException';
  }
}

export class BookmarkedPlayer {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly townHallLevel: number,
    readonly townHallPic: string,
    readonly clanTag: string,
    readonly clanName: string,
    readonly trophies: number,
    readonly league: string,
    readonly leagueUrl: string,
  ) {}

  static fromPlayer(player: Player): BookmarkedPlayer {
    const linkedClan = isRecord(player.clan) ? player.clan : null;
    return new BookmarkedPlayer(
      player.tag,
      player.name,
      player.townHallLevel,
      player.townHallPic,
      player.clanTag,
      typeof linkedClan?.name === 'string' ? linkedClan.name : player.clanOverview.name,
      player.trophies,
      player.league,
      player.leagueUrl,
    );
  }

  static fromApiJson(json: Record<string, unknown>): BookmarkedPlayer {
    const tag = String(json.player_tag ?? json.tag ?? '');
    return new BookmarkedPlayer(tag, tag.length ? tag : 'Unknown Player', 0, '', '', '', 0, '', '');
  }
}

export class BookmarkedClan {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly badgeUrl: string,
    readonly clanLevel: number,
    readonly memberCount: number,
  ) {}

  static fromClan(clan: Clan): BookmarkedClan {
    return new BookmarkedClan(
      clan.tag,
      clan.name,
      clan.badgeUrls.smallest,
      clan.clanLevel,
      clan.members,
    );
  }

  static fromApiJson(json: Record<string, unknown>): BookmarkedClan {
    const tag = String(json.clan_tag ?? json.tag ?? '');
    return new BookmarkedClan(tag, tag.length ? tag : 'Unknown Clan', '', 0, 0);
  }
}

export class BookmarkService {
  private hasLoaded = false;
  private loadGeneration = 0;
  private currentUserId: string | null = null;
  private playerBookmarks: BookmarkedPlayer[] = [];
  private clanBookmarks: BookmarkedClan[] = [];
  private readonly listeners = new Set<BookmarkListener>();
  private disposed = false;

  constructor(private readonly api: ContractApiService) {}

  get loaded(): boolean {
    return this.hasLoaded;
  }

  get players(): readonly BookmarkedPlayer[] {
    return Object.freeze([...this.playerBookmarks]);
  }

  get clans(): readonly BookmarkedClan[] {
    return Object.freeze([...this.clanBookmarks]);
  }

  subscribe(listener: BookmarkListener): () => void {
    if (this.disposed) return () => undefined;
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  dispose(): void {
    this.disposed = true;
    this.listeners.clear();
  }

  setCurrentUserId(userId: string | null | undefined): void {
    const normalized = userId?.trim() ?? '';
    const nextUserId = normalized.length ? normalized : null;
    if (this.currentUserId === nextUserId) return;
    this.currentUserId = nextUserId;
    this.loadGeneration += 1;
    this.hasLoaded = false;
  }

  async load(): Promise<void> {
    const generation = ++this.loadGeneration;
    if (!this.hasCurrentUser) {
      if (generation !== this.loadGeneration) return;
      this.playerBookmarks = [];
      this.clanBookmarks = [];
      this.hasLoaded = false;
      return;
    }

    const [playerResponse, clanResponse] = await Promise.all([
      this.listBookmarks('player'),
      this.listBookmarks('clan'),
    ]);
    const players = this.decodeBookmarkItems(playerResponse).map(BookmarkedPlayer.fromApiJson);
    const clans = this.decodeBookmarkItems(clanResponse).map(BookmarkedClan.fromApiJson);
    if (generation !== this.loadGeneration) return;
    this.playerBookmarks = players;
    this.clanBookmarks = clans;
    this.hasLoaded = true;
    this.notify();
  }

  isPlayerBookmarked(tag: string): boolean {
    return this.playerBookmarks.some((player) => player.tag === tag);
  }

  isClanBookmarked(tag: string): boolean {
    return this.clanBookmarks.some((clan) => clan.tag === tag);
  }

  async togglePlayer(player: Player): Promise<void> {
    if (this.isPlayerBookmarked(player.tag)) await this.removePlayer(player.tag);
    else await this.addPlayer(BookmarkedPlayer.fromPlayer(player));
  }

  async addPlayer(player: BookmarkedPlayer): Promise<void> {
    const previous = [...this.playerBookmarks];
    this.playerBookmarks = [
      player,
      ...this.playerBookmarks.filter((item) => item.tag !== player.tag),
    ];
    this.notify();
    try {
      this.requireCurrentUser();
      await this.createBookmark('player', player.tag);
    } catch (error) {
      this.playerBookmarks = previous;
      this.notify();
      throw error;
    }
  }

  async removePlayer(tag: string): Promise<void> {
    const previous = [...this.playerBookmarks];
    this.playerBookmarks = this.playerBookmarks.filter((player) => player.tag !== tag);
    this.notify();
    try {
      this.requireCurrentUser();
      await this.deleteBookmark('player', tag);
    } catch (error) {
      this.playerBookmarks = previous;
      this.notify();
      throw error;
    }
  }

  async reorderPlayer(oldIndex: number, newIndex: number): Promise<void> {
    if (oldIndex < 0 || oldIndex >= this.playerBookmarks.length) return;
    if (newIndex < 0 || newIndex > this.playerBookmarks.length) return;
    const previous = [...this.playerBookmarks];
    const reordered = [...this.playerBookmarks];
    const [player] = reordered.splice(oldIndex, 1);
    this.playerBookmarks = reordered;
    if (newIndex > reordered.length) {
      // Flutter removes first and then List.insert throws outside its rollback
      // block for an original-length destination index.
      throw new RangeError('newIndex is outside the post-removal list.');
    }
    reordered.splice(newIndex, 0, player!);
    this.notify();
    try {
      this.requireCurrentUser();
      await this.saveBookmarkOrder(
        'player',
        reordered.map((item) => item.tag),
      );
    } catch (error) {
      this.playerBookmarks = previous;
      this.notify();
      throw error;
    }
  }

  async reorderPlayers(orderedTags: readonly string[]): Promise<void> {
    const normalized = orderedTags.map((tag) => tag.trim().toUpperCase());
    if (new Set(normalized).size !== normalized.length) {
      throw new RangeError('Player bookmark order contains duplicate tags.');
    }
    const requested = new Map(
      this.playerBookmarks.map((player) => [player.tag.trim().toUpperCase(), player]),
    );
    const visibleOrder = normalized.flatMap((tag) => {
      const player = requested.get(tag);
      return player ? [player] : [];
    });
    const visibleTags = new Set(visibleOrder.map((player) => player.tag.trim().toUpperCase()));
    let visibleIndex = 0;
    const reordered = this.playerBookmarks.map((player) =>
      visibleTags.has(player.tag.trim().toUpperCase()) ? visibleOrder[visibleIndex++]! : player,
    );
    if (reordered.every((player, index) => player === this.playerBookmarks[index])) return;

    const previous = [...this.playerBookmarks];
    this.playerBookmarks = reordered;
    this.notify();
    try {
      this.requireCurrentUser();
      await this.saveBookmarkOrder(
        'player',
        reordered.map((player) => player.tag),
      );
    } catch (error) {
      this.playerBookmarks = previous;
      this.notify();
      throw error;
    }
  }

  async toggleClan(clan: Clan): Promise<void> {
    if (this.isClanBookmarked(clan.tag)) await this.removeClan(clan.tag);
    else await this.addClan(BookmarkedClan.fromClan(clan));
  }

  async addClan(clan: BookmarkedClan): Promise<void> {
    const previous = [...this.clanBookmarks];
    this.clanBookmarks = [clan, ...this.clanBookmarks.filter((item) => item.tag !== clan.tag)];
    this.notify();
    try {
      this.requireCurrentUser();
      await this.createBookmark('clan', clan.tag);
    } catch (error) {
      this.clanBookmarks = previous;
      this.notify();
      throw error;
    }
  }

  async removeClan(tag: string): Promise<void> {
    const previous = [...this.clanBookmarks];
    this.clanBookmarks = this.clanBookmarks.filter((clan) => clan.tag !== tag);
    this.notify();
    try {
      this.requireCurrentUser();
      await this.deleteBookmark('clan', tag);
    } catch (error) {
      this.clanBookmarks = previous;
      this.notify();
      throw error;
    }
  }

  async reorderClan(oldIndex: number, newIndex: number): Promise<void> {
    if (oldIndex < 0 || oldIndex >= this.clanBookmarks.length) return;
    if (newIndex < 0 || newIndex > this.clanBookmarks.length) return;
    const previous = [...this.clanBookmarks];
    const reordered = [...this.clanBookmarks];
    const [clan] = reordered.splice(oldIndex, 1);
    this.clanBookmarks = reordered;
    if (newIndex > reordered.length) {
      throw new RangeError('newIndex is outside the post-removal list.');
    }
    reordered.splice(newIndex, 0, clan!);
    this.notify();
    try {
      this.requireCurrentUser();
      await this.saveBookmarkOrder(
        'clan',
        reordered.map((item) => item.tag),
      );
    } catch (error) {
      this.clanBookmarks = previous;
      this.notify();
      throw error;
    }
  }

  private get hasCurrentUser(): boolean {
    return this.currentUserId !== null && this.currentUserId.length > 0;
  }

  private requireCurrentUser(): string {
    if (!this.hasCurrentUser) throw new UnauthorizedException('User not authenticated');
    return this.currentUserId!;
  }

  private decodeBookmarkItems(response: Awaited<ReturnType<typeof this.listBookmarks>>): readonly Record<string, unknown>[] {
    if (!response.ok) return [];
    return response.value.items;
  }

  private async createBookmark(type: BookmarkType, tag: string): Promise<void> {
    const userId = this.requireCurrentUser();
    await this.bookmarkRequest(
      Effect.runPromise(this.api.execute(BookmarksAddEndpoint, { path: { userId }, query: {}, body: { type, tag } })),
      'create',
      BookmarksAddEndpoint.path,
    );
  }

  private async deleteBookmark(type: BookmarkType, tag: string): Promise<void> {
    const userId = this.requireCurrentUser();
    const response = await this.bookmarkRequest(
      Effect.runPromise(this.api.executeStatus(BookmarksDeleteEndpoint, { path: { userId, type, tag }, query: {}, body: {} })),
      'delete',
      BookmarksDeleteEndpoint.path,
    );
    if (!response.ok) throw new BookmarkHttpException(response.status, 'delete', BookmarksDeleteEndpoint.path);
  }

  private async saveBookmarkOrder(type: BookmarkType, tags: readonly string[]): Promise<void> {
    const userId = this.requireCurrentUser();
    await this.bookmarkRequest(
      Effect.runPromise(this.api.execute(BookmarksOrderEndpoint, { path: { userId }, query: {}, body: { type, ordered_tags: [...tags] } })),
      'reorder',
      BookmarksOrderEndpoint.path,
    );
  }

  private listBookmarks(type: BookmarkType) {
    const userId = this.requireCurrentUser();
    return this.bookmarkRequest(
      Effect.runPromise(this.api.executeStatus(BookmarksListEndpoint, { path: { userId }, query: { type }, body: {} })),
      'load',
      BookmarksListEndpoint.path,
    );
  }

  private async bookmarkRequest<T>(
    request: Promise<T>,
    action: 'load' | 'create' | 'delete' | 'reorder',
    path: string,
  ): Promise<T> {
    try {
      return await request;
    } catch (error) {
      if (error instanceof ResponseDecodeError) throw new BookmarkFormatException();
      if (error instanceof ApiResponseError) {
        throw new BookmarkHttpException(error.status, action, path);
      }
      throw error;
    }
  }

  private notify(): void {
    if (!this.disposed) for (const listener of this.listeners) listener();
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
