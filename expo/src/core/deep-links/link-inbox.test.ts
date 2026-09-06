import { appLinkInbox, queueAppLink } from './link-inbox';

afterEach(async () => {
  await appLinkInbox.getInitialUrl();
});

test('keeps the latest valid destination until authenticated navigation consumes it once', async () => {
  expect(queueAppLink('https://app.clashk.ing/player/ABC')).toBe(true);
  expect(queueAppLink('clashking://settings/licenses?package=effect')).toBe(true);
  expect(await appLinkInbox.getInitialUrl()).toBe('clashking://settings/licenses?package=effect');
  expect(await appLinkInbox.getInitialUrl()).toBeNull();
});

test('rejects foreign and authentication URLs without replacing the pending destination', async () => {
  queueAppLink('https://app.clashk.ing/clan/ABC/war');
  expect(queueAppLink('https://other.example/player/ABC')).toBe(false);
  expect(queueAppLink('clashking://auth/callback?code=private')).toBe(false);
  expect(await appLinkInbox.getInitialUrl()).toBe('https://app.clashk.ing/clan/ABC/war');
});

test('delivers running links to the subscriber and queues again after it detaches', async () => {
  const listener = jest.fn();
  const stop = appLinkInbox.subscribe(listener);
  try {
    queueAppLink('clashking://player/ABC');
    expect(listener).toHaveBeenCalledWith('clashking://player/ABC');
    expect(await appLinkInbox.getInitialUrl()).toBeNull();
  } finally {
    stop();
  }
  queueAppLink('clashking://clan/DEF');
  expect(listener).toHaveBeenCalledTimes(1);
  expect(await appLinkInbox.getInitialUrl()).toBe('clashking://clan/DEF');
});
