import { loadStartupUpdate } from './startup-update-gate';

jest.mock('expo-updates', () => ({ isEnabled: false, useUpdates: () => ({}) }));
// Keep these copied helper cases isolated from the native SDK's cleanup timer.
jest.mock('../observability/observability', () => ({ reportException: jest.fn() }));

function setup() {
  return {
    runtime: {
      check: jest.fn(async () => ({ isAvailable: true, isRollBackToEmbedded: false })),
      fetch: jest.fn(async () => ({ isNew: true, isRollBackToEmbedded: false })),
      reload: jest.fn(async () => undefined),
    },
    callbacks: { downloading: jest.fn(), shouldReload: jest.fn(() => true) },
  };
}

test('downloads and applies an available update before app startup', async () => {
  const { runtime, callbacks } = setup();
  await loadStartupUpdate(runtime, callbacks);
  expect(callbacks.downloading).toHaveBeenCalledTimes(1);
  expect(runtime.fetch).toHaveBeenCalledTimes(1);
  expect(runtime.reload).toHaveBeenCalledTimes(1);
});

test('skipping continues the download but never reloads the active app', async () => {
  const { runtime, callbacks } = setup();
  callbacks.shouldReload.mockReturnValue(false);
  await loadStartupUpdate(runtime, callbacks);
  expect(runtime.fetch).toHaveBeenCalledTimes(1);
  expect(runtime.reload).not.toHaveBeenCalled();
});

test('no update does not download or reload', async () => {
  const { runtime, callbacks } = setup();
  runtime.check.mockResolvedValue({ isAvailable: false, isRollBackToEmbedded: false });
  await loadStartupUpdate(runtime, callbacks);
  expect(runtime.fetch).not.toHaveBeenCalled();
  expect(runtime.reload).not.toHaveBeenCalled();
});

test('rollback directives also fetch and reload the embedded update', async () => {
  const { runtime, callbacks } = setup();
  runtime.check.mockResolvedValue({ isAvailable: false, isRollBackToEmbedded: true });
  runtime.fetch.mockResolvedValue({ isNew: false, isRollBackToEmbedded: true });
  await loadStartupUpdate(runtime, callbacks);
  expect(runtime.reload).toHaveBeenCalledTimes(1);
});

test('failed downloads are surfaced without attempting a reload', async () => {
  const { runtime, callbacks } = setup();
  runtime.fetch.mockRejectedValue(new Error('offline'));
  await expect(loadStartupUpdate(runtime, callbacks)).rejects.toThrow('offline');
  expect(runtime.reload).not.toHaveBeenCalled();
});
