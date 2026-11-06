import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Updates from 'expo-updates';
import type { ElementRef } from 'react';
import type { View } from 'react-native';
import { captureRef } from 'react-native-view-shot';

const KEY = 'startup_update_handoff';
let resuming = false;
let startupCover: ElementRef<typeof View> | null = null;

export function registerStartupCover(view: ElementRef<typeof View> | null): void {
  startupCover = view;
}

export async function captureStartupReloadScreen(): Promise<string | undefined> {
  if (startupCover === null) return undefined;
  try {
    return await captureRef(startupCover, { format: 'png', result: 'tmpfile' });
  } catch {
    return undefined;
  }
}

export function isResumingStartupUpdate(): boolean {
  return resuming;
}

export async function markStartupUpdateReload(): Promise<void> {
  await AsyncStorage.setItem(KEY, JSON.stringify({ at: Date.now(), from: Updates.updateId }));
}

export async function prepareStartupUpdateHandoff(): Promise<void> {
  try {
    const stored = await AsyncStorage.getItem(KEY);
    if (stored === null) return;
    await AsyncStorage.removeItem(KEY);
    const marker = JSON.parse(stored) as { at?: unknown; from?: unknown };
    const elapsed = typeof marker.at === 'number' ? Date.now() - marker.at : -1;
    // Only the immediate launch of a different bundle continues the old splash.
    // A failed reload or later cold launch must keep normal startup behavior.
    resuming = elapsed >= 0 && elapsed < 60_000 && marker.from !== Updates.updateId;
  } catch {
    // Preferences must never stop startup or prevent an otherwise valid update.
  }
}
