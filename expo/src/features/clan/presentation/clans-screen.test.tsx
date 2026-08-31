import { render, waitFor } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { BookmarkedClan } from '../../../core/bookmarks/bookmark-service';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { ClansPresentationActions, ClansPresentationModel } from './contracts';
import { ClansScreen } from './clans-screen';

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
