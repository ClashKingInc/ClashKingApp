import { fireEvent, render } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import * as Clipboard from 'expo-clipboard';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import {
  UpgradeCategory,
  UpgradeCollectionItem,
  UpgradeCost,
  UpgradePlanPreferences,
  UpgradeQueue,
  UpgradeStep,
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
  UpgradeVillage,
} from '../models';
import { trackerFixture } from './upgrade-tracker-logic.test';
import {
  UpgradeTrackerScreen,
  boundedTrackerPageCache,
  uniqueCollectionItems,
  uniqueUpgradeItems,
} from './upgrade-tracker-screen';

jest.mock('react-native-draggable-flatlist', () => {
  const ReactModule = jest.requireActual<typeof import('react')>('react');
  const { View: MockView } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    ScaleDecorator: ({ children }: { children: React.ReactNode }) => children,
    NestableScrollContainer: ({ children }: { children: React.ReactNode }) =>
      ReactModule.createElement(MockView, null, children),
    NestableDraggableFlatList: ({
      data,
      renderItem,
    }: {
      data: readonly unknown[];
      renderItem: (parameters: Record<string, unknown>) => React.ReactNode;
    }) =>
      ReactModule.createElement(
        MockView,
        null,
        data.map((item, index) =>
          ReactModule.createElement(
            ReactModule.Fragment,
            { key: index },
            renderItem({ item, drag: jest.fn(), isActive: false, getIndex: () => index }),
          ),
        ),
      ),
  };
});

jest.mock('react-native-pager-view', () => {
  const ReactModule = jest.requireActual<typeof import('react')>('react');
  const { View: MockView } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    __esModule: true,
    default: ReactModule.forwardRef((props: object, ref) => {
      ReactModule.useImperativeHandle(ref, () => ({ setPage: jest.fn() }));
      return ReactModule.createElement(MockView, props);
    }),
  };
});

const actions = {
  onBack: jest.fn(),
  onSelectAccount: jest.fn(),
  onImport: jest.fn(async () => undefined),
  onRefresh: jest.fn(async () => undefined),
  onGoldPassChange: jest.fn(),
  onPreferencesChange: jest.fn(),
  onOpenGameSettings: jest.fn(),
};

function renderScreen(snapshot = trackerFixture()) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <UpgradeTrackerScreen
            snapshot={snapshot}
            accounts={[
              {
                tag: '#TEST',
                name: 'Tester',
                townHallLevel: 17,
                builderHallLevel: 10,
              },
            ]}
            selectedTag="#TEST"
            loading={false}
            error={null}
            goldPassPercent={0}
            preferences={new UpgradePlanPreferences()}
            {...actions}
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

describe('UpgradeTrackerScreen', () => {
  beforeEach(() => jest.clearAllMocks());

  it('renders live village progress and exposes all five Flutter destinations', async () => {
    const screen = await renderScreen();
    await fireEvent.press(screen.getByLabelText('Defenses'));
    expect(screen.getByLabelText('Cannon, level 1 of 3')).toBeTruthy();
    await fireEvent.press(screen.getByLabelText('Home Village'));
    expect(screen.getByText('Builder Base')).toBeTruthy();
    expect(screen.getByText('Calendar')).toBeTruthy();
    expect(screen.getByText('Plan')).toBeTruthy();
    expect(screen.getByText('Collection')).toBeTruthy();
    await fireEvent.press(screen.getByText('Collection'));
    await fireEvent.press(screen.getByLabelText('Sceneries'));
    expect(screen.getByText('Forest')).toBeTruthy();
  });

  it('routes account and back actions and opens a capture-backed share preview', async () => {
    const screen = await renderScreen();
    await fireEvent.press(screen.getByLabelText('Back'));
    await fireEvent.press(screen.getByLabelText('Choose account'));
    await fireEvent.press(screen.getByLabelText('Tester'));
    await fireEvent.press(screen.getByLabelText('Share tracker'));
    await fireEvent.press(screen.getByText('Home Village progress'));

    expect(actions.onBack).toHaveBeenCalled();
    expect(actions.onSelectAccount).toHaveBeenCalledWith('#TEST');
    expect(screen.getAllByText('Share progress')).toHaveLength(2);
    expect(screen.getByText('Share all 3')).toBeTruthy();
  });

  it('opens the graphical village breakdown and full planner priority editor', async () => {
    const screen = await renderScreen();
    await fireEvent.press(screen.getByLabelText('Village completion details'));
    expect(screen.getAllByText(/levels left/).length).toBeGreaterThan(0);
    await fireEvent.press(screen.getAllByLabelText('Close')[0]!);
    await fireEvent.press(screen.getByLabelText('Priorities'));
    expect(screen.getByText('Plan priorities')).toBeTruthy();
    expect(screen.getByText('Planning goals')).toBeTruthy();
    expect(screen.getByText('Walls each week')).toBeTruthy();
    expect(screen.queryByText('Compare approaches')).toBeNull();
  });

  it('opens group summaries and preserves Flutter research subgroups', async () => {
    const screen = await renderScreen();
    await fireEvent.press(screen.getByLabelText('Defenses summary'));
    expect(screen.getByText('Levels left')).toBeTruthy();
    await fireEvent.press(screen.getByLabelText('Close'));

    await fireEvent.press(screen.getByLabelText('Laboratory'));
    expect(screen.getByText('Troops')).toBeTruthy();
    expect(screen.getByLabelText('Barbarian, level 2 of 3')).toBeTruthy();
  });

  it('keeps searchable village pages without the removed group-filter controls', async () => {
    const screen = await renderScreen();
    expect(screen.getByLabelText('Defenses')).toBeTruthy();
    expect(screen.getByLabelText('Laboratory')).toBeTruthy();
    expect(screen.queryByTestId('upgrade-tracker-home-filter')).toBeNull();

    await fireEvent.changeText(screen.getByPlaceholderText('Search upgrades'), 'barbarian');

    expect(screen.queryByLabelText('Defenses')).toBeNull();
    expect(screen.getByLabelText('Laboratory')).toBeTruthy();

    await fireEvent.press(screen.getByLabelText('Home Village'));
    await fireEvent.press(screen.getByRole('radio', { name: 'Builder Base' }));
    expect(screen.getByPlaceholderText('Search upgrades')).toBeTruthy();
    expect(screen.queryByTestId('upgrade-tracker-builder-filter')).toBeNull();
  });

  it('renders compact localized resource rows instead of backend resource identifiers', async () => {
    const base = trackerFixture();
    const resourceUpgrade = new UpgradeTrackerItem({
      id: 3,
      name: 'Resource Store',
      imageUrl: 'resource-store.png',
      village: UpgradeVillage.home,
      category: UpgradeCategory.resources,
      queue: UpgradeQueue.builders,
      currentLevel: 1,
      targetLevel: 2,
      count: 1,
      steps: [
        new UpgradeStep(
          2,
          [new UpgradeCost('builder_gold', 1_500_000), new UpgradeCost('dark_elixir', 25_000)],
          3_600,
        ),
      ],
      completedUpgradeSeconds: 0,
      totalUpgradeSeconds: 3_600,
    });
    const snapshot = new UpgradeTrackerSnapshot({
      ...base,
      items: [...base.items, resourceUpgrade],
    });
    const screen = await renderScreen(snapshot);

    await fireEvent.press(screen.getByLabelText('Home Village'));
    await fireEvent.press(screen.getByRole('radio', { name: 'Plan' }));

    expect(screen.getAllByText('Builder Gold').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Dark Elixir').length).toBeGreaterThan(0);
    expect(screen.queryByText(/builder_gold|dark_elixir/i)).toBeNull();
    expect(
      screen.getAllByTestId('upgrade-tracker-plan-resource-builder_gold').length,
    ).toBeGreaterThan(0);
    expect(
      screen.getAllByTestId('upgrade-tracker-plan-resource-dark_elixir').length,
    ).toBeGreaterThan(0);
  });

  it('keeps collection filters compact and applies ownership selections', async () => {
    const screen = await renderScreen();
    await fireEvent.press(screen.getByLabelText('Home Village'));
    await fireEvent.press(screen.getByRole('radio', { name: 'Collection' }));
    await fireEvent.press(screen.getByLabelText('Sceneries'));
    expect(screen.getByText('Forest')).toBeTruthy();

    await fireEvent.press(screen.getByTestId('upgrade-tracker-collection-filter'));
    await fireEvent.press(screen.getByText('Missing'));

    expect(screen.queryByText('Forest')).toBeNull();
    expect(screen.getByText('No matching items')).toBeTruthy();
    expect(screen.getByTestId('upgrade-tracker-collection-sort-filter')).toBeTruthy();
  });

  it('renders the 30-day Flutter timeline and opens scheduled work details', async () => {
    const screen = await renderScreen();
    await fireEvent.press(screen.getByLabelText('Home Village'));
    await fireEvent.press(screen.getByText('Calendar'));

    expect(screen.getByTestId('upgrade-tracker-calendar-scroll').props.horizontal).not.toBe(true);
    expect(screen.getByTestId('upgrade-tracker-calendar-timeline').props.horizontal).toBe(true);
    expect(screen.getByTestId('upgrade-tracker-calendar-timeline').props.nestedScrollEnabled).toBe(
      true,
    );

    expect(screen.getByText('Builders')).toBeTruthy();
    expect(screen.getAllByText('Slot 1').length).toBeGreaterThan(0);
    const cannon = screen.getByLabelText(/Cannon, level 2,/);
    await fireEvent.press(cannon);
    expect(screen.getByText('Duration')).toBeTruthy();
    expect(screen.getByText('Starts')).toBeTruthy();
    expect(screen.getByText('Finishes')).toBeTruthy();
    await fireEvent.press(
      screen.getByTestId('planned-upgrade-modal-backdrop', { includeHiddenElements: true }),
    );
    expect(screen.queryByText('Duration')).toBeNull();
  });

  it('changes pages only through the dropdown while retaining a bounded page cache', async () => {
    const screen = await renderScreen();
    expect(screen.getByTestId('upgrade-tracker-pager').props.scrollEnabled).toBe(false);
    expect(screen.queryByText('Loot outlook')).toBeNull();
    await fireEvent.press(screen.getByLabelText('Home Village'));
    await fireEvent.press(screen.getByRole('radio', { name: 'Plan' }));
    expect(await screen.findByText('Loot outlook')).toBeTruthy();
    expect(screen.getByTestId('upgrade-tracker-plan-scroll').props.horizontal).not.toBe(true);
    expect(boundedTrackerPageCache(new Set(['home', 'builder']), 'home', 'plan')).toEqual(
      new Set(['plan', 'home', 'calendar']),
    );
    expect(
      boundedTrackerPageCache(new Set(['plan', 'home', 'calendar']), 'plan', 'collection').size,
    ).toBe(3);
    await fireEvent.press(screen.getByLabelText('Plan'));
    await fireEvent.press(screen.getByRole('radio', { name: 'Collection' }));
    expect(screen.getByTestId('upgrade-tracker-collection-scroll').props.horizontal).not.toBe(true);
  });

  it('scrolls one shared hero while keeping the five-option selector pinned', async () => {
    const screen = await renderScreen();
    await fireEvent.press(screen.getByLabelText('Defenses'));
    expect(screen.getByLabelText('Cannon, level 1 of 3')).toBeTruthy();
    const header = StyleSheet.flatten(
      screen.getByTestId('upgrade-tracker-collapsible-header').props.style,
    );
    const tabs = StyleSheet.flatten(screen.getByTestId('upgrade-tracker-pinned-tabs').props.style);

    expect(header.position).toBe('absolute');
    expect(tabs.position).toBe('absolute');
    expect(tabs.height).toBe(54);
    expect(header.transform[0].translateY).toBe(0);
    await fireEvent.scroll(screen.getByTestId('upgrade-tracker-home-scroll'), {
      nativeEvent: { contentOffset: { x: 0, y: 120 } },
    });
    await fireEvent(screen.getByTestId('upgrade-tracker-home-scroll'), 'scrollEndDrag', {
      nativeEvent: { contentOffset: { x: 0, y: 120 } },
    });
    expect(screen.getByTestId('upgrade-tracker-home-scroll').props.contentOffset.y).toBe(0);
    const translated = StyleSheet.flatten(
      screen.getByTestId('upgrade-tracker-collapsible-header').props.style,
    );
    expect(translated.transform[0].translateY).toBe(-120);
    await fireEvent(screen.getByTestId('upgrade-tracker-pager'), 'pageSelected', {
      nativeEvent: { position: 3 },
    });
    await fireEvent(screen.getByTestId('upgrade-tracker-pager'), 'pageSelected', {
      nativeEvent: { position: 4 },
    });
    await fireEvent(screen.getByTestId('upgrade-tracker-pager'), 'pageSelected', {
      nativeEvent: { position: 1 },
    });
    await fireEvent(screen.getByTestId('upgrade-tracker-pager'), 'pageSelected', {
      nativeEvent: { position: 2 },
    });
    await fireEvent(screen.getByTestId('upgrade-tracker-pager'), 'pageSelected', {
      nativeEvent: { position: 0 },
    });
    expect(screen.getByTestId('upgrade-tracker-home-scroll').props.contentOffset.y).toBe(120);
    expect(screen.getByLabelText('Cannon, level 1 of 3')).toBeTruthy();
  });

  it('imports directly from the clipboard and dismisses sheets from their backdrop', async () => {
    jest.spyOn(Clipboard, 'getStringAsync').mockResolvedValue('{"tag":"#TEST"}');
    const screen = await renderScreen();

    await fireEvent.press(screen.getByLabelText('Paste account JSON'));
    expect(screen.queryByLabelText('Account JSON')).toBeNull();
    await fireEvent.press(screen.getByLabelText('Paste clipboard'));
    expect(actions.onImport).toHaveBeenCalledWith('{"tag":"#TEST"}');

    await fireEvent.press(screen.getByLabelText('Choose account'));
    expect(screen.getByLabelText('Tester')).toBeTruthy();
    await fireEvent.press(
      screen.getByTestId('upgrade-tracker-choice-modal-backdrop', {
        includeHiddenElements: true,
      }),
    );
    expect(screen.queryByLabelText('Tester')).toBeNull();
  });

  it('deduplicates exact semantic rows without collapsing legitimate collection identities', () => {
    const snapshot = trackerFixture();
    expect(uniqueUpgradeItems([snapshot.items[0]!, snapshot.items[0]!])).toHaveLength(1);

    const collection = snapshot.collections[0]!;
    const builderVariant = new UpgradeCollectionItem({
      id: collection.id,
      name: collection.name,
      imageUrl: collection.imageUrl,
      type: collection.type,
      owned: collection.owned,
      village: UpgradeVillage.builderBase,
      meta: collection.meta,
    });
    expect(uniqueCollectionItems([collection, collection, builderVariant])).toEqual([
      collection,
      builderVariant,
    ]);
  });

  it('keeps the empty-state header below the iOS status bar', async () => {
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <UpgradeTrackerScreen
              snapshot={null}
              accounts={[]}
              selectedTag={null}
              loading={false}
              error={null}
              goldPassPercent={0}
              preferences={new UpgradePlanPreferences()}
              {...actions}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    expect(
      StyleSheet.flatten(screen.getByTestId('upgrade-tracker-empty-header').props.style).paddingTop,
    ).toBe(59);
  });
});
