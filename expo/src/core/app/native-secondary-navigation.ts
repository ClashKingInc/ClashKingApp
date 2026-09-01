import type { ReactNode } from 'react';

interface NativeSecondaryLayer {
  readonly content: ReactNode;
  readonly onRemove: () => void;
}

export type NativeSecondaryRouteTransition =
  | {
      readonly type: 'none';
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

export function publishNativeSecondaryLayer(key: string, layer: NativeSecondaryLayer) {
  layers.set(key, layer);
  listeners.get(key)?.forEach((listener) => listener());
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

export function notifyNativeSecondaryRemoved(key: string) {
  layers.get(key)?.onRemove();
  removeNativeSecondaryLayer(key);
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
  if (nextKey === undefined) return { type: 'none', routeKeys: current, staleKeys };

  return {
    type: prefixLength < current.length ? 'replace' : 'push',
    key: nextKey,
    routeKeys: [...current.slice(0, prefixLength), nextKey],
    staleKeys,
  };
}
