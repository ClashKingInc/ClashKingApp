import { act, fireEvent, render } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { HomeDashboardActions } from './contracts';
import { DashboardScreen } from './dashboard-screen';

jest.mock('../../../core/assets/local-asset-cache', () => ({
  localImageCache: {
    subscribe: () => () => {},
    peek: () => undefined,
    resolve: jest.fn(),
    getRevision: () => 0,
  },
}));

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
    }) => {
      const refreshProps = ReactModule.isValidElement(refreshControl)
        ? refreshControl.props
        : undefined;
      const mockProps = {
        accessibilityLabel: scrollEnabled ? 'scroll-enabled' : 'scroll-disabled',
        accessibilityState: { busy: refreshProps?.refreshing },
        onRefresh: refreshProps?.onRefresh,
        onScrollBeginDrag,
        onScrollEndDrag,
        onScrollOffsetChange,
        refreshControl,
        testID: 'home-draggable-list',
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
    mockHomeDrag.mockClear();
    await fireEvent(screen.getByTestId('home-card-upgrade'), 'longPress');
    expect(mockHomeDrag).toHaveBeenCalledTimes(1);
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
});
