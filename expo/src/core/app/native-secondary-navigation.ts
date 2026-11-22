import type { ReactNode } from 'react';

interface NativeSecondaryLayer {
  readonly owner?: 'wiki-link';
  readonly clanSpring?: import('../../features/clan/presentation/clan-spring-transition').ClanSpringOrigin;
  readonly content: ReactNode;
  readonly onRemove: () => void;
}

export type NativeSecondaryRouteTransition =
  | {
      readonly type: 'none' | 'dismiss';
      readonly routeKeys: readonly string[];
      readonly staleKeys: readonly string[];
    }
  | {
      readonly type: 'push' | 'replace';
      readonly key: string;
      readonly routeKeys: readonly string[];
      readonly staleKeys: readonly string[];
    };

const layers = new Map<string, NativeSecondaryLayer>();
const listeners = new Map<string, Set<() => void>>();

// Use each platform’s native push/pop animation, not a JS overlay.
// Choose transitions before navigation starts; changing options after mount
// is too late. Search expands in place, while its results remain native pushes.
export const nativeDetailScreenOptions = {
  gestureEnabled: true,
  presentation: 'card',
  animation: 'default',
  gestureDirection: 'horizontal',
} as const;

export function nativeSecondaryScreenOptions(layer?: string) {
  return layer?.includes(':utility:wiki:')
    ? {
        ...nativeDetailScreenOptions,
        // Keep the standard native slide and edge-only Back gesture. The
        // AppleZoom path waits for UIKit's late dismissal completion and can
        // block rapid reopen; horizontal tables/sliders must own interior drags.
        animation: 'slide_from_right' as const,
        fullScreenGestureEnabled: false,
        gestureResponseDistance: { end: 24 },
      }
    : layer?.startsWith('utility:search:')
      ? {
          ...nativeDetailScreenOptions,
          // The search field owns its in-place movement; the route must not fade or slide.
          animation: 'none' as const,
          gestureEnabled: false,
        }
      : nativeDetailScreenOptions;
}

export function publishNativeSecondaryLayer(key: string, layer: NativeSecondaryLayer) {
  layers.set(key, layer);
  listeners.get(key)?.forEach((listener) => listener());
}

/** A native Wiki Link owns its child pages without rerendering the app shell.
 * Preserve that tail only while its exact shell ancestry is still on screen.
 * A new utility/deep link must replace it; a native Back must never restore it. */
export function retainedNativeWikiRouteKeys(
  shellKeys: readonly string[],
  actualKeys: readonly string[],
): readonly string[] {
  if (!shellKeys.length || !shellKeys.every((key, index) => actualKeys[index] === key))
    return shellKeys;
  const tail = actualKeys.slice(shellKeys.length);
  return tail.every((key) => layers.get(key)?.owner === 'wiki-link')
    ? [...shellKeys, ...tail]
    : shellKeys;
}

export function removeNativeSecondaryLayer(key: string) {
  layers.delete(key);
  listeners.get(key)?.forEach((listener) => listener());
}

export function removeNativeSecondaryLayers(keys: Iterable<string>) {
  new Set(keys).forEach(removeNativeSecondaryLayer);
}

export function nativeSecondaryContent(key: string): ReactNode {
  return layers.get(key)?.content ?? null;
}

export function nativeSecondaryClanSpring(key: string) {
  return layers.get(key)?.clanSpring;
}

export function notifyNativeSecondaryRemoved(key: string) {
  notifyNativeSecondaryPopped(key);
  removeNativeSecondaryLayer(key);
}

/** Synchronize the owner as soon as the native stack pops, while retaining the
 * outgoing view until it unmounts. Clearing content here flashes during Back. */
export function notifyNativeSecondaryPopped(key: string) {
  layers.get(key)?.onRemove();
}

export function subscribeNativeSecondaryLayer(key: string, listener: () => void) {
  const keyListeners = listeners.get(key) ?? new Set<() => void>();
  keyListeners.add(listener);
  listeners.set(key, keyListeners);
  return () => {
    keyListeners.delete(listener);
    if (!keyListeners.size) listeners.delete(key);
  };
}

export function nativeSecondaryRouteTransition(
  current: readonly string[],
  expected: readonly string[],
): NativeSecondaryRouteTransition {
  let prefixLength = 0;
  while (
    prefixLength < current.length &&
    prefixLength < expected.length &&
    current[prefixLength] === expected[prefixLength]
  ) {
    prefixLength += 1;
  }

  const staleKeys = current.slice(prefixLength);
  const nextKey = expected[prefixLength];
  if (!expected.length && current.length) {
    return { type: 'dismiss', routeKeys: [], staleKeys };
  }
  if (nextKey === undefined) return { type: 'none', routeKeys: current, staleKeys };

  return {
    type: prefixLength < current.length ? 'replace' : 'push',
    key: nextKey,
    routeKeys: [...current.slice(0, prefixLength), nextKey],
    staleKeys,
  };
}

export function applyNativeSecondaryRouteTransition(
  transition: NativeSecondaryRouteTransition,
  navigation: {
    dismissAll: () => void;
    push: (href: { pathname: '/detail'; params: { layer: string } }) => void;
    replace: (href: { pathname: '/detail'; params: { layer: string } }) => void;
  },
) {
  if (transition.type === 'dismiss') {
    // Pop the outer detail stack without selecting Home inside the native tab
    // navigator. Returning from a Players detail must retain the Players tab.
    navigation.dismissAll();
    return;
  }
  // A replaced route stays visible while the native replacement animates.
  // NativeSecondaryRoute releases its retained content after actual removal;
  // clearing it here blanks the outgoing screen before the transition starts.
  if (transition.type !== 'replace') transition.staleKeys.forEach(removeNativeSecondaryLayer);
  if (transition.type === 'push' || transition.type === 'replace') {
    navigation[transition.type]({
      pathname: '/detail',
      params: {
        layer: transition.key,
        ...(layers.get(transition.key)?.clanSpring ? { clanSpring: '1' } : {}),
      },
    });
  }
}
