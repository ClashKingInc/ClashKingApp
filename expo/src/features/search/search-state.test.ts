import {
  SEARCH_DEBOUNCE_MS,
  SEARCH_MIN_QUERY_LENGTH,
  beginSearch,
  completeSearch,
  failSearch,
  invalidateSearch,
  initialSearchRequestState,
  changeSearchMode,
} from './search-state';

describe('search request state', () => {
  it('retains the exact 450ms debounce and three-character minimum', () => {
    expect(SEARCH_DEBOUNCE_MS).toBe(450);
    expect(SEARCH_MIN_QUERY_LENGTH).toBe(3);
    const short = beginSearch(initialSearchRequestState, ' ab ');
    expect(short.shouldSearch).toBe(false);
    expect(short.state).toMatchObject({ hasSearched: false, results: [] });
    expect(beginSearch(short.state, ' abc ').shouldSearch).toBe(true);
  });

  it('does not issue the same completed query twice', () => {
    const started = beginSearch(initialSearchRequestState, 'Hero').state;
    const completed = completeSearch(started, started.version, [{ tag: '#P' }]);
    expect(beginSearch(completed, ' Hero ').shouldSearch).toBe(false);
  });

  it('suppresses stale success and failure responses by request version', () => {
    const first = beginSearch(initialSearchRequestState, 'first').state;
    const second = beginSearch(first, 'second').state;
    expect(completeSearch(second, first.version, [{ tag: '#OLD' }])).toBe(second);
    expect(failSearch(second, first.version)).toBe(second);
    expect(completeSearch(second, second.version, [{ tag: '#NEW' }])).toMatchObject({
      results: [{ tag: '#NEW' }],
      isSearching: false,
    });
  });

  it('invalidates an in-flight request when filters or entity mode change', () => {
    const searching = beginSearch(initialSearchRequestState, 'Hero').state;
    const filterChanged = invalidateSearch(searching);
    expect(filterChanged).toMatchObject({
      version: searching.version + 1,
      results: [],
      lastQuery: '',
      isSearching: false,
      hasSearched: false,
    });
    expect(completeSearch(filterChanged, searching.version, [{ tag: '#STALE' }])).toBe(
      filterChanged,
    );

    const modeChanged = changeSearchMode(searching, 'clans');
    expect(modeChanged).toMatchObject({
      version: searching.version + 1,
      results: [],
      lastQuery: '',
      isSearching: false,
      hasSearched: false,
    });
    expect(completeSearch(modeChanged, searching.version, [{ tag: '#PLAYER' }])).toBe(modeChanged);
  });
});
