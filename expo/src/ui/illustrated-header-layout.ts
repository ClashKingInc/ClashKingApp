import type { useAdaptiveLayout } from './adaptive-layout';

type HeaderViewport = Pick<ReturnType<typeof useAdaptiveLayout>, 'isTablet' | 'isExpanded'>;

/** One expanded header scale for shared and feature-owned heroes. Compact
 * callers keep their existing phone geometry, including the Duo cover screen. */
export function illustratedHeaderLayout(viewport: HeaderViewport) {
  return {
    horizontal: 24,
    gap: viewport.isTablet ? 24 : 20,
    image: viewport.isTablet ? 104 : 88,
    title: viewport.isTablet ? 30 : 26,
    titleLine: viewport.isTablet ? 36 : 32,
    bodyMinHeight: viewport.isTablet ? 152 : 132,
    bottom: viewport.isTablet ? 28 : 24,
    minHeight: viewport.isTablet ? 244 : 220,
  } as const;
}
