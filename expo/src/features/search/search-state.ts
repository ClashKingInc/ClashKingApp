import type { JsonRecord, SearchMode } from './models';

export const SEARCH_DEBOUNCE_MS = 450;
export const SEARCH_MIN_QUERY_LENGTH = 3;
export const SEARCH_RECENT_LIMIT = 10;

export interface SearchRequestState {
  readonly lastQuery: string;
  readonly version: number;
  readonly isSearching: boolean;
  readonly hasSearched: boolean;
  readonly results: readonly JsonRecord[];
}

export const initialSearchRequestState: SearchRequestState = Object.freeze({
  lastQuery: '',
  version: 0,
  isSearching: false,
  hasSearched: false,
  results: [],
});

export function beginSearch(
  state: SearchRequestState,
  rawQuery: string,
): { readonly state: SearchRequestState; readonly shouldSearch: boolean } {
  const query = rawQuery.trim();
  if (query === state.lastQuery && state.hasSearched) return { state, shouldSearch: false };
  const version = state.version + 1;
  if (query.length < SEARCH_MIN_QUERY_LENGTH) {
    return {
      shouldSearch: false,
      state: { lastQuery: query, version, isSearching: false, hasSearched: false, results: [] },
    };
  }
  return {
    shouldSearch: true,
    state: { ...state, lastQuery: query, version, isSearching: true, hasSearched: true },
  };
}

export function completeSearch(
  state: SearchRequestState,
  version: number,
  results: readonly JsonRecord[],
): SearchRequestState {
  return version === state.version ? { ...state, results, isSearching: false } : state;
}

export function failSearch(state: SearchRequestState, version: number): SearchRequestState {
  return version === state.version ? { ...state, results: [], isSearching: false } : state;
}

export function changeSearchMode(state: SearchRequestState, _mode: SearchMode): SearchRequestState {
  return {
    ...state,
    version: state.version + 1,
    results: [],
    lastQuery: '',
    isSearching: false,
    hasSearched: false,
  };
}

export function invalidateSearch(state: SearchRequestState): SearchRequestState {
  return {
    ...state,
    version: state.version + 1,
    results: [],
    lastQuery: '',
    isSearching: false,
    hasSearched: false,
  };
}
