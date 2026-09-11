import { horizontalImageFilename, shareHorizontalCapture } from './horizontal-image-share';

test('builds stable horizontal PNG filenames', () => {
  expect(horizontalImageFilename('legends', 'Matt! King', '', new Date(2026, 8, 11, 9, 5, 4))).toBe(
    'legends_Matt_King_2026-09-11_09-05-04.png',
  );
});

test('captures once and shares the PNG natively', async () => {
  const capture = jest.fn().mockResolvedValue('/tmp/share.png');
  const nativeShare = jest.fn().mockResolvedValue(undefined);
  const webDownload = jest.fn();
  await expect(
    shareHorizontalCapture({
      fileName: 'share.png',
      message: 'Share',
      platform: 'native',
      capture,
      nativeShare,
      webDownload,
    }),
  ).resolves.toEqual({ url: '/tmp/share.png', fileName: 'share.png' });
  expect(capture).toHaveBeenCalledTimes(1);
  expect(nativeShare).toHaveBeenCalledWith('/tmp/share.png', 'Share');
  expect(webDownload).not.toHaveBeenCalled();
});

test('captures once and downloads the PNG on web', async () => {
  const webDownload = jest.fn();
  await shareHorizontalCapture({
    fileName: 'share.png',
    message: 'Share',
    platform: 'web',
    capture: jest.fn().mockResolvedValue('data:image/png;base64,abc'),
    nativeShare: jest.fn(),
    webDownload,
  });
  expect(webDownload).toHaveBeenCalledWith('data:image/png;base64,abc', 'share.png');
});
