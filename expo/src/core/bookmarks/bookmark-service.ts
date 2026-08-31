import { UnauthorizedException, type ApiClient, type ApiResponse } from '../api/client';
import type { Clan } from '../../features/clan/models';
import type { Player } from '../../features/player/models/player';

const ALL_HTTP_STATUSES = Array.from({ length: 500 }, (_, index) => index + 100);

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

  constructor(private readonly api: ApiClient) {}

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

    const userId = encodeURIComponent(this.currentUserId!);
    const [playerResponse, clanResponse] = await Promise.all([
      this.request(`/links/${userId}/bookmarks?type=player`, 'GET'),
      this.request(`/links/${userId}/bookmarks?type=clan`, 'GET'),
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

  private requireCurrentUser(): void {
    if (!this.hasCurrentUser) throw new UnauthorizedException('User not authenticated');
  }

  private decodeBookmarkItems(response: ApiResponse): Record<string, unknown>[] {
    if (response.status === 404) return [];
    if (response.status < 200 || response.status >= 300) {
      throw new BookmarkHttpException(response.status, 'load', response.url);
    }
    let data: unknown;
    try {
      data = JSON.parse(response.bodyText) as unknown;
    } catch {
      throw new BookmarkFormatException();
    }
    if (!isRecord(data) || !Array.isArray(data.items)) throw new BookmarkFormatException();
    return data.items.filter(isRecord);
  }

  private async createBookmark(type: BookmarkType, tag: string): Promise<void> {
    const response = await this.request(this.bookmarksEndpoint(), 'POST', { type, tag });
    this.throwOnMutationFailure(response, 'create');
  }

  private async deleteBookmark(type: BookmarkType, tag: string): Promise<void> {
    const endpoint = `${this.bookmarksEndpoint()}/${type}/${encodeURIComponent(tag)}`;
    const response = await this.request(endpoint, 'DELETE');
    this.throwOnMutationFailure(response, 'delete');
  }

  private async saveBookmarkOrder(type: BookmarkType, tags: readonly string[]): Promise<void> {
    const response = await this.request(`${this.bookmarksEndpoint()}/order`, 'PUT', {
      type,
      ordered_tags: tags,
    });
    this.throwOnMutationFailure(response, 'reorder');
  }

  private bookmarksEndpoint(): string {
    return `/links/${encodeURIComponent(this.currentUserId ?? '')}/bookmarks`;
  }

  private request(
    endpoint: string,
    method: 'GET' | 'POST' | 'PUT' | 'DELETE',
    body?: unknown,
  ): Promise<ApiResponse> {
    return this.api.request(endpoint, {
      method,
      body,
      requiresAuth: true,
      acceptedStatuses: ALL_HTTP_STATUSES,
    });
  }

  private throwOnMutationFailure(
    response: ApiResponse,
    action: 'create' | 'delete' | 'reorder',
  ): void {
    if (response.status >= 200 && response.status < 300) return;
    throw new BookmarkHttpException(response.status, action, response.url);
  }

  private notify(): void {
    if (!this.disposed) for (const listener of this.listeners) listener();
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
