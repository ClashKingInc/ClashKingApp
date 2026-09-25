import type { StringStore } from '../../services/storage/auth-storage';
import type { Player } from '../player/models';
import { currentLegendDay, type PlayerLegendLeagueData } from '../player/models/player-legend';
import type { NativeWidgetBridge, WidgetPlatform } from './contracts';
import {
  buildLegendsWidgetPayload,
  canonicalPlayerTag,
  type LegendsWidgetPayload,
  type LegendsWidgetPlayer,
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
  readonly loadLegendData: (tag: string, day: string) => Promise<PlayerLegendLeagueData>;
  readonly t: LegendsWidgetTranslate;
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

  constructor(private readonly options: LegendsWidgetServiceOptions) {}

  async syncBookmarkedPlayers(bookmarks: readonly LegendsWidgetBookmark[]): Promise<void> {
    if (this.options.platform === 'web') return;
    const generation = ++this.generation;
    try {
      const previous = await this.getCachedPlayers();
      const next = normalizeBookmarks(bookmarks, previous);
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
          return [{
            tag: String(value.tag ?? ''),
            name: String(value.name ?? ''),
            townHallLevel: finiteInteger(value.townHallLevel),
          }];
        }),
      );
    } catch (error) {
      await this.report({ operation: 'legends_widget.refresh', error });
      return [];
    }
  }

  async clear(): Promise<void> {
    if (this.options.platform === 'web') return;
    const generation = ++this.generation;
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
        const [playerResult, legendResult] = await Promise.allSettled([
          this.options.loadPlayer(tag),
          this.options.loadLegendData(tag, day),
        ]);
        if (generation !== this.generation) return;
        if (legendResult.status === 'rejected') throw legendResult.reason;
        if (!legendResult.value.currentDay && !legendResult.value.currentRank) {
          throw new Error('Legend refresh returned neither current day nor rank data');
        }
        const previousPayload = await this.readPayload(tag);
        const player = playerResult.status === 'fulfilled'
          ? playerResult.value
          : fallbackPlayer(bookmark, previousPayload);
        if (playerResult.status === 'rejected') {
          await this.report({ operation: 'legends_widget.player', error: playerResult.reason, tag });
        }
        const payload = buildLegendsWidgetPayload(player, legendResult.value, this.options.t, now);
        hydrated.set(tag, {
          tag,
          name: player.name,
          townHallLevel: player.townHallLevel,
        });
        await this.writeValue(generation, legendsWidgetKeyForPlayer(tag), JSON.stringify(payload));
      } catch (error) {
        await this.report({ operation: 'legends_widget.player', error, tag });
      }
    });
    return players.map((player) => hydrated.get(canonicalPlayerTag(player.tag)) ?? player);
  }

  private async writePlayers(
    generation: number,
    players: readonly LegendsWidgetBookmark[],
  ): Promise<void> {
    await this.writeValue(generation, LEGENDS_WIDGET_PLAYERS_KEY, JSON.stringify(players));
  }

  private async writeValue(
    generation: number,
    key: string,
    value: string | null,
  ): Promise<void> {
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

  private async readPayload(tag: string): Promise<LegendsWidgetPayload | null> {
    try {
      const raw = await this.options.mirror.getItem(legendsWidgetKeyForPlayer(tag));
      if (!raw) return null;
      const decoded: unknown = JSON.parse(raw);
      return isRecord(decoded) && decoded.schemaVersion === 1
        ? decoded as unknown as LegendsWidgetPayload
        : null;
    } catch {
      return null;
    }
  }

  private async report(context: LegendsWidgetErrorContext): Promise<void> {
    try {
      await this.options.reportError?.(context);
    } catch {
      // Reporting cannot change cache retention or widget refresh semantics.
    }
  }
}

function fallbackPlayer(
  bookmark: LegendsWidgetBookmark,
  previous: LegendsWidgetPayload | null,
): LegendsWidgetPlayer {
  const clan = previous?.clan;
  return {
    tag: canonicalPlayerTag(bookmark.tag),
    name: bookmark.name,
    townHallLevel: bookmark.townHallLevel,
    ...(clan
      ? {
          clanOverview: {
            tag: clan.tag,
            name: clan.name,
            clanLevel: 0,
            badgeUrls: { small: '', medium: clan.badgeUrl, large: '' },
          },
        }
      : undefined),
  };
}

function normalizeBookmarks(
  bookmarks: readonly LegendsWidgetBookmark[],
  fallbacks: readonly LegendsWidgetBookmark[] = [],
): LegendsWidgetBookmark[] {
  const fallbackByTag = new Map(fallbacks.map((item) => [canonicalPlayerTag(item.tag), item]));
  const normalized = new Map<string, LegendsWidgetBookmark>();
  for (const bookmark of bookmarks) {
    const tag = canonicalPlayerTag(bookmark.tag);
    if (!tag || normalized.has(tag)) continue;
    const fallback = fallbackByTag.get(tag);
    normalized.set(tag, {
      tag,
      name: bookmark.name || fallback?.name || tag,
      townHallLevel:
        bookmark.townHallLevel > 0 ? bookmark.townHallLevel : (fallback?.townHallLevel ?? 0),
    });
  }
  return [...normalized.values()];
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
