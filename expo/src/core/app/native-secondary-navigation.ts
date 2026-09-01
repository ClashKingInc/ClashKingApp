import type { ReactNode } from 'react';

interface NativeSecondaryLayer {
  readonly content: ReactNode;
  readonly onRemove: () => void;
}

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
