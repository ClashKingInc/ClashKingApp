import { fireEvent, render } from '@testing-library/react-native';
import { Keyboard, StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider, type SupportedLocale } from '../../i18n';
import { CKThemeProvider } from '../../ui';
import { emptyClanSearchFilters, emptyPlayerSearchFilters } from './models';
import { SearchScreen, type SearchScreenProps } from './search-screen';

async function renderScreen(
  overrides: Partial<SearchScreenProps> = {},
  locale: SupportedLocale = 'en',
) {
  const props: SearchScreenProps = {
    query: '',
    mode: 'players',
    filtersExpanded: false,
    playerFilters: emptyPlayerSearchFilters,
    clanFilters: emptyClanSearchFilters,
    results: [],
    recents: [],
    locations: [],
    leagues: [],
    isSearching: false,
    hasSearched: false,
    onQueryChange: jest.fn(),
    onSubmit: jest.fn(),
    onModeChange: jest.fn(),
    onFiltersExpandedChange: jest.fn(),
    onPlayerFiltersChange: jest.fn(),
    onClanFiltersChange: jest.fn(),
    onOpenResult: jest.fn(),
    onOpenRecent: jest.fn(),
    ...overrides,
  };
  return {
    props,
    view: await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale={locale}>
          <CKThemeProvider preference="light">
            <SearchScreen {...props} />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    ),
  };
}

describe('SearchScreen', () => {
  it('starts in player mode and forwards query, filter, and segmented-control actions', async () => {
    const dismissKeyboard = jest.spyOn(Keyboard, 'dismiss');
    const { props, view } = await renderScreen();
    await fireEvent.changeText(view.getByLabelText("Player's name or tag"), 'Hero');
    await fireEvent.press(view.getByRole('button', { name: 'Filters' }));
    await fireEvent.press(view.getByRole('tab', { name: 'Clans' }));
    expect(props.onQueryChange).toHaveBeenCalledWith('Hero');
    expect(props.onFiltersExpandedChange).toHaveBeenCalledWith(true);
    expect(dismissKeyboard).toHaveBeenCalledTimes(1);
    expect(props.onModeChange).toHaveBeenCalledWith('clans');
    dismissKeyboard.mockRestore();
  });

  it('renders player and clan result subtitles exactly like Flutter and opens a result', async () => {
    const open = jest.fn();
    const { view } = await renderScreen({
      query: 'red',
      results: [
        {
          name: 'Red Hero',
          tag: '#P',
          townHallLevel: 17,
          clan: { name: 'Red Clan' },
          league: { name: 'Legend League' },
        },
      ],
      hasSearched: true,
      onOpenResult: open,
    });
    expect(view.getByText('Red Clan • Legend League')).toBeTruthy();
    await fireEvent.press(view.getByRole('button', { name: 'Red Hero, #P' }));
    expect(open).toHaveBeenCalledWith(expect.objectContaining({ tag: '#P' }), 'players');
  });

  it('shows only recent items matching the active entity type', async () => {
    const { view } = await renderScreen({
      mode: 'clans',
      recents: [
        {
          type: 'clan',
          name: 'Recent Clan',
          tag: '#C',
          createdAt: new Date(),
          imageUrl: 'badge',
          clanName: null,
          leagueName: null,
          members: 42,
        },
      ],
    });
    expect(view.getByText('Recent')).toBeTruthy();
    expect(view.getByText('42 members')).toBeTruthy();
  });

  it('keeps the overlay cancel action and no-result state', async () => {
    const cancel = jest.fn();
    const { view } = await renderScreen({
      overlay: true,
      query: 'none',
      hasSearched: true,
      onCancel: cancel,
    });
    expect(view.getByText('No result.')).toBeTruthy();
    await fireEvent.press(view.getByRole('button', { name: 'Cancel' }));
    expect(cancel).toHaveBeenCalledTimes(1);
  });

  it('mirrors the Flutter search composition for an app-selected RTL locale', async () => {
    const { view } = await renderScreen(
      {
        query: 'hero',
        results: [{ name: 'Hero', tag: '#P', townHallLevel: 17 }],
        hasSearched: true,
      },
      'ar',
    );
    expect(StyleSheet.flatten(view.getByTestId('search-input').props.style).textAlign).toBe(
      'right',
    );
    expect(
      StyleSheet.flatten(view.getByTestId('search-mode-selector').props.style).flexDirection,
    ).toBe('row-reverse');
    expect(
      StyleSheet.flatten(view.getByTestId('search-entity-row').props.style).flexDirection,
    ).toBe('row-reverse');
  });

  it('labels the league filter, orders leagues highest-first, and keeps option icons', async () => {
    const onPlayerFiltersChange = jest.fn();
    const { view } = await renderScreen({
      filtersExpanded: true,
      leagues: [
        { id: 1, name: 'Bronze League' },
        { id: 3, name: 'Legend League' },
      ],
      onPlayerFiltersChange,
    });
    await fireEvent.press(view.getByRole('button', { name: 'League: Not set' }));
    expect(view.getAllByText('League')).toHaveLength(2);
    expect(view.getAllByRole('radio').map((option) => option.props.accessibilityLabel)).toEqual([
      'Not set',
      'Legend League',
      'Bronze League',
    ]);
    await fireEvent.press(view.getByRole('radio', { name: 'Legend League' }));
    expect(onPlayerFiltersChange).toHaveBeenCalledWith({
      leagueIds: [3],
      minTownHallLevel: null,
      maxTownHallLevel: null,
    });
  });

  it('uses one icon-backed Town Hall picker and applies one exact API level', async () => {
    const onPlayerFiltersChange = jest.fn();
    const { view } = await renderScreen({
      filtersExpanded: true,
      playerFilters: {
        leagueIds: [],
        maxTownHallLevel: 17,
        minTownHallLevel: 17,
      },
      onPlayerFiltersChange,
    });
    await fireEvent.press(view.getByRole('button', { name: 'Town Hall: Town Hall 17' }));
    expect(
      view
        .getAllByRole('radio')
        .slice(0, 3)
        .map((option) => option.props.accessibilityLabel),
    ).toEqual(['Not set', 'Town Hall 18', 'Town Hall 17']);
    await fireEvent.press(view.getByRole('radio', { name: 'Town Hall 16' }));
    expect(onPlayerFiltersChange).toHaveBeenCalledWith({
      leagueIds: [],
      minTownHallLevel: 16,
      maxTownHallLevel: 16,
    });
  });

  it('clears both Town Hall API bounds from the same picker', async () => {
    const onPlayerFiltersChange = jest.fn();
    const { view } = await renderScreen({
      filtersExpanded: true,
      playerFilters: {
        leagueIds: [],
        minTownHallLevel: 18,
        maxTownHallLevel: 18,
      },
      onPlayerFiltersChange,
    });
    await fireEvent.press(view.getByRole('button', { name: 'Town Hall: Town Hall 18' }));
    await fireEvent.press(view.getByRole('radio', { name: 'Not set' }));
    expect(onPlayerFiltersChange).toHaveBeenCalledWith({
      leagueIds: [],
      minTownHallLevel: null,
      maxTownHallLevel: null,
    });
  });

  it('keeps the clan country picker free of search UI', async () => {
    const onClanFiltersChange = jest.fn();
    const { view } = await renderScreen({
      mode: 'clans',
      filtersExpanded: true,
      locations: [{ id: 1, name: 'United States', countryCode: 'US' }],
      onClanFiltersChange,
    });
    await fireEvent.press(view.getByRole('button', { name: 'Location: Not set' }));
    expect(view.queryByLabelText('Search locations or country codes')).toBeNull();
    await fireEvent.press(view.getByRole('radio', { name: 'United States' }));
    expect(onClanFiltersChange).toHaveBeenCalledWith({
      warFrequency: null,
      locationId: 1,
      minMembers: null,
      maxMembers: null,
      minClanPoints: null,
      minClanLevel: null,
    });
  });

  it('keeps clan filters full-width, labelled, and touch-accessible', async () => {
    const onClanFiltersChange = jest.fn();
    const { view } = await renderScreen({
      mode: 'clans',
      filtersExpanded: true,
      onClanFiltersChange,
    });
    expect(view.getByRole('button', { name: 'War frequency: Not set' })).toBeTruthy();
    expect(view.getByRole('button', { name: 'Location: Not set' })).toBeTruthy();
    expect(view.queryByText('Minimum clan points')).toBeNull();

    const members = view.getByRole('adjustable', {
      name: 'Minimum members – Maximum members',
    });
    expect(StyleSheet.flatten(members.props.style).height).toBeGreaterThanOrEqual(44);
    await fireEvent(members, 'accessibilityAction', {
      nativeEvent: { actionName: 'increment' },
    });
    expect(onClanFiltersChange).toHaveBeenCalledWith({
      warFrequency: null,
      locationId: null,
      minMembers: 1,
      maxMembers: null,
      minClanPoints: null,
      minClanLevel: null,
    });

    expect(
      view.getByRole('adjustable', { name: 'Minimum clan level' }).props.accessibilityValue.max,
    ).toBe(50);
  });

  it('places expanded filters inside the keyboard-adjusting overlay scroll area', async () => {
    const { view } = await renderScreen({
      overlay: true,
      mode: 'clans',
      filtersExpanded: true,
    });
    const scroll = view.getByTestId('search-overlay-scroll');
    expect(scroll.props.automaticallyAdjustKeyboardInsets).toBe(true);
    const filters = view.getByTestId('clan-search-filters');
    const ancestors = [];
    let ancestor = filters.parent;
    while (ancestor) {
      ancestors.push(ancestor);
      ancestor = ancestor.parent;
    }
    expect(ancestors).toContain(scroll);
  });
});
