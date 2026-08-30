import { ckBreakpoints } from '../ui/tokens';

export const DESKTOP_SIDEBAR_WIDTH = 264;

export function resolveMobileDrawerWidth(viewportWidth: number): number {
  return Math.min(viewportWidth * 0.82, 330);
}

export function resolveShellLayout(platform: string, width: number): 'mobile' | 'desktop' {
  return platform === 'web' && width >= ckBreakpoints.desktop ? 'desktop' : 'mobile';
}
