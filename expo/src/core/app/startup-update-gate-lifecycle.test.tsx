import { act, cleanup, render } from '@testing-library/react-native';
import * as Updates from 'expo-updates';
import { Platform, Text } from 'react-native';

import { reportException } from '../observability/observability';
import { StartupLoadingScreen } from './startup-loading';
import { StartupUpdateGate } from './startup-update-gate';

jest.mock('expo-updates', () => ({
  isEnabled: true,
  useUpdates: jest.fn(() => ({ downloadProgress: 0.35 })),
  checkForUpdateAsync: jest.fn(),
  fetchUpdateAsync: jest.fn(),
  reloadAsync: jest.fn(),
}));
jest.mock('../observability/observability', () => ({ reportException: jest.fn() }));
jest.mock('./startup-loading', () => ({ StartupLoadingScreen: jest.fn(() => null) }));

const available = {
  isAvailable: true,
  isRollBackToEmbedded: false,
} as Awaited<ReturnType<typeof Updates.checkForUpdateAsync>>;
const downloaded = {
  isNew: true,
  isRollBackToEmbedded: false,
} as Awaited<ReturnType<typeof Updates.fetchUpdateAsync>>;
const developmentGlobal = global as typeof global & { __DEV__: boolean };

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((complete) => {
    resolve = complete;
  });
  return { promise, resolve };
}

function mount() {
  return render(
    <StartupUpdateGate>
      <Text>Application bootstrap</Text>
    </StartupUpdateGate>,
  );
}

function latestLoadingProps() {
  return jest.mocked(StartupLoadingScreen).mock.calls.at(-1)?.[0];
}

describe('preserved OTA startup lifecycle', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    jest.clearAllMocks();
    jest.replaceProperty(Platform, 'OS', 'ios');
    jest.replaceProperty(developmentGlobal, '__DEV__', false);
    jest.replaceProperty(Updates, 'isEnabled', true);
    jest.mocked(Updates.checkForUpdateAsync).mockImplementation(() => new Promise(() => {}));
    jest.mocked(Updates.fetchUpdateAsync).mockResolvedValue(downloaded);
    jest.mocked(Updates.reloadAsync).mockResolvedValue(undefined);
  });

  afterEach(async () => {
    await cleanup();
    jest.restoreAllMocks();
    jest.useRealTimers();
  });

  it.each([
    { platform: 'web', development: false, enabled: true },
    { platform: 'ios', development: true, enabled: true },
    { platform: 'android', development: false, enabled: false },
  ] as const)('never checks or blocks with %j', async ({ platform, development, enabled }) => {
    jest.replaceProperty(Platform, 'OS', platform);
    jest.replaceProperty(developmentGlobal, '__DEV__', development);
    jest.replaceProperty(Updates, 'isEnabled', enabled);

    const screen = await mount();

    expect(screen.getByText('Application bootstrap')).toBeTruthy();
    expect(Updates.checkForUpdateAsync).not.toHaveBeenCalled();
    expect(Updates.fetchUpdateAsync).not.toHaveBeenCalled();
    expect(Updates.reloadAsync).not.toHaveBeenCalled();
  });

  it('releases after the exact five-second check deadline and never reloads a late result', async () => {
    const check = deferred<Awaited<ReturnType<typeof Updates.checkForUpdateAsync>>>();
    jest.mocked(Updates.checkForUpdateAsync).mockReturnValue(check.promise);
    const screen = await mount();

    expect(latestLoadingProps()?.update).toEqual({ downloading: false, progress: 0.35 });
    await act(async () => jest.advanceTimersByTime(4_999));
    expect(screen.queryByText('Application bootstrap')).toBeNull();
    await act(async () => jest.advanceTimersByTime(1));
    expect(screen.getByText('Application bootstrap')).toBeTruthy();
    await act(async () => check.resolve(available));
    expect(Updates.fetchUpdateAsync).toHaveBeenCalledTimes(1);
    expect(Updates.reloadAsync).not.toHaveBeenCalled();
  });

  it('clears the check deadline during download and forwards progress before applying the update', async () => {
    const download = deferred<Awaited<ReturnType<typeof Updates.fetchUpdateAsync>>>();
    jest.mocked(Updates.checkForUpdateAsync).mockResolvedValue(available);
    jest.mocked(Updates.fetchUpdateAsync).mockReturnValue(download.promise);
    const screen = await mount();

    expect(latestLoadingProps()?.update).toEqual({ downloading: true, progress: 0.35 });
    await act(async () => jest.advanceTimersByTime(20_000));
    expect(screen.queryByText('Application bootstrap')).toBeNull();
    await act(async () => download.resolve(downloaded));
    expect(Updates.checkForUpdateAsync).toHaveBeenCalledTimes(1);
    expect(Updates.reloadAsync).toHaveBeenCalledTimes(1);
    expect(screen.getByText('Application bootstrap')).toBeTruthy();
  });

  it('continues in the background before a check finishes without a later reload', async () => {
    const check = deferred<Awaited<ReturnType<typeof Updates.checkForUpdateAsync>>>();
    jest.mocked(Updates.checkForUpdateAsync).mockReturnValue(check.promise);
    const screen = await mount();

    await act(async () => latestLoadingProps()?.onUpdateInBackground?.());
    expect(screen.getByText('Application bootstrap')).toBeTruthy();
    await act(async () => check.resolve(available));
    expect(Updates.fetchUpdateAsync).toHaveBeenCalledTimes(1);
    expect(Updates.reloadAsync).not.toHaveBeenCalled();
  });

  it('continues in the background during download without a later reload', async () => {
    const download = deferred<Awaited<ReturnType<typeof Updates.fetchUpdateAsync>>>();
    jest.mocked(Updates.checkForUpdateAsync).mockResolvedValue(available);
    jest.mocked(Updates.fetchUpdateAsync).mockReturnValue(download.promise);
    const screen = await mount();

    await act(async () => latestLoadingProps()?.onUpdateInBackground?.());
    expect(screen.getByText('Application bootstrap')).toBeTruthy();
    await act(async () => download.resolve(downloaded));
    expect(Updates.reloadAsync).not.toHaveBeenCalled();
  });

  it.each(['check', 'download'] as const)(
    'reports %s failure and continues startup',
    async (stage) => {
      const error = new Error('offline');
      if (stage === 'check') {
        jest.mocked(Updates.checkForUpdateAsync).mockRejectedValue(error);
      } else {
        jest.mocked(Updates.checkForUpdateAsync).mockResolvedValue(available);
        jest.mocked(Updates.fetchUpdateAsync).mockRejectedValue(error);
      }

      const screen = await mount();

      expect(screen.getByText('Application bootstrap')).toBeTruthy();
      expect(reportException).toHaveBeenCalledWith(error, 'startup.update');
      expect(Updates.reloadAsync).not.toHaveBeenCalled();
    },
  );

  it('does not reload when unmounted during a download', async () => {
    const download = deferred<Awaited<ReturnType<typeof Updates.fetchUpdateAsync>>>();
    jest.mocked(Updates.checkForUpdateAsync).mockResolvedValue(available);
    jest.mocked(Updates.fetchUpdateAsync).mockReturnValue(download.promise);
    const screen = await mount();

    await screen.unmount();
    await act(async () => download.resolve(downloaded));

    expect(Updates.reloadAsync).not.toHaveBeenCalled();
  });
});
