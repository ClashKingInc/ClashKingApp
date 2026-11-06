import { Platform } from 'react-native';
import type { AppRuntime } from '../../core/app/runtime';

interface RequestOptions {
  signal?: AbortSignal;
  force?: boolean;
}
interface ServiceState {
  scope: string;
  generation: number;
  cache: Map<string, { until: number; value: unknown }>;
  pending: Map<string, Promise<unknown>>;
}
// Runtime wrappers can change during React renders. The token service is the
// stable owner; environment and session changes still discard every old read.
const states = new WeakMap<AppRuntime['tokens'], ServiceState>();
export function esportsService(runtime: AppRuntime) {
  let state = states.get(runtime.tokens);
  if (!state) {
    state = { scope: '', generation: 0, cache: new Map(), pending: new Map() };
    states.set(runtime.tokens, state);
  }
  const shared = state;
  const invalidate = () => {
    shared.generation += 1;
    shared.cache.clear();
    shared.pending.clear();
  };
  async function request<T>(
    path: string,
    method = 'GET',
    body?: unknown,
    publicRead = false,
    options: RequestOptions = {},
  ): Promise<T> {
    if (options.signal?.aborted) throw new Error('Request cancelled');
    const userId = runtime.auth.state.currentUser?.userId ?? '';
    const token = publicRead ? null : await runtime.tokens.getAccessToken();
    // A refresh can finish after account switching. Never associate that old
    // credential or its response with the replacement account's cache.
    if (userId !== (runtime.auth.state.currentUser?.userId ?? ''))
      throw new Error('Session changed');
    const scope = `${runtime.configuration.apiV2Url}\n${userId}`;
    if (shared.scope !== scope) {
      invalidate();
      shared.scope = scope;
    }
    const key = `${publicRead ? 'public' : 'session'}:${path}`;
    const read = method === 'GET';
    // Cache only public CCN reads; authenticated requests always revalidate.
    const cacheable = read && publicRead && path.startsWith('/esports/');
    if (read && options.force) invalidate();
    const cached = shared.cache.get(key);
    if (cacheable && !options.force && cached && cached.until > Date.now())
      return cached.value as T;
    const generation = shared.generation;
    const execute = async (): Promise<T> => {
      const multipart = body instanceof FormData;
      const controller = new AbortController();
      // Allow the API's bounded full-ladder query to finish; basic discovery
      // and profile reads retain the short interactive timeout.
      const timeout = /^\/esports\/ccn\/elo(?:-(?:matches|team))?(?:\?|$)/u.test(path)
        ? 50_000
        : /^\/esports\/ccn\/(standings|records)(?:\?|$)/u.test(path)
          ? 35_000
          : 15_000;
      const timer = setTimeout(() => controller.abort(), timeout);
      try {
        const response = await fetch(`${runtime.configuration.apiV2Url}${path}`, {
          method,
          headers: {
            ...(body === undefined || multipart ? {} : { 'Content-Type': 'application/json' }),
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
          ...(Platform.OS === 'web'
            ? { credentials: publicRead ? ('omit' as const) : ('include' as const) }
            : {}),
          ...(body === undefined ? {} : { body: multipart ? body : JSON.stringify(body) }),
          signal: controller.signal,
        });
        if (!response.ok) {
          const error = (await response.json().catch(() => ({}))) as {
            message?: string;
            detail?: string;
          };
          throw new Error(
            error.message ??
              (typeof error.detail === 'string' ? error.detail : `HTTP ${response.status}`),
          );
        }
        const value = (response.status === 204 ? undefined : await response.json()) as T;
        if (!read) invalidate();
        else if (
          cacheable &&
          generation === shared.generation &&
          !(path.startsWith('/esports/') && (value as { data?: unknown })?.data == null)
        ) {
          if (shared.cache.size >= 100) shared.cache.delete(shared.cache.keys().next().value!);
          shared.cache.set(key, {
            // Discovery barely changes within a session; player basicinfo is
            // itself cached by CCN for two minutes. Avoid making a Back action
            // start the same slow provider request again a minute later.
            until:
              Date.now() +
              (/\/esports\/ccn\/(events|divisions|segments)(?:\?|$)/u.test(path)
                ? 300_000
                : 120_000),
            value,
          });
        }
        return value;
      } finally {
        clearTimeout(timer);
      }
    };
    let result =
      read && !options.force ? (shared.pending.get(key) as Promise<T> | undefined) : undefined;
    if (!result) {
      result = execute();
      if (read) {
        shared.pending.set(key, result);
        const current = result;
        void result
          .finally(() => {
            if (shared.pending.get(key) === current) shared.pending.delete(key);
          })
          .catch(() => {});
      }
    }
    // Cancelling one mounted consumer must not cancel a shared fetch for others.
    if (!options.signal) return result;
    return new Promise<T>((resolve, reject) => {
      const signal = options.signal!;
      const abort = () => reject(new Error('Request cancelled'));
      signal.addEventListener('abort', abort, { once: true });
      if (signal.aborted) abort();
      void result!.then(resolve, reject).finally(() => signal.removeEventListener('abort', abort));
    });
  }
  return { request, invalidate };
}
