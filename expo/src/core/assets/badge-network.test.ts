import { fetch } from 'expo/fetch';
import { ManagedImageCache, type ImageFiles } from './managed-image-cache';
import { rememberBadgeToken } from './badge-token-hints';
import './local-asset-cache';

jest.mock('@react-native-async-storage/async-storage', () => ({ __esModule: true, default: {} }));
jest.mock('./managed-image-cache', () => ({ ManagedImageCache: jest.fn() }));
jest.mock('expo/fetch', () => ({ fetch: jest.fn() }));
jest.mock('expo-crypto', () => ({}));
jest.mock('expo-file-system', () => ({ Paths: {}, Directory: class {}, File: class {} }));

test('managed network adapter attaches token headers without changing the URL', async () => {
  const files = jest.mocked(ManagedImageCache).mock.calls[0]![1] as ImageFiles;
  rememberBadgeToken('NETWORK', { badgeToken: 'network_token' });
  jest.mocked(fetch).mockResolvedValue({ ok: false } as Awaited<ReturnType<typeof fetch>>);
  const url = 'https://badges.clashk.ing/NETWORK.avif?size=128';
  await expect(files.download(url, 'sha')).rejects.toThrow('Image download failed');
  expect(fetch).toHaveBeenLastCalledWith(url, expect.objectContaining({
    headers: { 'Cache-Control': 'no-cache', 'X-ClashKing-Badge-Token': 'network_token' },
  }));
  const asset = 'https://assets.clashk.ing/icons/NETWORK.avif';
  await expect(files.download(asset, 'sha')).rejects.toThrow();
  expect(fetch).toHaveBeenLastCalledWith(asset, expect.objectContaining({ headers: { 'Cache-Control': 'no-cache' } }));
});
