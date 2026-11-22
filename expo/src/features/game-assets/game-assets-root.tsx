import { useCallback, useContext, useEffect, useMemo, useState } from 'react';

import { useAppRuntime } from '../../core/app/runtime-context';
import { PlatformGameAssetActions, type GameAssetActions } from './actions';
import { WikiScreen } from './wiki-screen';
import { WikiCatalogueContext, wikiCatalogue, type WikiEntry } from './wiki-catalogue';
import type { GameAssetManifest } from './models';
import {
  GameAssetManifestService,
  PreferenceGameAssetManifestCache,
  type GameAssetManifestRepository,
} from './repository';

// Reuse the parsed manifest across category pushes. Re-reading and decoding the
// full asset catalogue on every route stalls navigation before it can animate.
const repositories = new WeakMap<object, GameAssetManifestService>();

/** Live replacement for Flutter's GameAssetsPage, including its embedded category subpage. */
export function GameAssetsRoot({
  onBack,
  repository,
  actions,
}: {
  readonly onBack: () => void;
  readonly repository?: GameAssetManifestRepository;
  readonly actions?: GameAssetActions;
}) {
  const runtime = useAppRuntime();
  const inheritedCatalogue = useContext(WikiCatalogueContext);
  const [refreshRevision, setRefreshRevision] = useState(0);
  const defaultRepository = useMemo(() => {
    let existing = repositories.get(runtime.preferences);
    if (!existing) {
      existing = new GameAssetManifestService({
        cache: new PreferenceGameAssetManifestCache(runtime.preferences),
      });
      repositories.set(runtime.preferences, existing);
    }
    return existing;
  }, [runtime.preferences]);
  const activeRepository = repository ?? defaultRepository;
  const activeActions = useMemo(() => actions ?? new PlatformGameAssetActions(), [actions]);
  const [loadState, setLoadState] = useState<{
    readonly repository: GameAssetManifestRepository;
    readonly manifest: GameAssetManifest | null;
    readonly catalogue: readonly WikiEntry[];
    readonly loading: boolean;
    readonly error: unknown;
  }>(() => {
    const manifest =
      activeRepository instanceof GameAssetManifestService ? activeRepository.peek() : null;
    return {
      repository: activeRepository,
      manifest,
      catalogue: inheritedCatalogue ?? (manifest ? wikiCatalogue(manifest) : []),
      loading: !inheritedCatalogue && !manifest,
      error: null,
    };
  });
  const currentState =
    loadState.repository === activeRepository
      ? loadState
      : { repository: activeRepository, manifest: null, catalogue: [], loading: true, error: null };

  const load = useCallback(
    async (forceRefresh = false) => {
      setLoadState((current) => ({
        repository: activeRepository,
        manifest: current.repository === activeRepository ? current.manifest : null,
        catalogue: current.repository === activeRepository ? current.catalogue : [],
        loading: true,
        error: null,
      }));
      try {
        // Refresh metadata and artwork together before replacing a visible grid.
        if (forceRefresh) await runtime.gameData.refreshStaticDataIfChanged();
        const manifest = await activeRepository.load({ forceRefresh });
        setLoadState({
          repository: activeRepository,
          manifest,
          catalogue: wikiCatalogue(manifest),
          loading: false,
          error: null,
        });
        setRefreshRevision((revision) => revision + 1);
      } catch (nextError) {
        setLoadState((current) => ({
          repository: activeRepository,
          manifest: current.repository === activeRepository ? current.manifest : null,
          catalogue: current.repository === activeRepository ? current.catalogue : [],
          loading: false,
          error: nextError,
        }));
      }
    },
    [activeRepository, runtime.gameData],
  );

  useEffect(() => {
    let active = true;
    // Child routes inherit the source visit. Background manifest/data refreshes
    // must not replace portraits, insert cards or rebuild a retained grid.
    if (
      inheritedCatalogue ||
      (activeRepository instanceof GameAssetManifestService && activeRepository.peek())
    )
      return;
    void activeRepository
      .load()
      .then((nextManifest) => {
        if (active) {
          setLoadState({
            repository: activeRepository,
            manifest: nextManifest,
            catalogue: wikiCatalogue(nextManifest),
            loading: false,
            error: null,
          });
        }
      })
      .catch((nextError: unknown) => {
        if (active) {
          setLoadState({
            repository: activeRepository,
            manifest: null,
            catalogue: [],
            loading: false,
            error: nextError,
          });
        }
      });
    return () => {
      active = false;
    };
  }, [activeRepository, inheritedCatalogue]);

  return (
    <WikiScreen
      manifest={currentState.manifest}
      catalogue={
        refreshRevision ? currentState.catalogue : (inheritedCatalogue ?? currentState.catalogue)
      }
      loading={currentState.loading}
      error={currentState.error}
      actions={activeActions}
      onBack={onBack}
      onRefresh={() => {
        void load(true);
      }}
    />
  );
}
