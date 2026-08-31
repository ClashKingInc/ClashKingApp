import { ResponseFormatException, type ApiClient } from '../../../core/api/client';
import {
  ACHIEVEMENT_CATALOG_FALLBACK,
  isAchievementId,
  type Achievement,
  type AchievementId,
} from '../models';

export interface AchievementsSnapshot {
  readonly achievements: readonly Achievement[];
  readonly isRefreshing: boolean;
}

type Listener = (snapshot: AchievementsSnapshot) => void;

export class AchievementsRepository {
  private snapshotValue: AchievementsSnapshot = Object.freeze({
    achievements: Object.freeze([]),
    isRefreshing: false,
  });
  private readonly listeners = new Set<Listener>();
  private sessionGeneration = 0;
  private sessionUserId: string | null = null;

  constructor(private readonly api: Pick<ApiClient, 'requestRecord'>) {}

  get snapshot(): AchievementsSnapshot {
    return this.snapshotValue;
  }

  subscribe(listener: Listener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  bindSession(userId: string | null): void {
    if (userId === this.sessionUserId) return;
    this.sessionUserId = userId;
    this.clear();
  }

  clear(): void {
    this.sessionGeneration += 1;
    this.setSnapshot([], false);
  }

  async load(): Promise<void> {
    const generation = this.sessionGeneration;
    const response = await this.fetchCatalog();
    if (generation !== this.sessionGeneration) return;
    this.replaceFromResponse(response);
  }

  async check(): Promise<void> {
    if (this.snapshotValue.isRefreshing) return;
    const generation = this.sessionGeneration;
    this.setSnapshot(this.snapshotValue.achievements, true);
    try {
      const response = await this.fetchCatalog();
      if (generation !== this.sessionGeneration) return;
      this.replaceFromResponse(response, true);
    } finally {
      if (generation === this.sessionGeneration) {
        this.setSnapshot(this.snapshotValue.achievements, false);
      }
    }
  }

  private fetchCatalog(): Promise<Record<string, unknown>> {
    return this.api.requestRecord('/achievements/check', {
      method: 'POST',
      body: {},
      requiresAuth: true,
    });
  }

  private replaceFromResponse(response: Record<string, unknown>, preserveRefreshing = false): void {
    if (!Array.isArray(response.items)) {
      throw new ResponseFormatException('Achievement response is missing items.');
    }
    const remoteById = new Map<AchievementId, Achievement>();
    for (const rawItem of response.items) {
      if (!isRecord(rawItem)) continue;
      const id = typeof rawItem.id === 'string' ? rawItem.id : '';
      const modelUrl = rawItem.asset_url;
      const earnedCount = rawItem.earned_count;
      const repeatable = rawItem.repeatable;
      if (
        !isAchievementId(id) ||
        typeof modelUrl !== 'string' ||
        modelUrl.length === 0 ||
        typeof earnedCount !== 'number' ||
        !Number.isFinite(earnedCount) ||
        typeof repeatable !== 'boolean'
      ) {
        continue;
      }
      remoteById.set(id, {
        id,
        modelUrl,
        earnedCount: Math.min(2 ** 31, Math.max(0, Math.trunc(earnedCount))),
        isRepeatable: repeatable,
      });
    }
    const achievements = ACHIEVEMENT_CATALOG_FALLBACK.flatMap((catalogItem) => {
      const remote = remoteById.get(catalogItem.id);
      return remote ? [remote] : [];
    });
    this.setSnapshot(achievements, preserveRefreshing && this.snapshotValue.isRefreshing);
  }

  private setSnapshot(achievements: readonly Achievement[], isRefreshing: boolean): void {
    this.snapshotValue = Object.freeze({
      achievements: Object.freeze([...achievements]),
      isRefreshing,
    });
    this.listeners.forEach((listener) => listener(this.snapshotValue));
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
