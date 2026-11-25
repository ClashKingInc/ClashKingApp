import { canonicalTag } from '../../../core/domain/tags';
import type { StringStorage } from '../../../core/storage/storage';

export interface HomeStartupSnapshot {
  readonly userId: string;
  readonly tag: string;
  readonly name: string;
  readonly townHallLevel: number;
}

export interface HomeStartupPreview {
  readonly snapshot: HomeStartupSnapshot;
  readonly selectedReady: Promise<void>;
}

function storageKey(userId: string): string {
  return `home_startup_snapshot_v1:${encodeURIComponent(userId)}`;
}

export async function readHomeStartupSnapshot(
  storage: StringStorage,
  userId: string,
  selectedTag: string,
): Promise<HomeStartupSnapshot | null> {
  const tag = canonicalTag(selectedTag);
  if (!userId || !tag) return null;
  try {
    const raw = await storage.getString(storageKey(userId));
    if (!raw || raw.length > 1024) return null;
    const data = JSON.parse(raw) as Partial<HomeStartupSnapshot> | null;
    if (
      data?.tag !== tag ||
      typeof data.name !== 'string' ||
      !data.name.trim() ||
      data.name.length > 100 ||
      typeof data.townHallLevel !== 'number' ||
      !Number.isInteger(data.townHallLevel) ||
      data.townHallLevel < 1
    ) return null;
    return { userId, tag, name: data.name, townHallLevel: data.townHallLevel };
  } catch {
    return null;
  }
}

export async function saveHomeStartupSnapshot(
  storage: StringStorage,
  snapshot: HomeStartupSnapshot,
): Promise<void> {
  const { userId, tag, name, townHallLevel } = snapshot;
  if (
    !userId || !canonicalTag(tag) || !name.trim() || name.length > 100 ||
    !Number.isInteger(townHallLevel) || townHallLevel < 1
  ) return;
  try {
    await storage.setString(
      storageKey(userId),
      JSON.stringify({ tag: canonicalTag(tag), name, townHallLevel }),
    );
  } catch {
    // The preview is optional when local storage is unavailable.
  }
}
