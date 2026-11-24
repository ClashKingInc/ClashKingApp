import { GameAssetManifest } from './models';

export interface GameAssetManifestRepository {
  load(options?: { forceRefresh?: boolean }): Promise<GameAssetManifest>;
  peek?(): GameAssetManifest | null;
}

/** Wiki projection of the manifest already owned and refreshed by GameDataService. */
export class GameAssetManifestService implements GameAssetManifestRepository {
  private source?: Record<string, unknown>;
  private manifest: GameAssetManifest | null = null;

  constructor(
    private readonly loadManifest: (refresh?: boolean) => Promise<Record<string, unknown>>,
  ) {}

  peek(): GameAssetManifest | null {
    return this.manifest;
  }

  async load({ forceRefresh = false } = {}): Promise<GameAssetManifest> {
    try {
      const source = await this.loadManifest(forceRefresh);
      if (source !== this.source || !this.manifest) {
        const manifest = GameAssetManifest.fromJson(source);
        this.source = source;
        this.manifest = manifest;
      }
      return this.manifest;
    } catch (error) {
      if (this.manifest) return this.manifest;
      throw error;
    }
  }
}
