import type { StringStore } from '../../services/storage/auth-storage';
import type { Player } from '../player/models';
import type { RankedLeagueData } from '../player/models/player-ranked';
import { currentLegendDay, type PlayerLegendLeagueData } from '../player/models/player-legend';
import type { NativeWidgetBridge, WidgetPlatform } from './contracts';
import {
  buildLegendsWidgetPayload,
  buildRankedWidgetPayload,
  canonicalPlayerTag,
  type LegendsWidgetTranslate,
} from './legends-widget-payload';

export const LEGENDS_WIDGET_PLAYERS_KEY = 'legendsWidgetPlayers';

export interface LegendsWidgetBookmark {
  readonly tag: string;
  readonly name: string;
  readonly townHallLevel: number;
}

export interface LegendsWidgetErrorContext {
  readonly operation: 'legends_widget.sync' | 'legends_widget.refresh' | 'legends_widget.player';
  readonly error: unknown;
  readonly tag?: string;
}

export interface LegendsWidgetServiceOptions {
  readonly platform: WidgetPlatform;
  readonly native: Pick<NativeWidgetBridge, 'setWidgetValue' | 'reloadWidgets'>;
  readonly mirror: StringStore;
  readonly loadPlayer: (tag: string) => Promise<Player>;
  readonly cachedPlayer?: (tag: string) => Pick<Player, 'name' | 'townHallLevel'> | null;
  readonly eligiblePlayers?: () => readonly LegendsWidgetBookmark[];
  readonly loadLegendData: (tag: string, day: string) => Promise<PlayerLegendLeagueData>;
  readonly loadRankedData: (tag: string) => Promise<RankedLeagueData>;
  readonly t: LegendsWidgetTranslate;
  readonly locale?: () => string;
  readonly now?: () => Date;
  readonly concurrency?: number;
  readonly reportError?: (context: LegendsWidgetErrorContext) => void | Promise<void>;
}

export function legendsWidgetKeyForPlayer(tag: string): string {
  return `legendsWidget_${canonicalPlayerTag(tag).slice(1)}`;
}

export class LegendsWidgetService {
  private generation = 0;
  private writeChain: Promise<void> = Promise.resolve();
  private readonly legendLoads = new Map<string, Promise<PlayerLegendLeagueData>>();
  private readonly legendCache = new Map<string, { value: PlayerLegendLeagueData; at: number }>();

  constructor(private readonly options: LegendsWidgetServiceOptions) {}

  async syncBookmarkedPlayers(bookmarks: readonly LegendsWidgetBookmark[]): Promise<void> {
    if (this.options.platform === 'web') return;
    const generation = ++this.generation;
    try {
      const previous = await this.getCachedPlayers();
      const next = normalizeBookmarks(
        this.options.eligiblePlayers?.() ?? bookmarks,
        previous,
        this.options.cachedPlayer,
      );
      const nextTags = new Set(next.map((player) => canonicalPlayerTag(player.tag)));
      for (const player of previous) {
        if (!nextTags.has(canonicalPlayerTag(player.tag))) {
          await this.writeValue(generation, legendsWidgetKeyForPlayer(player.tag), null);
        }
      }
      await this.writePlayers(generation, next);
      const hydrated = await this.refreshPlayers(generation, next);
      await this.writePlayers(generation, hydrated);
      if (generation === this.generation) await this.options.native.reloadWidgets();
    } catch (error) {
      await this.report({ operation: 'legends_widget.sync', error });
    }
  }

  async refreshCachedBookmarks(): Promise<void> {
    if (this.options.platform === 'web') return;
    // Reconcile ownership on every refresh, not just when the picker opens.
    // A stale bookmark cache must never reintroduce an unverified player on
    // either native platform; the shared picker and both widget types use it.
    if (this.options.eligiblePlayers) {
      await this.syncBookmarkedPlayers(this.options.eligiblePlayers());
      return;
    }
    const generation = ++this.generation;
    try {
      const cached = await this.getCachedPlayers();
      const hydrated = await this.refreshPlayers(generation, cached);
      await this.writePlayers(generation, hydrated);
      if (generation === this.generation) await this.options.native.reloadWidgets();
    } catch (error) {
      await this.report({ operation: 'legends_widget.refresh', error });
    }
  }

  async getCachedPlayers(): Promise<LegendsWidgetBookmark[]> {
    if (this.options.platform === 'web') return [];
    try {
      const raw = await this.options.mirror.getItem(LEGENDS_WIDGET_PLAYERS_KEY);
      if (!raw) return [];
      const decoded: unknown = JSON.parse(raw);
      if (!Array.isArray(decoded)) return [];
      return normalizeBookmarks(
        decoded.flatMap((value) => {
          if (!isRecord(value)) return [];
          return [
            {
              tag: String(value.tag ?? ''),
              name: String(value.name ?? ''),
              townHallLevel: finiteInteger(value.townHallLevel),
            },
          ];
        }),
        [],
        this.options.cachedPlayer,
      );
    } catch (error) {
      await this.report({ operation: 'legends_widget.refresh', error });
      return [];
    }
  }

  async clear(): Promise<void> {
    if (this.options.platform === 'web') return;
    const generation = ++this.generation;
    this.legendLoads.clear();
    this.legendCache.clear();
    const cached = await this.getCachedPlayers();
    for (const player of cached) {
      await this.writeValue(generation, legendsWidgetKeyForPlayer(player.tag), null);
    }
    await this.writePlayers(generation, []);
    if (generation === this.generation) await this.options.native.reloadWidgets();
  }

  private async refreshPlayers(
    generation: number,
    players: readonly LegendsWidgetBookmark[],
  ): Promise<LegendsWidgetBookmark[]> {
    const hydrated = new Map(players.map((player) => [canonicalPlayerTag(player.tag), player]));
    await mapWithConcurrency(players, this.options.concurrency ?? 3, async (bookmark) => {
      if (generation !== this.generation) return;
      const tag = canonicalPlayerTag(bookmark.tag);
      try {
        const now = this.now();
        const day = currentLegendDay(now);
        const player = await this.options.loadPlayer(tag);
        if (generation !== this.generation) return;
        hydrated.set(tag, {
          tag,
          name: player.name,
          townHallLevel: player.townHallLevel,
        });
        // Legend II/III use the weekly Ranked source, not the daily Legend I feed.
        if (!player.isLegendLeague) {
          const data = await this.options.loadRankedData(tag);
          if (generation !== this.generation) return;
          // Missing membership is not a zero-attack week. Retain the previous
          // snapshot as stale until the authoritative period can be refreshed.
          if (!data.currentGroup && !data.currentBattlelog)
            throw new Error('Ranked refresh returned no current period');
          const payload = buildRankedWidgetPayload(
            player,
            data,
            this.options.t,
            now,
            this.options.locale?.(),
          );
          await this.writeValue(
            generation,
            legendsWidgetKeyForPlayer(tag),
            JSON.stringify(payload),
          );
          return;
        }
        const data = await this.loadLegendData(tag, day);
        if (generation !== this.generation) return;
        if (!data.currentDay && !data.currentRank) {
          throw new Error('Legend refresh returned neither current day nor rank data');
        }
        const payload = buildLegendsWidgetPayload(player, data, this.options.t, now);
        await this.writeValue(generation, legendsWidgetKeyForPlayer(tag), JSON.stringify(payload));
      } catch (error) {
        await this.report({ operation: 'legends_widget.player', error, tag });
      }
    });
    return players.map((player) => hydrated.get(canonicalPlayerTag(player.tag)) ?? player);
  }

  private loadLegendData(tag: string, day: string): Promise<PlayerLegendLeagueData> {
    const key = `${tag}:${day}`;
    const pending = this.legendLoads.get(key);
    if (pending) return pending;
    const cached = this.legendCache.get(key);
    const age = cached ? this.now().getTime() - cached.at : Infinity;
    if (cached && age >= 0 && age < 60_000) return Promise.resolve(cached.value);
    const load = this.options
      .loadLegendData(tag, day)
      .then((value) => {
        if (this.legendLoads.get(key) === load) {
          if (this.legendCache.size >= 100)
            this.legendCache.delete(this.legendCache.keys().next().value!);
          this.legendCache.set(key, { value, at: this.now().getTime() });
        }
        return value;
      })
      .finally(() => {
        if (this.legendLoads.get(key) === load) this.legendLoads.delete(key);
      });
    this.legendLoads.set(key, load);
    return load;
  }

  private async writePlayers(
    generation: number,
    players: readonly LegendsWidgetBookmark[],
  ): Promise<void> {
    await this.writeValue(generation, LEGENDS_WIDGET_PLAYERS_KEY, JSON.stringify(players));
  }

  private async writeValue(generation: number, key: string, value: string | null): Promise<void> {
    const write = this.writeChain.then(async () => {
      if (generation !== this.generation) return;
      await this.options.native.setWidgetValue(key, value);
      if (value === null) await this.options.mirror.removeItem(key);
      else await this.options.mirror.setItem(key, value);
    });
    this.writeChain = write.catch(() => undefined);
    await write;
  }

  private now(): Date {
    return this.options.now?.() ?? new Date();
  }

  private async report(context: LegendsWidgetErrorContext): Promise<void> {
    try {
      await this.options.reportError?.(context);
    } catch {
      // Reporting cannot change cache retention or widget refresh semantics.
    }
  }
}

function normalizeBookmarks(
  bookmarks: readonly LegendsWidgetBookmark[],
  fallbacks: readonly LegendsWidgetBookmark[] = [],
  cachedPlayer?: (tag: string) => Pick<Player, 'name' | 'townHallLevel'> | null,
): LegendsWidgetBookmark[] {
  const fallbackByTag = new Map(fallbacks.map((item) => [canonicalPlayerTag(item.tag), item]));
  const normalized = new Map<string, LegendsWidgetBookmark>();
  for (const bookmark of bookmarks) {
    const tag = canonicalPlayerTag(bookmark.tag);
    if (!tag || normalized.has(tag)) continue;
    const fallback = fallbackByTag.get(tag);
    const profile = cachedPlayer?.(tag);
    normalized.set(tag, {
      tag,
      name:
        resolvedName(profile?.name, tag) ||
        resolvedName(bookmark.name, tag) ||
        resolvedName(fallback?.name, tag) ||
        tag,
      townHallLevel:
        profile && profile.townHallLevel > 0
          ? profile.townHallLevel
          : bookmark.townHallLevel > 0
            ? bookmark.townHallLevel
            : (fallback?.townHallLevel ?? 0),
    });
  }
  return [...normalized.values()];
}

function resolvedName(name: string | undefined, tag: string): string {
  const value = name?.trim() ?? '';
  return value && canonicalPlayerTag(value) !== tag ? value : '';
}

async function mapWithConcurrency<T>(
  values: readonly T[],
  requestedLimit: number,
  operation: (value: T) => Promise<void>,
): Promise<void> {
  const limit = Math.max(1, Math.min(values.length, Math.floor(requestedLimit) || 1));
  let cursor = 0;
  await Promise.all(
    Array.from({ length: limit }, async () => {
      while (cursor < values.length) {
        const value = values[cursor++];
        if (value !== undefined) await operation(value);
      }
    }),
  );
}

function finiteInteger(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? Math.trunc(value) : 0;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
