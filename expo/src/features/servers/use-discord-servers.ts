import { useCallback, useEffect, useState } from 'react';
import { AppState, Platform } from 'react-native';
import { Effect } from 'effect';
import { GuildsEndpoint, type EndpointResponse } from '@clashking/api-contracts/expo';
import { useAppRuntime } from '../../core/app/runtime-context';
import type { AuthUser } from '../auth/models';

export type DashboardServer = EndpointResponse<typeof GuildsEndpoint>[number];

export function useDiscordServers(user: AuthUser | null | undefined) {
  const runtime = useAppRuntime();
  const userId = user?.userId;
  // A ClashKing user ID can survive conversion to email-only login. Only the
  // linked auth methods establish Discord access; email + Discord still works.
  const hasDiscordIdentity = user?.authMethods.includes('discord') === true;
  const enabled = Boolean(userId) && hasDiscordIdentity && Platform.OS !== 'web';
  const [generation, setGeneration] = useState(0);
  const [result, setResult] = useState<{
    userId: string | undefined;
    servers: readonly DashboardServer[];
    generation: number;
    error: boolean;
  }>({ userId: undefined, servers: [], generation: -1, error: false });
  const refresh = useCallback(() => setGeneration((value) => value + 1), []);
  useEffect(() => {
    if (!enabled) return;
    let active = true;
    let retry: ReturnType<typeof setTimeout> | undefined;
    const load = (attempt = 0) =>
      void Effect.runPromise(
        runtime.contractApi.execute(GuildsEndpoint, { path: {}, query: {}, body: {} }),
      )
        .then((servers) => {
          if (active) setResult({ userId, servers, generation, error: false });
        })
        .catch(() => {
          // A brief tunnel/Discord outage must not strand a fresh sign-in on an
          // empty list. Keep any known servers and bound automatic retries.
          if (active && attempt < 2) {
            retry = setTimeout(() => load(attempt + 1), 1000 * (attempt + 1));
            return;
          }
          if (active)
            setResult((current) => ({
              userId,
              servers: current.userId === userId ? current.servers : [],
              generation,
              error: true,
            }));
        });
    load();
    return () => {
      active = false;
      clearTimeout(retry);
    };
  }, [runtime, userId, enabled, generation]);
  useEffect(() => {
    if (!enabled) return;
    let previous = AppState.currentState;
    const subscription = AppState.addEventListener('change', (next) => {
      // Discord installation happens outside the app. Refresh on return without
      // polling, and share this result between the drawer and the server list.
      if (next === 'active' && previous !== 'active') refresh();
      previous = next;
    });
    return () => subscription.remove();
  }, [enabled, refresh]);
  const loading = enabled && (result.userId !== userId || result.generation !== generation);
  const current = !enabled
    ? { servers: [], loading: false, error: false }
    : {
        servers: result.userId === userId ? result.servers : [],
        loading,
        error: !loading && result.error,
      };
  return { ...current, hasDiscordIdentity, refresh };
}

export type DiscordServersState = ReturnType<typeof useDiscordServers>;

export function managesDiscordServer(server: DashboardServer): boolean {
  if (server.owner) return true;
  if (!/^\d+$/.test(server.permissions)) return false;
  return (BigInt(server.permissions) & (8n | 32n)) !== 0n;
}
