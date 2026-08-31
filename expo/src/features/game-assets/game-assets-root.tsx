import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

import { useAppRuntime } from '../../core/app/runtime-context';
import { PlatformGameAssetActions, type GameAssetActions } from './actions';
import { GameAssetsScreen } from './game-assets-screen';
import type { GameAssetManifest } from './models';
import {
  GameAssetManifestService,
  PreferenceGameAssetManifestCache,
  type GameAssetManifestRepository,
} from './repository';

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
  const defaultRepository = useMemo(
    () =>
      new GameAssetManifestService({
        cache: new PreferenceGameAssetManifestCache(runtime.preferences),
      }),
    [runtime.preferences],
  );
  const activeRepository = repository ?? defaultRepository;
  const activeActions = useMemo(() => actions ?? new PlatformGameAssetActions(), [actions]);
  const [loadState, setLoadState] = useState<{
    readonly repository: GameAssetManifestRepository;
    readonly manifest: GameAssetManifest | null;
    readonly loading: boolean;
    readonly error: unknown;
  }>(() => ({ repository: activeRepository, manifest: null, loading: true, error: null }));
  const previousRepository = useRef(activeRepository);
  const currentState =
    loadState.repository === activeRepository
      ? loadState
      : { repository: activeRepository, manifest: null, loading: true, error: null };

  const load = useCallback(
    async (forceRefresh = false) => {
      setLoadState((current) => ({
        repository: activeRepository,
        manifest: current.repository === activeRepository ? current.manifest : null,
        loading: true,
        error: null,
      }));
      try {
        setLoadState({
          repository: activeRepository,
          manifest: await activeRepository.load({ forceRefresh }),
          loading: false,
          error: null,
        });
      } catch (nextError) {
        setLoadState((current) => ({
          repository: activeRepository,
          manifest: current.repository === activeRepository ? current.manifest : null,
          loading: false,
          error: nextError,
        }));
      }
    },
    [activeRepository],
  );

  useEffect(() => {
    let active = true;
    const repositoryChanged = previousRepository.current !== activeRepository;
    previousRepository.current = activeRepository;
    void activeRepository
      .load({ forceRefresh: repositoryChanged })
      .then((nextManifest) => {
        if (active) {
          setLoadState({
            repository: activeRepository,
            manifest: nextManifest,
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
            loading: false,
            error: nextError,
          });
        }
      });
    return () => {
      active = false;
    };
  }, [activeRepository]);

  return (
    <GameAssetsScreen
      manifest={currentState.manifest}
      loading={currentState.loading}
      error={currentState.error}
      actions={activeActions}
      onBack={onBack}
      onRefresh={() => void load(true)}
    />
  );
}
