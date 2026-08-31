import { fireEvent, render } from '@testing-library/react-native';
import type { ComponentProps } from 'react';
import { View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { Achievement } from '../models';
import type { AchievementModelViewer } from './achievement-model-viewer';
import { AchievementsScreen } from './achievements-screen';

jest.mock('react-native-webview', () => ({
  WebView: jest.requireActual<typeof import('react-native')>('react-native').View,
}));

const achievements: readonly Achievement[] = [
  {
    id: 'townhall_18',
    modelUrl: 'https://assets.clashk.ing/achievements/town-hall-18-achievement-badge.glb',
    earnedCount: 1,
    isRepeatable: true,
  },
  {
    id: 'war_warrior',
    modelUrl: 'https://assets.clashk.ing/achievements/war-champion-achievement-badge.glb',
    earnedCount: 0,
    isRepeatable: true,
  },
  {
    id: 'mr_legend',
    modelUrl: 'https://assets.clashk.ing/achievements/perfect-legends-day-achievement-badge.glb',
    earnedCount: 4,
    isRepeatable: true,
  },
  {
    id: 'defense_doesnt_matter',
    modelUrl: 'https://assets.clashk.ing/achievements/bad-legends-achievement-badge.glb',
    earnedCount: 2,
    isRepeatable: true,
  },
];

type ModelProps = ComponentProps<typeof AchievementModelViewer>;

async function setup() {
  const requests: ModelProps[] = [];
  const onBack = jest.fn();
  const ModelRenderer = (props: ModelProps) => {
    requests.push(props);
    return <View testID={`model-${props.achievement.id}-${props.interactive}`} />;
  };
  const screen = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <AchievementsScreen
            achievements={achievements}
            modelRenderer={ModelRenderer}
            onBack={onBack}
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  return { onBack, requests, screen };
}

test('renders the exact completion copy, localized labels, lock state, and earned counts', async () => {
  const { screen } = await setup();
  expect(screen.getByText('Achievements')).toBeTruthy();
  expect(screen.getByText('3/4 completed')).toBeTruthy();
  expect(screen.getByRole('button', { name: 'Townhall 18, ×1' })).toBeTruthy();
  expect(screen.getByRole('button', { name: 'War Warrior, LOCKED' })).toBeTruthy();
  expect(screen.getByRole('button', { name: 'Mr. Legend, ×4' })).toBeTruthy();
  expect(screen.getByRole('button', { name: 'Defense Doesn’t Matter, ×2' })).toBeTruthy();
});

test('opens a fixed detail sheet with one description and plain earned count', async () => {
  const { requests, screen } = await setup();
  await fireEvent.press(screen.getByTestId('achievement-war_warrior'));
  expect(screen.getByTestId('achievement-detail-sheet')).toBeTruthy();
  expect(screen.getByText('Reach 5,000 war stars.')).toBeTruthy();
  expect(screen.getByText('Earned ×0')).toBeTruthy();
  expect(screen.queryByText('Requirement')).toBeNull();
  expect(screen.queryByText('Repeatable')).toBeNull();
  expect(
    requests.some(
      (request) =>
        request.achievement.id === 'war_warrior' &&
        request.interactive &&
        request.enableIdleRotation,
    ),
  ).toBe(true);
  await fireEvent.press(screen.getByTestId('achievement-detail-close'));
  expect(screen.queryByTestId('achievement-detail-sheet')).toBeNull();
});

test('delegates back navigation and makes tiles inert model previews', async () => {
  const { onBack, requests, screen } = await setup();
  expect(screen.getByRole('button', { name: 'Back' })).toBeTruthy();
  await fireEvent.press(screen.getByTestId('achievements-back'));
  expect(onBack).toHaveBeenCalledTimes(1);
  expect(
    requests
      .filter((request) => !request.interactive)
      .every((request) => request.enableIdleRotation === false),
  ).toBe(true);
});
