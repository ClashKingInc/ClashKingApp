import { act, render, waitFor } from '@testing-library/react-native';

import { GameAssetsRoot } from './game-assets-root';
import type { GameAssetManifest } from './models';
import type { GameAssetManifestRepository } from './repository';

jest.mock('@clashking/native', () => ({
  __esModule: true,
  default: { saveFile: jest.fn() },
}));

jest.mock('../../core/app/runtime-context', () => ({
  useAppRuntime: () => ({ preferences: {} }),
}));

jest.mock('./game-assets-screen', () => ({
  GameAssetsScreen: (() => {
    const { Text } = jest.requireActual('react-native');
    function MockGameAssetsScreen(props: {
      loading: boolean;
      manifest: GameAssetManifest | null;
      error: unknown;
    }) {
      return (
        <Text testID="game-assets-state">
          {`${props.loading}:${props.manifest?.version ?? 'none'}:${props.error ? 'error' : 'ok'}`}
        </Text>
      );
    }
    return MockGameAssetsScreen;
  })(),
}));

test('clears stale manifest state and force-refreshes when the repository changes', async () => {
  const manifest = { version: 1, assets: [], categories: [] } as unknown as GameAssetManifest;
  const firstRepository = {
    load: jest.fn(async () => manifest),
  } satisfies GameAssetManifestRepository;
  let resolveSecond!: (value: GameAssetManifest) => void;
  const secondRepository = {
    load: jest.fn(
      () =>
        new Promise<GameAssetManifest>((resolve) => {
          resolveSecond = resolve;
        }),
    ),
  } satisfies GameAssetManifestRepository;

  const view = await render(<GameAssetsRoot onBack={jest.fn()} repository={firstRepository} />);
  await waitFor(() =>
    expect(view.getByTestId('game-assets-state').props.children).toBe('false:1:ok'),
  );
  expect(firstRepository.load).toHaveBeenCalledWith({ forceRefresh: false });

  await view.rerender(<GameAssetsRoot onBack={jest.fn()} repository={secondRepository} />);
  await waitFor(() =>
    expect(view.getByTestId('game-assets-state').props.children).toBe('true:none:ok'),
  );
  expect(secondRepository.load).toHaveBeenCalledWith({ forceRefresh: true });

  await act(async () => resolveSecond(manifest));
  await waitFor(() =>
    expect(view.getByTestId('game-assets-state').props.children).toBe('false:1:ok'),
  );
});
