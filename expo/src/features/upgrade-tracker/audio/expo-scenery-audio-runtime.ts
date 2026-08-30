import {
  clearPreloadedSource,
  createAudioPlayer,
  preload,
  setAudioModeAsync,
  type AudioPlayer,
} from 'expo-audio';
import type {
  SceneryAudioPlatform,
  SceneryAudioPlayer,
  SceneryAudioRuntime,
} from './scenery-audio-service';
import { sceneryAudioModeForPlatform } from './scenery-audio-service';

export class ExpoSceneryAudioRuntime implements SceneryAudioRuntime {
  async configurePlayback(platform: SceneryAudioPlatform): Promise<void> {
    const mode = sceneryAudioModeForPlatform(platform);
    if (mode !== null) await setAudioModeAsync(mode);
  }

  preload(source: string): Promise<void> {
    return preload(source);
  }

  clearPreloadedSource(source: string): Promise<void> {
    return clearPreloadedSource(source);
  }

  createPlayer(source: string, updateIntervalMilliseconds: number): SceneryAudioPlayer {
    return createAudioPlayer(source, {
      updateInterval: updateIntervalMilliseconds,
      keepAudioSessionActive: false,
    }) as AudioPlayer & SceneryAudioPlayer;
  }
}
