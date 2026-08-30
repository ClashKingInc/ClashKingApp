export const SUPPORTED_GAME_ASSET_EXTENSIONS = Object.freeze(
  new Set(['gif', 'jpeg', 'jpg', 'png', 'svg', 'webp']),
);

export class GameAssetManifest {
  readonly version: number;
  readonly assets: readonly GameAsset[];
  readonly categories: readonly GameAssetCategory[];

  constructor(version: number, assets: Iterable<GameAsset>) {
    this.version = version;
    this.assets = Object.freeze(
      [...assets].sort((left, right) => naturalCompare(left.path, right.path)),
    );
    this.categories = Object.freeze(buildCategories(this.assets));
  }

  static fromJson(value: unknown): GameAssetManifest {
    if (!isRecord(value)) throw new TypeError('Game asset manifest must be an object');
    if (value.version !== 1) {
      throw new TypeError(`Unsupported game asset manifest version: ${String(value.version)}`);
    }
    if (!Array.isArray(value.assets)) {
      throw new TypeError('Game asset manifest assets must be a list');
    }
    return new GameAssetManifest(
      1,
      value.assets.map((asset, index) => {
        if (!isRecord(asset)) throw new TypeError(`Game asset at index ${index} must be an object`);
        return GameAsset.fromJson(asset);
      }),
    );
  }
}

export class GameAsset {
  readonly path: string;
  readonly category: string;
  readonly displayName: string;
  readonly extension: string;
  readonly url: string;
  private readonly searchText: string;

  constructor(input: {
    path: string;
    category: string;
    displayName: string;
    extension: string;
    url: string;
  }) {
    this.path = input.path;
    this.category = input.category;
    this.displayName = input.displayName;
    this.extension = input.extension;
    this.url = input.url;
    this.searchText = `${input.path} ${input.displayName}`.toLowerCase();
  }

  static fromJson(json: Record<string, unknown>): GameAsset {
    const path = requiredString(json, 'path');
    const category = requiredString(json, 'category');
    const displayName = requiredString(json, 'display_name');
    const extension = requiredString(json, 'extension').toLowerCase();
    const url = requiredString(json, 'url');
    if (!SUPPORTED_GAME_ASSET_EXTENSIONS.has(extension)) {
      throw new TypeError(`Unsupported game asset extension: ${extension}`);
    }
    if (path.startsWith('bot/')) throw new TypeError('The bot asset folder is not supported');
    const segments = path.split('/');
    if (segments.length < 2 || segments[0] !== category) {
      throw new TypeError(`Game asset category does not match its path: ${category} / ${path}`);
    }
    if (!path.toLowerCase().endsWith(`.${extension}`)) {
      throw new TypeError(`Game asset extension does not match its path: ${path}`);
    }
    let parsed: URL;
    try {
      parsed = new URL(url);
    } catch {
      throw new TypeError(`Invalid game asset URL: ${url}`);
    }
    if (!['http:', 'https:'].includes(parsed.protocol) || !parsed.host) {
      throw new TypeError(`Invalid game asset URL: ${url}`);
    }
    return new GameAsset({ path, category, displayName, extension, url });
  }

  get fileName(): string {
    const segment = new URL(this.url).pathname.split('/').at(-1) ?? '';
    return decodeURIComponent(segment);
  }

  get tileDisplayName(): string {
    if (this.category !== 'buildings') return this.displayName;
    const segments = this.path.split('/');
    if (segments.length < 4) return this.displayName;
    return `${formatGameAssetCategory(segments.at(-2)!)} · ${formatGameAssetCategory(this.displayName)}`;
  }

  matches(query: string): boolean {
    const normalized = query.trim().toLowerCase();
    return !normalized || this.searchText.includes(normalized);
  }
}

export class GameAssetCategory {
  readonly id: string;
  readonly assets: readonly GameAsset[];

  constructor(id: string, assets: Iterable<GameAsset>) {
    this.id = id;
    this.assets = Object.freeze([...assets]);
  }

  get count(): number {
    return this.assets.length;
  }

  get representativeAsset(): GameAsset {
    return this.assets.find((asset) => asset.extension !== 'svg') ?? this.assets[0]!;
  }

  get extensions(): readonly string[] {
    return Object.freeze(
      [...new Set(this.assets.map((asset) => asset.extension))].sort((left, right) =>
        left.localeCompare(right),
      ),
    );
  }
}

export function filterGameAssets(
  assets: Iterable<GameAsset>,
  options: { query?: string; extension?: string } = {},
): readonly GameAsset[] {
  const query = options.query ?? '';
  const extension = options.extension ?? '';
  return [...assets].filter(
    (asset) => (!extension || asset.extension === extension) && asset.matches(query),
  );
}

export function formatGameAssetCategory(category: string): string {
  return category
    .split(/[-_]+/)
    .filter(Boolean)
    .map((word) =>
      word.length === 1 ? word.toUpperCase() : word[0]!.toUpperCase() + word.slice(1),
    )
    .join(' ');
}

export function naturalCompare(left: string, right: string): number {
  const leftParts = naturalParts(left);
  const rightParts = naturalParts(right);
  const length = Math.min(leftParts.length, rightParts.length);
  for (let index = 0; index < length; index += 1) {
    const leftPart = leftParts[index]!;
    const rightPart = rightParts[index]!;
    if (typeof leftPart === 'number' && typeof rightPart === 'number') {
      if (leftPart !== rightPart) return leftPart - rightPart;
    } else {
      const leftText = String(leftPart);
      const rightText = String(rightPart);
      if (leftText !== rightText) return leftText < rightText ? -1 : 1;
    }
  }
  return leftParts.length - rightParts.length;
}

function buildCategories(assets: readonly GameAsset[]): GameAssetCategory[] {
  const grouped = new Map<string, GameAsset[]>();
  for (const asset of assets) {
    const items = grouped.get(asset.category) ?? [];
    items.push(asset);
    grouped.set(asset.category, items);
  }
  return [...grouped.keys()]
    .sort((left, right) => left.localeCompare(right))
    .map((id) => new GameAssetCategory(id, grouped.get(id)!));
}

function naturalParts(value: string): readonly (number | string)[] {
  return (value.toLowerCase().match(/\d+|\D+/g) ?? []).map((part) =>
    /^\d+$/.test(part) ? Number(part) : part,
  );
}

function requiredString(json: Record<string, unknown>, key: string): string {
  const value = json[key];
  if (typeof value !== 'string' || !value.trim()) {
    throw new TypeError(`Game asset ${key} must be a non-empty string`);
  }
  return value;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
