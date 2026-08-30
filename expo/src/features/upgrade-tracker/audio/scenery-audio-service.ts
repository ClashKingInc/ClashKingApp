export type SceneryAudioPlatform = 'ios' | 'android' | 'web';

export interface SceneryAudioMode {
  readonly allowsRecording: false;
  readonly playsInSilentMode: true;
  readonly shouldPlayInBackground: false;
  readonly shouldRouteThroughEarpiece: false;
  readonly interruptionMode: 'doNotMix' | 'duckOthers';
}

export function sceneryAudioModeForPlatform(
  platform: SceneryAudioPlatform,
): SceneryAudioMode | null {
  if (platform === 'web') return null;
  return {
    allowsRecording: false,
    playsInSilentMode: true,
    shouldPlayInBackground: false,
    shouldRouteThroughEarpiece: false,
    interruptionMode: platform === 'ios' ? 'doNotMix' : 'duckOthers',
  };
}

export interface SceneryAudioStatus {
  readonly currentTime: number;
  readonly duration: number;
  readonly playing: boolean;
  readonly isLoaded: boolean;
  readonly isBuffering: boolean;
  readonly didJustFinish: boolean;
}

export interface SceneryAudioPlayer {
  volume: number;
  loop: boolean;
  muted: boolean;
  play(): void;
  pause(): void;
  seekTo(seconds: number): Promise<void>;
  addListener(
    event: 'playbackStatusUpdate',
    listener: (status: SceneryAudioStatus) => void,
  ): { remove(): void };
  remove(): void;
}

export interface SceneryAudioRuntime {
  configurePlayback(platform: SceneryAudioPlatform): Promise<void>;
  preload(source: string): Promise<void>;
  clearPreloadedSource(source: string): Promise<void>;
  createPlayer(source: string, updateIntervalMilliseconds: number): SceneryAudioPlayer;
}

export interface SceneryAudioState {
  readonly checking: boolean;
  readonly available: boolean;
  readonly loading: boolean;
  readonly playing: boolean;
  readonly positionMilliseconds: number;
  readonly durationMilliseconds: number;
}

export type SceneryAudioListener = (state: SceneryAudioState) => void;

const POSITION_INTERVAL_MILLISECONDS = 250;

export class SceneryAudioService {
  private player: SceneryAudioPlayer | undefined;
  private playerSubscription: { remove(): void } | undefined;
  private preparePromise: Promise<SceneryAudioPlayer> | undefined;
  private listeners = new Set<SceneryAudioListener>();
  private disposed = false;
  private ended = false;
  private state: SceneryAudioState = {
    checking: true,
    available: false,
    loading: false,
    playing: false,
    positionMilliseconds: 0,
    durationMilliseconds: 0,
  };

  constructor(
    readonly source: string,
    private readonly platform: SceneryAudioPlatform,
    private readonly runtime: SceneryAudioRuntime,
    private readonly fetchHead: (url: string) => Promise<{ status: number }> = async (url) =>
      fetch(url, { method: 'HEAD' }),
  ) {}

  snapshot(): SceneryAudioState {
    return this.state;
  }

  subscribe(listener: SceneryAudioListener): () => void {
    this.listeners.add(listener);
    listener(this.state);
    return () => this.listeners.delete(listener);
  }

  async checkAvailability(): Promise<boolean> {
    try {
      const response = await this.fetchHead(this.source);
      const available = response.status >= 200 && response.status < 300;
      this.update({ checking: false, available });
      return available;
    } catch {
      this.update({ checking: false, available: false });
      return false;
    }
  }

  async toggle(): Promise<void> {
    if (this.state.playing) {
      this.pause();
      return;
    }
    await this.play();
  }

  async play(): Promise<void> {
    if (this.disposed) return;
    try {
      this.update({ loading: this.player === undefined });
      const player = await this.prepare();
      if (this.disposed) return;
      if (this.ended) {
        await player.seekTo(0);
        this.ended = false;
      }
      player.play();
      this.update({ loading: false, playing: true });
    } catch {
      this.update({ available: false, loading: false, playing: false });
    }
  }

  pause(): void {
    this.player?.pause();
    this.update({ playing: false });
  }

  async seek(positionMilliseconds: number): Promise<void> {
    if (!this.player || this.disposed) return;
    const duration = Math.max(0, this.state.durationMilliseconds);
    const position = Math.min(Math.max(positionMilliseconds, 0), duration || positionMilliseconds);
    await this.player.seekTo(position / 1000);
    this.ended = false;
    this.update({ positionMilliseconds: position });
  }

  async dispose(): Promise<void> {
    if (this.disposed) return;
    this.disposed = true;
    if (this.preparePromise) {
      try {
        await this.preparePromise;
      } catch {
        // A failed in-flight load has no player to release.
      }
    }
    this.playerSubscription?.remove();
    this.player?.pause();
    this.player?.remove();
    this.player = undefined;
    this.listeners.clear();
    await this.runtime.clearPreloadedSource(this.source);
  }

  private prepare(): Promise<SceneryAudioPlayer> {
    if (this.player) return Promise.resolve(this.player);
    if (this.preparePromise) return this.preparePromise;
    this.preparePromise = (async () => {
      await this.runtime.configurePlayback(this.platform);
      await this.runtime.preload(this.source);
      const player = this.runtime.createPlayer(this.source, POSITION_INTERVAL_MILLISECONDS);
      player.volume = 1;
      player.loop = false;
      player.muted = false;
      this.playerSubscription = player.addListener('playbackStatusUpdate', (status) => {
        if (this.disposed) return;
        this.ended = status.didJustFinish;
        this.update({
          loading: status.isBuffering || !status.isLoaded,
          playing: status.didJustFinish ? false : status.playing,
          positionMilliseconds: status.didJustFinish
            ? 0
            : Math.max(0, Math.round(status.currentTime * 1000)),
          durationMilliseconds: Math.max(0, Math.round(status.duration * 1000)),
        });
      });
      this.player = player;
      return player;
    })().finally(() => {
      this.preparePromise = undefined;
    });
    return this.preparePromise;
  }

  private update(patch: Partial<SceneryAudioState>): void {
    if (this.disposed) return;
    this.state = { ...this.state, ...patch };
    for (const listener of this.listeners) listener(this.state);
  }
}
