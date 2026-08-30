import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { View } from 'react-native';

import { useAppRuntime } from '../../core/app/runtime-context';
import { useI18n } from '../../i18n';
import { SkeletonLoadingDialog, Snackbar } from '../../ui';
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
  beginSearch,
  changeSearchMode,
  completeSearch,
  failSearch,
  initialSearchRequestState,
  invalidateSearch,
  type SearchRequestState,
} from './search-state';

export interface SearchRootProps {
  readonly overlay?: boolean;
  readonly autofocus?: boolean;
  readonly onCancel?: () => void;
  readonly onOpenPlayer: (player: Player) => void;
  readonly onOpenClan: (clan: Clan) => void;
}

/** Live replacement for Flutter's utility-page and global-overlay SearchPage variants. */
export function SearchRoot({
  overlay = false,
  autofocus = false,
  onCancel,
  onOpenPlayer,
  onOpenClan,
}: SearchRootProps) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const service = useMemo(() => new SearchService(runtime.api), [runtime.api]);
  const [query, setQuery] = useState('');
  const [mode, setMode] = useState<SearchMode>('players');
  const [filtersExpanded, setFiltersExpanded] = useState(false);
  const [playerFilters, setPlayerFiltersState] = useState(emptyPlayerSearchFilters);
  const [clanFilters, setClanFiltersState] = useState(emptyClanSearchFilters);
  const [requestState, setRequestState] = useState(initialSearchRequestState);
  const requestRef = useRef<SearchRequestState>(initialSearchRequestState);
  const [recents, setRecents] = useState<readonly RecentSearchItem[]>([]);
  const [locations, setLocations] = useState<readonly SearchLocation[]>([]);
  const [leagues, setLeagues] = useState<readonly SearchLeague[]>([]);
  const [opening, setOpening] = useState(false);
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
    const loadFilters =
      mode === 'clans'
        ? service.loadLocations().then((nextLocations) => {
            if (active) setLocations(nextLocations);
          })
        : service.loadLeagues().then((nextLeagues) => {
            if (active) setLeagues(nextLeagues);
          });
    void loadFilters.catch(() => {
      if (!active) return;
      if (mode === 'clans') setLocations([]);
      else setLeagues([]);
    });
    return () => {
      active = false;
    };
  }, [filtersExpanded, mode, service]);

  const runSearch = useCallback(async () => {
    const started = beginSearch(requestRef.current, query);
    publishRequest(started.state);
    if (!started.shouldSearch) return;
    const version = started.state.version;
    try {
      const trackingHeaders = userId ? { 'x-ck-user-id': userId } : undefined;
      const results =
        mode === 'players'
          ? await runtime.players.searchPlayers(query.trim(), {
              leagueIds: playerFilters.leagueIds,
              townHallLevels: playerTownHallLevels(playerFilters),
              extraHeaders: trackingHeaders,
            })
          : await service.searchClans(query.trim(), normalizeClanSearchFilters(clanFilters));
      publishRequest(completeSearch(requestRef.current, version, results));
    } catch {
      publishRequest(failSearch(requestRef.current, version));
    }
  }, [clanFilters, mode, playerFilters, publishRequest, query, runtime.players, service, userId]);

  useEffect(() => {
    const timer = setTimeout(() => void runSearch(), SEARCH_DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [runSearch]);

  const changeMode = (next: SearchMode) => {
    if (next === mode) return;
    setMode(next);
    setFiltersExpanded(false);
    publishRequest(changeSearchMode(requestRef.current, next));
  };
  const changePlayerFilters = (next: PlayerSearchFilters) => {
    setPlayerFiltersState(next);
    publishRequest(invalidateSearch(requestRef.current));
  };
  const changeClanFilters = (next: ClanSearchFilters) => {
    setClanFiltersState(normalizeClanSearchFilters(next));
    publishRequest(invalidateSearch(requestRef.current));
  };
  const changeQuery = (next: string) => {
    setQuery(next);
    if (!next.length) {
      publishRequest({
        ...requestRef.current,
        version: requestRef.current.version + 1,
        results: [],
        isSearching: false,
        hasSearched: false,
        lastQuery: '',
      });
    }
  };

  const openResult = async (result: JsonRecord, type: SearchMode) => {
    const tag = typeof result.tag === 'string' ? result.tag : '';
    setOpening(true);
    try {
      const trackingHeaders = userId ? { 'x-ck-user-id': userId } : undefined;
      if (type === 'players') {
        const player = await runtime.players.getPlayerAndClanData(tag, trackingHeaders);
        void loadRecents();
        onOpenPlayer(player);
      } else {
        let clan: Clan;
        try {
          clan = await runtime.clans.getClanAndWarData(tag, { extraHeaders: trackingHeaders });
        } catch {
          clan = Clan.fromJson(await service.loadClanFallback(tag, trackingHeaders));
          await runtime.clans.loadJoinLeaveForClan(clan);
        }
        void loadRecents();
        onOpenClan(clan);
      }
    } catch {
      setSnackbar(
        type === 'players' ? t('searchErrorPlayerLoadFailed') : t('searchErrorClanLoadFailed'),
      );
    } finally {
      setOpening(false);
    }
  };
  const openRecent = (item: RecentSearchItem) =>
    openResult({ tag: item.tag, name: item.name }, item.type === 'player' ? 'players' : 'clans');

  return (
    <View style={{ flex: 1 }}>
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
        isSearching={requestState.isSearching}
        hasSearched={requestState.hasSearched}
        onQueryChange={changeQuery}
        onSubmit={() => void runSearch()}
        onModeChange={changeMode}
        onFiltersExpandedChange={setFiltersExpanded}
        onPlayerFiltersChange={changePlayerFilters}
        onClanFiltersChange={changeClanFilters}
        onOpenResult={(result, type) => void openResult(result, type)}
        onOpenRecent={(item) => void openRecent(item)}
        onCancel={onCancel}
      />
      <SkeletonLoadingDialog visible={opening} />
      <Snackbar message={snackbar} onDismiss={() => setSnackbar(undefined)} />
    </View>
  );
}
