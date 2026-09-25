import { act, fireEvent, render, within } from '@testing-library/react-native';
import { Animated } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { HomeDashboardActions } from './contracts';
import { DashboardScreen } from './dashboard-screen';
import { HomeRankedCard, HomeTodoCard, HomeUpgradeCard } from './home-cards';
import { HomeAccountRail } from './home-components';

jest.mock('../../../ui', () => ({
  ...jest.requireActual('../../../ui'),
  useCKAccessibility: () => ({
    reduceMotion: false,
    reduceTransparency: false,
    highContrast: false,
  }),
}));

jest.mock('../../../core/assets/local-asset-cache', () => ({
  localImageCache: {
    subscribe: () => () => {},
    peek: () => undefined,
    resolve: jest.fn(),
    getRevision: () => 0,
  },
}));

const mockAnimatedSpring = jest.spyOn(Animated, 'spring').mockReturnValue({
  start: jest.fn(),
  stop: jest.fn(),
  reset: jest.fn(),
});

jest.mock('react-native-gesture-handler', () => {
  const ReactModule = jest.requireActual<typeof import('react')>('react');

  const Pan = () => {
    const callbacks: Record<string, (...args: never[]) => void> = {};
    const gesture = {
      callbacks,
      minDistance() {
        return this;
      },
      hitSlop() {
        return this;
      },
      shouldCancelWhenOutside() {
        return this;
      },
      runOnJS() {
        return this;
      },
      onStart(callback: (...args: never[]) => void) {
        callbacks.start = callback;
        return this;
      },
      onUpdate(callback: (...args: never[]) => void) {
        callbacks.update = callback;
        return this;
      },
      onEnd(callback: (...args: never[]) => void) {
        callbacks.end = callback;
        return this;
      },
      onFinalize(callback: (...args: never[]) => void) {
        callbacks.finalize = callback;
        return this;
      },
    };
    return gesture;
  };

  return {
    Gesture: { Pan },
    GestureDetector: ({
      children,
      gesture,
    }: {
      children: React.ReactElement;
      gesture: ReturnType<typeof Pan>;
    }) =>
      ReactModule.cloneElement(children, {
        onGestureStart: gesture.callbacks.start,
        onGestureUpdate: gesture.callbacks.update,
        onGestureEnd: gesture.callbacks.end,
        onGestureFinalize: gesture.callbacks.finalize,
      } as Record<string, unknown>),
  };
});

const mockHomeDrag = jest.fn();

jest.mock('react-native-draggable-flatlist', () => {
  const ReactModule = jest.requireActual<typeof import('react')>('react');
  const { View: MockView } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    __esModule: true,
    default: ({
      data,
      ListEmptyComponent,
      ListHeaderComponent,
      onScrollBeginDrag,
      onScrollEndDrag,
      onScrollOffsetChange,
      renderItem,
      refreshControl,
      scrollEnabled,
      testID = 'home-draggable-list',
      onDragEnd,
    }: {
      data: readonly unknown[];
      ListEmptyComponent?: React.ReactNode;
      ListHeaderComponent?: React.ReactNode;
      onScrollBeginDrag?: () => void;
      onScrollEndDrag?: () => void;
      onScrollOffsetChange?: (offset: number) => void;
      refreshControl?: React.ReactElement<{
        onRefresh?: () => void;
        refreshing?: boolean;
      }>;
      renderItem: (parameters: Record<string, unknown>) => React.ReactNode;
      scrollEnabled?: boolean;
      testID?: string;
      onDragEnd?: (parameters: Record<string, unknown>) => void;
    }) => {
      const refreshProps = ReactModule.isValidElement(refreshControl)
        ? refreshControl.props
        : undefined;
      const mockProps = {
        accessibilityLabel: scrollEnabled ? 'scroll-enabled' : 'scroll-disabled',
        accessibilityState: { busy: refreshProps?.refreshing },
        onRefresh: refreshProps?.onRefresh,
        onDragEnd,
        onScrollBeginDrag,
        onScrollEndDrag,
        onScrollOffsetChange,
        refreshControl,
        testID,
      } as unknown as React.ComponentProps<typeof MockView>;
      return ReactModule.createElement(
        MockView,
        mockProps,
        ListHeaderComponent,
        data.length
          ? data.map((item, index) =>
              ReactModule.createElement(
                ReactModule.Fragment,
                { key: index },
                renderItem({
                  item,
                  drag: mockHomeDrag,
                  isActive: false,
                  getIndex: () => index,
                }),
              ),
            )
          : ListEmptyComponent,
      );
    },
    ScaleDecorator: ({ children }: { children: React.ReactNode }) => children,
  };
});

const actions = (): HomeDashboardActions => ({
  refresh: jest.fn(async () => undefined),
  showRefreshError: jest.fn(),
  openManageAccounts: jest.fn(),
  openAnnouncement: jest.fn(),
  openTodo: jest.fn(),
  openRanked: jest.fn(),
  openUpgradeTracker: jest.fn(),
  reorderCards: jest.fn(),
});

describe('DashboardScreen states', () => {
  it('keeps the original expanding name pill without a swipeable account rail', async () => {
    const entries = ['ONE', 'TWO', 'THREE', 'FOUR', 'FIVE'].map((name) => ({
      tag: `#${name}`,
      name,
      subtitle: '',
      imageUrl: '',
    }));
    const onSelect = jest.fn();
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <HomeAccountRail entries={entries} selectedIndex={1} onSelect={onSelect} />
        </CKThemeProvider>
      </I18nProvider>,
    );
    expect(within(screen.getByRole('button', { name: 'TWO' })).getByText('TWO')).toBeTruthy();
    expect(JSON.stringify(screen.toJSON())).not.toContain('"horizontal":true');
    expect(screen.getAllByRole('button')).toHaveLength(5);
    for (const button of screen.getAllByRole('button')) {
      expect(button.props.style[0].width).toBeUndefined();
      expect(button.props.style[0]).toMatchObject({ height: 28, minWidth: 28, maxWidth: 126 });
    }
    expect(within(screen.getByRole('button', { name: 'ONE' })).queryByText('ONE')).toBeNull();
    await fireEvent.press(screen.getByRole('button', { name: 'FIVE' }));
    expect(onSelect).toHaveBeenCalledWith(4);
    await act(async () => {
      screen.rerender(
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <HomeAccountRail entries={entries} selectedIndex={4} onSelect={onSelect} />
          </CKThemeProvider>
        </I18nProvider>,
      );
    });
    expect(within(screen.getByRole('button', { name: 'FIVE' })).getByText('FIVE')).toBeTruthy();
    expect(screen.queryByText('TWO')).toBeNull();
  });
  it('shows only the saved account on desktop while keeping account switching available', async () => {
    const callbacks = actions();
    callbacks.selectAccount = jest.fn();
    const summary = (tag: string, name: string) => ({
      account: { tag, name, subtitle: tag, imageUrl: '' },
      status: `${name} status`,
      metrics: [],
      done: 0,
      total: 1,
    });
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <HomeTodoCard
            model={{ accounts: [summary('#ONE', 'One'), summary('#TWO', 'Two')] }}
            selectedAccountTag="#TWO"
            desktop
            actions={callbacks}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );
    expect(screen.getByText('Two status')).toBeTruthy();
    expect(screen.queryByText('One status')).toBeNull();
    expect(screen.queryByText('All accounts')).toBeNull();
    await fireEvent.press(screen.getByRole('button', { name: 'One' }));
    expect(callbacks.selectAccount).toHaveBeenCalledWith('#ONE');
  });
  it('shows only the selected mobile To-do panel and switches it through account chips', async () => {
    const callbacks = actions();
    callbacks.selectAccount = jest.fn();
    const summary = (tag: string, name: string) => ({
      account: { tag, name, subtitle: tag, imageUrl: '' },
      status: `${name} status`,
      metrics: [],
      done: 0,
      total: 1,
    });
    const model = { accounts: [summary('#ONE', 'One'), summary('#TWO', 'Two')] };
    const wrap = (tag: string) => (
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <HomeTodoCard
            model={model}
            selectedAccountTag={tag}
            desktop={false}
            actions={callbacks}
          />
        </CKThemeProvider>
      </I18nProvider>
    );
    const screen = await render(wrap('#TWO'));
    expect(screen.getByText('Two status')).toBeTruthy();
    expect(screen.queryByText('One status')).toBeNull();
    await fireEvent.press(screen.getByRole('button', { name: 'One' }));
    expect(callbacks.selectAccount).toHaveBeenCalledWith('#ONE');
    await screen.rerender(wrap('#ONE'));
    expect(screen.getByText('One status')).toBeTruthy();
    expect(screen.queryByText('Two status')).toBeNull();
    await screen.unmount();
  });

  it('shows only the selected mobile Ranked League and Upgrade Tracker details', async () => {
    const callbacks = actions();
    callbacks.selectAccount = jest.fn();
    const identity = (tag: string, name: string) => ({ tag, name, subtitle: tag, imageUrl: '' });
    const ranked = {
      state: 'ready' as const,
      configuredCount: 2,
      accounts: [
        {
          ...identity('#ONE', 'One'),
          tierIconUrl: '',
          trophies: 123,
          rank: 111,
          attacksDone: 1,
          defensesDone: 2,
          maxBattles: 6,
        },
        {
          ...identity('#TWO', 'Two'),
          tierIconUrl: '',
          trophies: 456,
          rank: 222,
          attacksDone: 3,
          defensesDone: 4,
          maxBattles: 6,
        },
      ],
    };
    const rankedScreen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <HomeRankedCard
            model={ranked}
            selectedAccountTag="#TWO"
            desktop={false}
            actions={callbacks}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );
    expect(rankedScreen.getByText('Group rank #222')).toBeTruthy();
    expect(rankedScreen.queryByText('Group rank #111')).toBeNull();
    await rankedScreen.unmount();

    const upgradeAccount = (tag: string, name: string, builders: number) => ({
      ...identity(tag, name),
      completion: 0.4,
      capturedAt: new Date(),
      needsUpdate: false,
      hasActionableQueueWork: false,
      builderProjectedSeconds: 0,
      labProjectedSeconds: 0,
      petProjectedSeconds: 0,
      activeBuilders: builders,
      totalBuilders: 6,
      labActive: false,
      hasLab: true,
      petsActive: false,
      hasPets: false,
      wallsAtMax: 0,
      wallsTotal: 0,
    });
    const upgrade = {
      state: 'ready' as const,
      configuredCount: 2,
      accounts: [upgradeAccount('#ONE', 'One', 1), upgradeAccount('#TWO', 'Two', 4)],
      missingAccounts: [],
      combined: {
        completion: 0.4,
        status: 'Combined status',
        builderProjectedSeconds: 0,
        labProjectedSeconds: 0,
        petProjectedSeconds: 0,
        activeBuilders: 5,
        totalBuilders: 12,
        activeLabs: 0,
        totalLabs: 2,
        activePets: 0,
        totalPets: 0,
      },
    };
    const upgradeScreen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <HomeUpgradeCard
            model={upgrade}
            selectedAccountTag="#TWO"
            desktop={false}
            actions={callbacks}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );
    expect(upgradeScreen.getByText('4/6')).toBeTruthy();
    expect(upgradeScreen.queryByText('1/6')).toBeNull();
    expect(upgradeScreen.queryByText('Combined status')).toBeNull();
    await upgradeScreen.unmount();
  });
  it('shows the exact no-linked-account action and delegates navigation', async () => {
    const callbacks = actions();
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <DashboardScreen
              platform="ios"
              model={{
                loading: false,
                linkedAccountCount: 0,
                announcements: [],
                upgradeTrackerEnabled: true,
              }}
              actions={callbacks}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    expect(screen.getByText('No linked accounts')).toBeTruthy();
    expect(
      screen.getByText('Link a Clash account to see attacks, events, and activity here.'),
    ).toBeTruthy();
    await fireEvent.press(screen.getByRole('button', { name: 'Manage Accounts' }));
    expect(callbacks.openManageAccounts).toHaveBeenCalledTimes(1);
  });

  it('renders Flutter upgrade placeholders when configured accounts have no snapshot', async () => {
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <DashboardScreen
              platform="ios"
              model={{
                loading: false,
                linkedAccountCount: 2,
                announcements: [],
                upgradeTrackerEnabled: true,
                upgrade: { state: 'empty', configuredCount: 2 },
              }}
              actions={actions()}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );
    expect(screen.getByText('Open the tracker to import or refresh upgrade data.')).toBeTruthy();
    expect(screen.getByText('2 accounts')).toBeTruthy();
    expect(screen.getAllByText('-')).toHaveLength(3);
    expect(screen.queryByTestId('home-card-drag-upgrade')).toBeNull();
    expect(screen.getByTestId('home-draggable-list').props.accessibilityLabel).toBe(
      'scroll-enabled',
    );
  });

  it('shows the todo card progress label at zero percent', async () => {
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <DashboardScreen
              platform="ios"
              model={{
                loading: false,
                linkedAccountCount: 1,
                announcements: [],
                upgradeTrackerEnabled: false,
                todo: {
                  accounts: [
                    {
                      account: {
                        tag: '#TODO',
                        name: 'Todo account',
                        subtitle: 'TH16',
                        imageUrl:
                          'https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_No_Padding.png',
                      },
                      status: 'Todo account has tasks left',
                      metrics: [{ id: 'legend', kind: 'legendAttacks', done: 0, total: 4 }],
                      done: 0,
                      total: 4,
                    },
                  ],
                },
              }}
              actions={actions()}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    expect(screen.getByText('0%')).toBeTruthy();
  });

  it('uses a native Android scroll view with a visible refresh control', async () => {
    const callbacks = actions();
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <DashboardScreen
              platform="android"
              model={{
                loading: false,
                linkedAccountCount: 1,
                announcements: [],
                upgradeTrackerEnabled: false,
                todo: {
                  accounts: [
                    {
                      account: {
                        tag: '#TODO',
                        name: 'Todo account',
                        subtitle: 'TH16',
                        imageUrl:
                          'https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_No_Padding.png',
                      },
                      status: 'Todo account has tasks left',
                      metrics: [{ id: 'legend', kind: 'legendAttacks', done: 0, total: 4 }],
                      done: 0,
                      total: 4,
                    },
                  ],
                },
              }}
              actions={callbacks}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    const scrollView = screen.getByTestId('home-scroll-view');
    await act(async () => {
      scrollView.props.refreshControl.props.onRefresh();
    });

    expect(callbacks.refresh).toHaveBeenCalledTimes(1);
    expect(scrollView.props.refreshControl).toBeTruthy();
    expect(screen.queryByTestId('home-draggable-list')).toBeNull();
  });

  const verifyAndroidCardReordering = async () => {
    const callbacks = actions();
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <DashboardScreen
              platform="android"
              model={{
                loading: false,
                linkedAccountCount: 1,
                announcements: [],
                upgradeTrackerEnabled: false,
                todo: {
                  accounts: [
                    {
                      account: {
                        tag: '#TODO',
                        name: 'Todo account',
                        subtitle: 'TH16',
                        imageUrl:
                          'https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_No_Padding.png',
                      },
                      status: 'Todo account has tasks left',
                      metrics: [{ id: 'legend', kind: 'legendAttacks', done: 0, total: 4 }],
                      done: 0,
                      total: 4,
                    },
                  ],
                },
                ranked: { state: 'empty', configuredCount: 1 },
              }}
              actions={callbacks}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    const handle = screen.getByTestId('home-card-drag-todo');
    expect(handle.props.accessibilityLabel).toBe('Reorder To-do list');
    fireEvent(screen.getByTestId('home-card-shell-todo'), 'layout', {
      nativeEvent: { layout: { x: 0, y: 0, width: 390, height: 200 } },
    });
    fireEvent(screen.getByTestId('home-card-shell-ranked'), 'layout', {
      nativeEvent: { layout: { x: 0, y: 212, width: 390, height: 180 } },
    });
    await act(async () => {
      fireEvent(handle, 'gestureStart');
    });
    expect(screen.getByTestId('home-scroll-view').props.scrollEnabled).toBe(false);
    mockAnimatedSpring.mockClear();
    await act(async () => {
      fireEvent(screen.getByTestId('home-card-drag-todo'), 'gestureUpdate', {
        translationY: 300,
      });
    });
    expect(mockAnimatedSpring).toHaveBeenCalled();
    expect(callbacks.reorderCards).not.toHaveBeenCalled();
    await act(async () => {
      fireEvent(screen.getByTestId('home-card-drag-todo'), 'gestureEnd', {
        translationY: 300,
      });
    });
    expect(callbacks.reorderCards).toHaveBeenCalledWith(['ranked', 'todo']);
  };

  it('refreshes after one full pull even if the native refresh control misses it', async () => {
    const callbacks = actions();
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <DashboardScreen
              platform="android"
              model={{
                loading: false,
                linkedAccountCount: 1,
                lastRefresh: new Date('2026-09-14T12:00:00Z'),
                announcements: [],
                upgradeTrackerEnabled: false,
                todo: {
                  accounts: [
                    {
                      account: {
                        tag: '#TODO',
                        name: 'Todo account',
                        subtitle: 'TH16',
                        imageUrl:
                          'https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_No_Padding.png',
                      },
                      status: 'Todo account has tasks left',
                      metrics: [{ id: 'legend', kind: 'legendAttacks', done: 0, total: 4 }],
                      done: 0,
                      total: 4,
                    },
                  ],
                },
              }}
              actions={callbacks}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    const list = screen.getByTestId('home-scroll-view');
    await fireEvent(list, 'scrollBeginDrag');
    await fireEvent.scroll(list, { nativeEvent: { contentOffset: { y: -80 } } });
    await fireEvent(list, 'scrollEndDrag');

    expect(callbacks.refresh).toHaveBeenCalledTimes(1);
  });

  it(
    'moves Android home cards before committing the order from the corner handle',
    verifyAndroidCardReordering,
  );
});
