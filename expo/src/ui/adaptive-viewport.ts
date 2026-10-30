import { createContext } from 'react';

/** Dimensions of the content pane, not the complete native window. A Duo
 * fold can reserve part of that window while its navigation stays in place. */
export type AdaptiveViewport = {
  width: number;
  height: number;
  constrained: boolean;
};

export const AdaptiveViewportContext = createContext<AdaptiveViewport | null>(null);
