import { DESKTOP_SIDEBAR_WIDTH, resolveMobileDrawerWidth, resolveShellLayout } from '../contracts';

describe('Flutter navigation shell contracts', () => {
  it('uses the exact web-only desktop breakpoint and sidebar width', () => {
    expect(DESKTOP_SIDEBAR_WIDTH).toBe(264);
    expect(resolveShellLayout('web', 899)).toBe('mobile');
    expect(resolveShellLayout('web', 900)).toBe('desktop');
    expect(resolveShellLayout('ios', 1200)).toBe('mobile');
    expect(resolveShellLayout('android', 1200)).toBe('mobile');
  });

  it("caps the mobile drawer at Flutter's 82 percent or 330 pixels", () => {
    expect(resolveMobileDrawerWidth(390)).toBeCloseTo(319.8);
    expect(resolveMobileDrawerWidth(1000)).toBe(330);
  });
});
