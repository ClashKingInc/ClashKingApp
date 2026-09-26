import { act, fireEvent, render, waitFor } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { BookmarkedClan } from '../../../core/bookmarks/bookmark-service';
import type { Player } from '../../player/models/player';
import type { Clan } from '../models';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { buildClanRoster, type ClansPresentationActions, type ClansPresentationModel } from './contracts';
import { ClansScreen } from './clans-screen';

jest.mock('../../../core/assets/local-asset-cache', () => ({
  localImageCache: {
    subscribe: () => () => {},
    peek: () => undefined,
    resolve: jest.fn(),
    getRevision: () => 0,
  },
}));

jest.mock('react-native-draggable-flatlist', () => {
  const ReactModule = jest.requireActual<typeof import('react')>('react');
  const { View: MockView } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    __esModule: true,
    default: ({ data, ListHeaderComponent, ListEmptyComponent, renderItem, onDragEnd, onScrollBeginDrag, onScrollEndDrag, onScrollOffsetChange }: {
      data: readonly unknown[];
      ListHeaderComponent?: React.ReactNode;
      ListEmptyComponent?: React.ReactNode;
      renderItem: (params: Record<string, unknown>) => React.ReactNode;
      onDragEnd: (params: { data: unknown[]; from: number; to: number }) => void;
      onScrollBeginDrag?: () => void;
      onScrollEndDrag?: () => void;
      onScrollOffsetChange?: (offset: number) => void;
    }) => ReactModule.createElement(MockView as React.ComponentType<Record<string, unknown>>, { testID: 'clan-draggable-list', onDragEnd, onScrollBeginDrag, onScrollEndDrag, onScroll: (event: { nativeEvent: { contentOffset: { y: number } } }) => onScrollOffsetChange?.(event.nativeEvent.contentOffset.y) },
      ListHeaderComponent,
      data.length ? data.map((item, index) => ReactModule.createElement(ReactModule.Fragment,
        { key: index }, renderItem({ item, drag: jest.fn(), isActive: false }))) : ListEmptyComponent,
    ),
    ScaleDecorator: ({ children }: { children: React.ReactNode }) => children,
  };
});

const makeActions = (): ClansPresentationActions => ({
  refresh: jest.fn(async () => undefined),
  isNetworkError: jest.fn(() => false),
  openNetworkError: jest.fn(),
  showMessage: jest.fn(),
  hydrateBookmarkedClans: jest.fn(async () => undefined),
  loadClan: jest.fn(async () => {
    throw new Error('unused');
  }),
  openClan: jest.fn(),
  reorderLinkedClans: jest.fn(async () => undefined),
  reorderBookmarkedClans: jest.fn(async () => undefined),
});

function renderScreen(model: ClansPresentationModel, actions: ClansPresentationActions) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ClansScreen model={model} actions={actions} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

describe('ClansScreen states', () => {
  it('isolates linked clans from direct clan bookmarks and persists both tab orders', async () => {
    const clan = (tag: string, name: string) => ({
      tag, name, members: 42, clanPoints: 0, type: '', location: null, warLeague: null,
    }) as Clan;
    const linkedA = clan('#A', 'Linked A');
    const linkedB = clan('#B', 'Linked B');
    const model: ClansPresentationModel = {
      profiles: [
        { tag: '#P1', clanTag: '#A', clan: linkedA },
        { tag: '#P2', clanTag: '#B', clan: linkedB },
      ] as Player[],
      bookmarks: [
        new BookmarkedClan('#A', 'Linked duplicate', '', 1, 1),
        new BookmarkedClan('#C', 'Bookmarked C', '', 1, 1),
        new BookmarkedClan('#D', 'Bookmarked D', '', 1, 1),
      ],
      hydratedClans: [],
    };
    const callbacks = makeActions();
    const screen = await renderScreen(model, callbacks);
    expect(screen.getByRole('tab', { name: 'Linked' }).props.accessibilityState.selected).toBe(true);
    expect(screen.getByTestId('clan-roster-card-#A')).toBeTruthy();
    expect(screen.getByTestId('clan-roster-card-#B')).toBeTruthy();
    expect(screen.queryByTestId('clan-roster-card-#C')).toBeNull();
    const roster = buildClanRoster(model);
    await act(async () => fireEvent(screen.getByTestId('clan-draggable-list'), 'dragEnd', {
      data: [roster.items[1], roster.items[0]], from: 0, to: 1,
    }));
    expect(callbacks.reorderLinkedClans).toHaveBeenCalledWith(['#B', '#A']);

    await act(async () => fireEvent.press(screen.getByRole('tab', { name: 'Bookmarked' })));
    expect(screen.queryByTestId('clan-roster-card-#A')).toBeNull();
    expect(screen.getByTestId('clan-roster-card-#C')).toBeTruthy();
    expect(screen.getByTestId('clan-roster-card-#D')).toBeTruthy();
    await act(async () => fireEvent(screen.getByTestId('clan-draggable-list'), 'dragEnd', {
      data: [roster.items[3], roster.items[2]], from: 0, to: 1,
    }));
    expect(callbacks.reorderBookmarkedClans).toHaveBeenCalledWith(['#D', '#C']);
  });
  it('refreshes after one full pull on the native scroll view', async () => {
    const actions = makeActions();
    const screen = await renderScreen({ profiles: [], bookmarks: [], hydratedClans: [] }, actions);
    const scroll = screen.getByTestId('clan-draggable-list');

    await act(async () => {
      fireEvent(scroll, 'scrollBeginDrag');
      fireEvent.scroll(scroll, { nativeEvent: { contentOffset: { y: -80 } } });
      fireEvent(scroll, 'scrollEndDrag');
    });

    expect(actions.refresh).toHaveBeenCalledTimes(1);
  });
  it('renders the exact no-clan state', async () => {
    const screen = await renderScreen(
      { profiles: [], bookmarks: [], hydratedClans: [] },
      makeActions(),
    );
    expect(screen.getByText('No clan')).toBeTruthy();
    expect(screen.getByText('Join a clan to unlock new features.')).toBeTruthy();
  });

  it('requests each missing bookmark once', async () => {
    const actions = makeActions();
    const model: ClansPresentationModel = {
      profiles: [],
      bookmarks: [new BookmarkedClan('#BOOK', 'Bookmark', '', 0, 0)],
      hydratedClans: [],
    };
    const screen = await renderScreen(model, actions);
    await waitFor(() => expect(actions.hydrateBookmarkedClans).toHaveBeenCalledWith(['#BOOK']));
    screen.rerender(
      <SafeAreaProvider>
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <ClansScreen model={{ ...model }} actions={actions} />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );
    await waitFor(() => expect(actions.hydrateBookmarkedClans).toHaveBeenCalledTimes(1));
  });
});
