import { ckBreakpoints } from '../ui/tokens';

export const DESKTOP_SIDEBAR_WIDTH = 264;
export const PRIMARY_TAB_BAR_HEIGHT = 62;
export const PRIMARY_TAB_BAR_TOP_PADDING = 4;
export const IOS_PRIMARY_TAB_BAR_MIN_HEIGHT = 78;
export const WEB_PRIMARY_TAB_BAR_HEIGHT = 64;

export function fallbackTabBarBottomPadding(bottomInset: number): number {
  return bottomInset > 0 ? bottomInset : 10;
}

export function primaryTabBarClearance(
  platform: string,
  viewportWidth: number,
  bottomInset: number,
): number {
  if (resolveShellLayout(platform, viewportWidth) === 'desktop') return bottomInset;
  if (platform === 'web') return WEB_PRIMARY_TAB_BAR_HEIGHT + bottomInset;
  const barHeight = PRIMARY_TAB_BAR_HEIGHT + PRIMARY_TAB_BAR_TOP_PADDING;
  if (platform === 'ios') {
    return Math.max(IOS_PRIMARY_TAB_BAR_MIN_HEIGHT, barHeight + bottomInset);
  }
  return barHeight + fallbackTabBarBottomPadding(bottomInset);
}

export function resolveMobileDrawerWidth(viewportWidth: number): number {
  return Math.min(viewportWidth * 0.82, 330);
}

export function resolveShellLayout(platform: string, width: number): 'mobile' | 'desktop' {
  return platform === 'web' && width >= ckBreakpoints.desktop ? 'desktop' : 'mobile';
}
