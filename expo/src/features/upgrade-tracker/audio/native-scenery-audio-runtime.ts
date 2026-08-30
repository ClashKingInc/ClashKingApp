import ClashKingNative, { type SceneryAudioNativeStatus } from '@clashking/native';

import type {
  SceneryAudioPlatform,
  SceneryAudioPlayer,
  SceneryAudioRuntime,
  SceneryAudioStatus,
} from './scenery-audio-service';

export class NativeSceneryAudioRuntime implements SceneryAudioRuntime {
  private preparedSource: string | null = null;

  configurePlayback(_platform: SceneryAudioPlatform): Promise<void> {
    return Promise.resolve();
  }

  async preload(source: string): Promise<void> {
    await ClashKingNative.prepareSceneryAudio(source);
    this.preparedSource = source;
  }

  async clearPreloadedSource(source: string): Promise<void> {
    if (this.preparedSource !== source) return;
    this.preparedSource = null;
    await ClashKingNative.releaseSceneryAudio();
  }

  createPlayer(source: string, _updateIntervalMilliseconds: number): SceneryAudioPlayer {
    if (this.preparedSource !== source) {
      throw new Error('Native scenery audio must be preloaded before creating its player.');
    }
    return new NativeSceneryAudioPlayer();
  }
}

class NativeSceneryAudioPlayer implements SceneryAudioPlayer {
  volume = 1;
  loop = false;
  muted = false;

  play(): void {
    void ClashKingNative.playSceneryAudio();
  }

  pause(): void {
    void ClashKingNative.pauseSceneryAudio();
  }

  seekTo(seconds: number): Promise<void> {
    return ClashKingNative.seekSceneryAudio(Math.max(0, Math.round(seconds * 1000)));
  }

  addListener(
    event: 'playbackStatusUpdate',
    listener: (status: SceneryAudioStatus) => void,
  ): { remove(): void } {
    void event;
    return ClashKingNative.addListener('onSceneryAudioStatus', (status) =>
      listener(toServiceStatus(status)),
    );
  }

  remove(): void {
    void ClashKingNative.releaseSceneryAudio();
  }
}

function toServiceStatus(status: SceneryAudioNativeStatus): SceneryAudioStatus {
  return {
    currentTime: status.positionMilliseconds / 1000,
    duration: status.durationMilliseconds / 1000,
    playing: status.playing,
    isLoaded: status.loaded,
    isBuffering: status.buffering,
    didJustFinish: status.didJustFinish,
  };
}
