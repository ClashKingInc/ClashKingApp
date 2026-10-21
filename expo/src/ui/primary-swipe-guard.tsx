import { createContext, useContext } from 'react';

// A touch that starts on a paged widget belongs to that widget, not the
// native outer PagerView. Vertical scrolling and long-press reorder stay free.
export const PrimarySwipeGuard = createContext<(blocked: boolean) => void>(() => {});
export const usePrimarySwipeGuard = () => useContext(PrimarySwipeGuard);
