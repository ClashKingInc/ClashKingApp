import contract from '../../../../native/parity-contract.json';
import type {
  SceneryAudioPlayer,
  SceneryAudioRuntime,
  SceneryAudioStatus,
} from './scenery-audio-service';
import { SceneryAudioService, sceneryAudioModeForPlatform } from './scenery-audio-service';

function harness(platform: 'ios' | 'android' | 'web' = 'ios') {
  let statusListener: ((status: SceneryAudioStatus) => void) | undefined;
  const subscription = { remove: jest.fn() };
  const player: jest.Mocked<SceneryAudioPlayer> = {
    volume: 0,
    loop: true,
    muted: true,
    play: jest.fn(),
    pause: jest.fn(),
    seekTo: jest.fn(async (_seconds: number) => undefined),
    addListener: jest.fn((_event, listener) => {
      statusListener = listener;
      return subscription;
    }),
    remove: jest.fn(),
  };
  const runtime: jest.Mocked<SceneryAudioRuntime> = {
    configurePlayback: jest.fn(async (_platform) => undefined),
    preload: jest.fn(async (_source) => undefined),
    clearPreloadedSource: jest.fn(async (_source) => undefined),
    createPlayer: jest.fn((_source, _updateIntervalMilliseconds) => player),
  };
  const head = jest.fn(async () => ({ status: 200 }));
  const service = new SceneryAudioService(
    'https://assets.clashk.ing/scenery/music.ogg',
    platform,
    runtime,
    head,
  );
  return {
    service,
    runtime,
    player,
    head,
    subscription,
    emit(status: Partial<SceneryAudioStatus>) {
      statusListener?.({
        currentTime: 0,
        duration: 0,
        playing: false,
        isLoaded: true,
        isBuffering: false,
        didJustFinish: false,
        ...status,
      });
    },
  };
}

describe('SceneryAudioService', () => {
  test('declares exact native iOS and Android interruption and attribute parity', () => {
    expect(sceneryAudioModeForPlatform('ios')).toEqual({
      allowsRecording: false,
      playsInSilentMode: true,
      shouldPlayInBackground: false,
      shouldRouteThroughEarpiece: false,
      interruptionMode: 'doNotMix',
    });
    expect(sceneryAudioModeForPlatform('android')).toEqual({
      allowsRecording: false,
      playsInSilentMode: true,
      shouldPlayInBackground: false,
      shouldRouteThroughEarpiece: false,
      interruptionMode: 'duckOthers',
    });
    expect(sceneryAudioModeForPlatform('web')).toBeNull();
    expect(contract.sceneryAudio.android.exactInterruptionParity).toBe(true);
    expect(contract.sceneryAudio.android.exactAudioAttributesParity).toBe(true);
    expect(contract.sceneryAudio.android).not.toHaveProperty('gap');
    expect(contract.sceneryAudio.android).not.toHaveProperty('audioAttributesGap');
  });

  test('checks the network source with HEAD and hides unavailable audio', async () => {
    const h = harness();
    await expect(h.service.checkAvailability()).resolves.toBe(true);
    expect(h.head).toHaveBeenCalledWith('https://assets.clashk.ing/scenery/music.ogg');
    expect(h.service.snapshot()).toMatchObject({ checking: false, available: true });

    const missing = harness();
    missing.head.mockResolvedValue({ status: 404 });
    await expect(missing.service.checkAvailability()).resolves.toBe(false);
    expect(missing.service.snapshot()).toMatchObject({ checking: false, available: false });
  });

  test('downloads before play, uses full volume/no loop, pauses and resumes one player', async () => {
    const h = harness('ios');
    await h.service.play();
    expect(h.runtime.configurePlayback).toHaveBeenCalledWith('ios');
    expect(h.runtime.preload).toHaveBeenCalledWith(h.service.source);
    expect(h.runtime.createPlayer).toHaveBeenCalledWith(h.service.source, 250);
    expect(h.player).toMatchObject({ volume: 1, loop: false, muted: false });
    expect(h.player.play).toHaveBeenCalledTimes(1);

    h.emit({ currentTime: 12.345, duration: 70.1, playing: true });
    expect(h.service.snapshot()).toMatchObject({
      playing: true,
      positionMilliseconds: 12345,
      durationMilliseconds: 70100,
    });
    h.service.pause();
    await h.service.play();
    expect(h.player.pause).toHaveBeenCalledTimes(1);
    expect(h.player.play).toHaveBeenCalledTimes(2);
    expect(h.runtime.createPlayer).toHaveBeenCalledTimes(1);
  });

  test('resets completed playback, clamps seeking and releases only its own player', async () => {
    const h = harness();
    await h.service.play();
    h.emit({ duration: 30, currentTime: 30, didJustFinish: true });
    expect(h.service.snapshot()).toMatchObject({ playing: false, positionMilliseconds: 0 });
    await h.service.play();
    expect(h.player.seekTo).toHaveBeenCalledWith(0);
    await h.service.seek(45_000);
    expect(h.player.seekTo).toHaveBeenLastCalledWith(30);

    await h.service.dispose();
    expect(h.subscription.remove).toHaveBeenCalledTimes(1);
    expect(h.player.pause).toHaveBeenCalled();
    expect(h.player.remove).toHaveBeenCalledTimes(1);
    expect(h.runtime.clearPreloadedSource).toHaveBeenCalledWith(h.service.source);
  });

  test('supports overlapping instances without global audio shutdown', async () => {
    const first = harness();
    const second = harness();
    await Promise.all([first.service.play(), second.service.play()]);
    expect(first.player.play).toHaveBeenCalledTimes(1);
    expect(second.player.play).toHaveBeenCalledTimes(1);
    await first.service.dispose();
    expect(second.player.pause).not.toHaveBeenCalled();
  });

  test('suppresses load errors and marks the soundtrack unavailable like Flutter', async () => {
    const h = harness();
    h.runtime.preload.mockRejectedValue(new Error('offline'));
    await expect(h.service.play()).resolves.toBeUndefined();
    expect(h.service.snapshot()).toMatchObject({
      available: false,
      loading: false,
      playing: false,
    });
  });
});
