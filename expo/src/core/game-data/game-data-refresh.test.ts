import { startGameDataRefresh } from './game-data-refresh';

test('checks on mount, foreground ticks, and resume, then cleans up', async () => {
  jest.useFakeTimers();
  let active = true;
  let resume = () => {};
  const remove = jest.fn();
  const refresh = jest.fn(async () => {});
  const stop = startGameDataRefresh(
    refresh,
    () => active,
    (callback) => {
      resume = callback;
      return remove;
    },
  );
  expect(refresh).toHaveBeenCalledTimes(1);
  jest.advanceTimersByTime(60_000);
  expect(refresh).toHaveBeenCalledTimes(2);
  active = false;
  jest.advanceTimersByTime(120_000);
  resume();
  expect(refresh).toHaveBeenCalledTimes(2);
  active = true;
  resume();
  expect(refresh).toHaveBeenCalledTimes(3);
  stop();
  jest.advanceTimersByTime(60_000);
  expect(refresh).toHaveBeenCalledTimes(3);
  expect(remove).toHaveBeenCalledTimes(1);
  jest.useRealTimers();
});
