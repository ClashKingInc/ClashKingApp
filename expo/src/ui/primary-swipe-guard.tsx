import { createContext, useContext } from 'react';
import type { Gesture, LegacyPanGesture } from 'react-native-gesture-handler';

// Pause the primary pager for an interactive widget (including web fallback).
// Native account strips also use explicit recognizer relationships below and
// in AccountBarScrollView, rather than relying on JS state to stop the drawer.
export const PrimarySwipeGuard = createContext<(blocked: boolean) => void>(() => {});
export const usePrimarySwipeGuard = () => useContext(PrimarySwipeGuard);

// Horizontal account bars make the native pager wait for their own recognizer.
// This relationship is decided on the UI thread, not after a React state update.
export const PrimaryPageGestureContext = createContext<
  ReturnType<typeof Gesture.Native> | LegacyPanGesture | undefined
>(undefined);
