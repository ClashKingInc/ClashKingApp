import { ApiResponseError } from '@clashking/api-client';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useLinkParameters, linkChoice } from '../../core/deep-links/link-parameters';
import { Keyboard, KeyboardAvoidingView, Platform } from 'react-native';

import { useAppRuntime } from '../../core/app/runtime-context';
import { useI18n } from '../../i18n';
import { PageLoading, Snackbar } from '../../ui';
import { Clan } from '../clan/models';
import type { Player } from '../player/models/player';
import {
  emptyClanSearchFilters,
  emptyPlayerSearchFilters,
  normalizeClanSearchFilters,
  playerTownHallLevels,
  type ClanSearchFilters,
  type JsonRecord,
  type PlayerSearchFilters,
  type RecentSearchItem,
  type SearchLeague,
  type SearchLocation,
  type SearchMode,
} from './models';
import { SearchScreen } from './search-screen';
import { SearchService } from './search-service';
import {
  SEARCH_DEBOUNCE_MS,
  classifySearchQuery,
  initialSearchRequestState,
  invalidateSearch,
  type SearchRequestState,
} from './search-state';

export interface SearchRootProps {
  readonly onOpenDestination?: (request: {
    kind: 'player' | 'clan';
    seed: JsonRecord;
    load: () => Promise<SearchDestinationResult>;
  }) => void;
  readonly initialQuery?: string;
  readonly overlay?: boolean;
  readonly autofocus?: boolean;
  readonly onCancel?: () => void;
  readonly onOpenPlayer: (player: Player) => void;
  readonly onOpenClan: (clan: Clan) => void;
}

export type SearchDestinationResult =
  | { readonly kind: 'player'; readonly player: Player }
  | { readonly kind: 'clan'; readonly clan: Clan };

/** Live replacement for Flutter's utility-page and global-overlay SearchPage variants. */
export function SearchRoot({
  initialQuery,
  overlay = false,
  autofocus = false,
  onCancel,
  onOpenPlayer,
  onOpenClan,
  onOpenDestination,
}: SearchRootProps) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const service = useMemo(() => new SearchService(runtime.contractApi), [runtime.contractApi]);
  const link = useLinkParameters();
  const [query, setQuery] = useState(initialQuery ?? link.q ?? '');
  const [mode, setMode] = useState<SearchMode>(
    linkChoice(link.type, ['players', 'clans'], 'players'),
  );
  const [filtersExpanded, setFiltersExpanded] = useState(false);
  const [playerFilters, setPlayerFiltersState] = useState(emptyPlayerSearchFilters);
  const [clanFilters, setClanFiltersState] = useState(emptyClanSearchFilters);
  const [requestState, setRequestState] = useState(initialSearchRequestState);
  const requestRef = useRef<SearchRequestState>(initialSearchRequestState);
  const searchTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const [recents, setRecents] = useState<readonly RecentSearchItem[]>([]);
  const [locations, setLocations] = useState<readonly SearchLocation[]>([]);
  const [leagues, setLeagues] = useState<readonly SearchLeague[]>([]);
  const [filterOptionsStatus, setFilterOptionsStatus] = useState<'loading' | 'ready' | 'error'>(
    'loading',
  );
  const [filterOptionsAttempt, setFilterOptionsAttempt] = useState(0);
  const [opening, setOpening] = useState(false);
  const mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  const [snackbar, setSnackbar] = useState<string>();
  const userId = runtime.auth.state.currentUser?.userId.trim() || null;

  const publishRequest = useCallback((next: SearchRequestState) => {
    requestRef.current = next;
    setRequestState(next);
  }, []);

  const loadRecents = useCallback(async () => {
    const expectedUserId = runtime.auth.state.currentUser?.userId.trim() || null;
    const items = await service.loadRecents(expectedUserId);
    if ((runtime.auth.state.currentUser?.userId.trim() || null) === expectedUserId)
      setRecents(items);
  }, [runtime.auth, service]);

  useEffect(() => {
    void service.loadRecents(userId).then((items) => {
      if ((runtime.auth.state.currentUser?.userId.trim() || null) === userId) setRecents(items);
    });
    return runtime.auth.subscribe(() => void loadRecents());
  }, [loadRecents, runtime.auth, service, userId]);

  useEffect(() => {
    if (!filtersExpanded) return undefined;
    let active = true;
    const loadFilters = async () => {
      try {
        if (mode === 'clans') {
          const options = await service.loadLocations();
          if (active) setLocations(options);
        } else {
          const options = await service.loadLeagues();
          if (active) setLeagues(options);
        }
        if (active) setFilterOptionsStatus('ready');
      } catch {
        if (active) setFilterOptionsStatus('error');
      }
    };
    void loadFilters();
    return () => {
      active = false;
    };
  }, [filterOptionsAttempt, filtersExpanded, mode, service]);

  const searchText = query.trim();
  const runSearch = useCallback(
    async (retry = false) => {
      const request = requestRef.current;
      if (request.status !== 'idle' && !(retry && request.status === 'error')) return;
      const search = classifySearchQuery(searchText);
      if (search.kind !== 'tag' && search.kind !== 'text') return;

      const version = request.version + 1;
      publishRequest({ version, status: 'loading', results: [] });
      const finish = (status: 'success' | 'error', results: readonly JsonRecord[] = []) => {
        if (mounted.current && requestRef.current.version === version) {
          publishRequest({ version, status, results });
        }
      };
      try {
        const trackingHeaders =
          userId && Platform.OS !== 'web' ? { 'x-ck-user-id': userId } : undefined;
        if (search.kind === 'tag') {
          if (mode === 'clans') {
            finish('success', [await service.loadClanByTag(search.value, trackingHeaders)]);
          } else {
            const player = await runtime.players.getPlayerAndClanData(search.value, trackingHeaders);
            finish('success', [
              {
                tag: player.tag,
                name: player.name,
                townHallLevel: player.townHallLevel,
                trophies: player.trophies,
              },
            ]);
          }
          return;
        }
        const results =
          mode === 'players'
            ? await runtime.players.searchPlayers(search.value, {
                leagueIds: playerFilters.leagueIds,
                townHallLevels: playerTownHallLevels(playerFilters),
                extraHeaders: trackingHeaders,
              })
            : await service.searchClans(search.value, clanFilters);
        finish('success', results);
      } catch (error) {
        if (search.kind === 'tag' && error instanceof ApiResponseError && error.status === 404) {
          finish('success');
        } else {
          finish('error');
        }
      }
    },
    [clanFilters, mode, playerFilters, publishRequest, runtime.players, searchText, service, userId],
  );

  useEffect(() => {
    if (requestState.status !== 'idle') return;
    const timer = setTimeout(() => void runSearch(), SEARCH_DEBOUNCE_MS);
    searchTimer.current = timer;
    return () => clearTimeout(timer);
  }, [requestState.status, requestState.version, runSearch]);

  const resetSearch = () => {
    clearTimeout(searchTimer.current);
    publishRequest(invalidateSearch(requestRef.current));
  };
  const changeMode = (next: SearchMode) => {
    if (next === mode) return;
    setMode(next);
    setFiltersExpanded(false);
    resetSearch();
  };
  const changePlayerFilters = (next: PlayerSearchFilters) => {
    if (next === playerFilters) return;
    setPlayerFiltersState(next);
    if (!searchText.startsWith('#')) resetSearch();
  };
  const changeClanFilters = (next: ClanSearchFilters) => {
    if (next === clanFilters) return;
    setClanFiltersState(normalizeClanSearchFilters(next));
    if (!searchText.startsWith('#')) resetSearch();
  };
  const changeQuery = (next: string) => {
    if (next.trim() !== searchText) resetSearch();
    setQuery(next);
  };

  const openResult = async (result: JsonRecord, type: SearchMode) => {
    if (opening) return;
    const tag = typeof result.tag === 'string' ? result.tag : '';
    Keyboard.dismiss();
    const load = async (): Promise<SearchDestinationResult> => {
      const trackingHeaders =
        userId && Platform.OS !== 'web' ? { 'x-ck-user-id': userId } : undefined;
      if (type === 'players') {
        const player = await runtime.players.getPlayerAndClanData(tag, trackingHeaders);
        void loadRecents();
        return { kind: 'player', player };
      } else {
        let clan: Clan;
        try {
          clan = await runtime.clans.getClanAndWarData(tag, { extraHeaders: trackingHeaders });
        } catch {
          try {
            clan = Clan.fromJson(await service.loadClanByTag(tag, trackingHeaders));
          } catch {
            // Search already returned enough identity data to open a useful clan detail shell.
            // This keeps web navigation responsive when the follow-up proxy request is blocked.
            clan = Clan.fromJson(result);
          }
          void runtime.clans.loadJoinLeaveForClan(clan);
        }
        void loadRecents();
        return { kind: 'clan', clan };
      }
    };
    if (onOpenDestination) {
      onOpenDestination({ kind: type === 'players' ? 'player' : 'clan', seed: result, load });
      return;
    }
    // Standalone consumers without shell navigation retain their existing handoff.
    setOpening(true);
    try {
      const destination = await load();
      if (!mounted.current) return;
      if (destination.kind === 'player') onOpenPlayer(destination.player);
      else onOpenClan(destination.clan);
    } catch (error) {
      if (!mounted.current) return;
      setSnackbar(
        error instanceof ApiResponseError && error.status===404 ? t('accountsErrorTagNotExists') :
        type === 'players' ? t('searchErrorPlayerLoadFailed') : t('searchErrorClanLoadFailed'),
      );
    } finally {
      setOpening(false);
    }
  };
  const openRecent = (item: RecentSearchItem) =>
    openResult({ tag: item.tag, name: item.name }, item.type === 'player' ? 'players' : 'clans');

  // On iOS, padding the overlay avoids the ScrollView resetting its offset when the keyboard hides.
  return (
    <KeyboardAvoidingView
      behavior={overlay && Platform.OS === 'ios' ? 'padding' : undefined}
      style={{ flex: 1 }}
    >
      <SearchScreen
        overlay={overlay}
        autofocus={autofocus}
        query={query}
        mode={mode}
        filtersExpanded={filtersExpanded}
        playerFilters={playerFilters}
        clanFilters={clanFilters}
        results={requestState.results}
        recents={recents}
        locations={locations}
        leagues={leagues}
        searchStatus={requestState.status}
        filterOptionsStatus={filterOptionsStatus}
        onRetryFilterOptions={() => {
          setFilterOptionsStatus('loading');
          setFilterOptionsAttempt((attempt) => attempt + 1);
        }}
        onQueryChange={changeQuery}
        onSubmit={() => void runSearch(true)}
        onModeChange={changeMode}
        onFiltersExpandedChange={(expanded) => {
          if (expanded) setFilterOptionsStatus('loading');
          setFiltersExpanded(expanded);
        }}
        onPlayerFiltersChange={changePlayerFilters}
        onClanFiltersChange={changeClanFilters}
        onOpenResult={openResult}
        onOpenRecent={(item) => void openRecent(item)}
        onCancel={onCancel}
      />
      <PageLoading visible={opening} />
      <Snackbar message={snackbar} onDismiss={() => setSnackbar(undefined)} />
    </KeyboardAvoidingView>
  );
}
