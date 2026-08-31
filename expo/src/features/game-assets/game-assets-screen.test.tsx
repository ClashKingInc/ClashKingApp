import { fireEvent, render } from '@testing-library/react-native';
import type { ReactNode } from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../i18n';
import { CKThemeProvider } from '../../ui';
import type { GameAssetActions } from './actions';
import {
  GameAssetsScreen,
  formatImageCount,
  formatResultCount,
  localizedCategory,
} from './game-assets-screen';
import { GameAssetManifest } from './models';

jest.mock('react-native-gesture-handler', () => {
  const chain = () => ({
    onUpdate() {
      return this;
    },
    onEnd() {
      return this;
    },
  });
  return {
    Gesture: { Pinch: chain, Pan: chain, Simultaneous: () => ({}) },
    GestureDetector: ({ children }: { children: ReactNode }) => children,
  };
});

jest.mock('react-native-reanimated', () => {
  const { View } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    __esModule: true,
    default: { View },
    useSharedValue: (value: number) => ({ value }),
    useAnimatedStyle: (factory: () => object) => factory(),
  };
});

const manifest = GameAssetManifest.fromJson({
  version: 1,
  assets: [
    {
      path: 'heroes/king.png',
      category: 'heroes',
      display_name: 'King',
      extension: 'png',
      url: 'https://assets.test/king.png',
    },
    {
      path: 'heroes/queen.svg',
      category: 'heroes',
      display_name: 'Queen',
      extension: 'svg',
      url: 'https://assets.test/queen.svg',
    },
  ],
});

async function renderScreen(actions: GameAssetActions) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <GameAssetsScreen
            manifest={manifest}
            loading={false}
            error={null}
            actions={actions}
            onBack={jest.fn()}
            onRefresh={jest.fn()}
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

describe('GameAssetsScreen', () => {
  it('renders category controls, count, three-column tiles, and search filtering', async () => {
    const actions = { copy: jest.fn(), share: jest.fn(), save: jest.fn() } as GameAssetActions;
    const view = await renderScreen(actions);
    expect(view.getByRole('button', { name: 'Back' })).toBeTruthy();
    expect(view.getByText('2 results')).toBeTruthy();
    expect(view.getByRole('button', { name: 'King' })).toBeTruthy();
    await fireEvent.changeText(view.getByLabelText('Search this category'), 'Queen');
    expect(view.getByText('1 result')).toBeTruthy();
    expect(view.queryByRole('button', { name: 'King' })).toBeNull();
  });

  it('copies URL on long press and opens exact preview actions on tap', async () => {
    const actions: GameAssetActions = {
      copy: jest.fn(async () => undefined),
      share: jest.fn(async () => undefined),
      save: jest.fn(async () => '/saved/king.png'),
    };
    const view = await renderScreen(actions);
    const tile = view.getByRole('button', { name: 'King' });
    await fireEvent(tile, 'longPress');
    expect(actions.copy).toHaveBeenCalledWith('https://assets.test/king.png');
    await fireEvent.press(tile);
    expect(view.getByText('heroes/king.png')).toBeTruthy();
    expect(view.getByRole('button', { name: 'Copy URL' })).toBeTruthy();
    expect(view.getByRole('button', { name: 'Copy path' })).toBeTruthy();
    expect(view.getByRole('button', { name: 'Share' })).toBeTruthy();
    expect(view.getByRole('button', { name: 'Save' })).toBeTruthy();
  });

  it('preserves localized category aliases and singular/plural count rules', () => {
    const t = ((key: string, values?: Record<string, unknown>) =>
      values?.count ? `${key}:${values.count}` : key) as Parameters<typeof localizedCategory>[1];
    expect(localizedCategory('capital_house-parts', t)).toBe('gameAssetsCategoryCapitalHouseParts');
    expect(localizedCategory('custom_icons', t)).toBe('Custom Icons');
    expect(formatImageCount(1, 'en', t)).toBe('gameAssetsOneImage');
    expect(formatImageCount(1200, 'en', t)).toBe('gameAssetsImageCount:1,200');
    expect(formatResultCount(1, 'en', t)).toBe('gameAssetsOneResult');
  });
});
