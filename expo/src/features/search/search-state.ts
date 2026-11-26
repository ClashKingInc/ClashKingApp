import type { JsonRecord } from './models';

export const SEARCH_DEBOUNCE_MS = 450;
export const SEARCH_PAGE_SIZE = 20;
const minimumQueryLength = 3;

export type SearchQuery =
  | { readonly kind: 'empty' | 'tooShort' | 'invalidTag' }
  | { readonly kind: 'text' | 'tag'; readonly value: string };

export function classifySearchQuery(value: string): SearchQuery {
  const query = value.trim();
  if (!query) return { kind: 'empty' };
  if (query.startsWith('#')) {
    if (query.length <= minimumQueryLength) return { kind: 'tooShort' };
    const tag = query.toUpperCase().replace(/O/g, '0');
    return /^#[0289PYLQGRJCUV]{3,15}$/.test(tag)
      ? { kind: 'tag', value: tag }
      : { kind: 'invalidTag' };
  }
  return query.length < minimumQueryLength
    ? { kind: 'tooShort' }
    : { kind: 'text', value: query };
}

export interface SearchPage {
  readonly results: readonly JsonRecord[];
  readonly nextCursor: string | null;
}

export interface SearchRequestState extends SearchPage {
  readonly version: number;
  readonly status: 'idle' | 'loading' | 'success' | 'error';
  readonly paginationStatus: 'idle' | 'loading' | 'error' | 'expired';
}

export const initialSearchRequestState: SearchRequestState = Object.freeze({
  version: 0,
  status: 'idle',
  results: [],
  nextCursor: null,
  paginationStatus: 'idle',
});

export function invalidateSearch(state: SearchRequestState): SearchRequestState {
  return { ...initialSearchRequestState, version: state.version + 1 };
}
