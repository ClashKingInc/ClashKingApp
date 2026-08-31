import { describe, expect, it } from '@jest/globals';

import { resolveGridColumns } from '../layout';
import { durationForMotion, resolveGlassMode } from '../policies';
import {
  ckColors,
  ckControlHeight,
  ckMotion,
  ckOpacity,
  ckRadius,
  ckSpacing,
  ckThemeColors,
  ckTypography,
  colorWithAlpha,
  statColors,
} from '../tokens';

describe('ClashKing UI contracts', () => {
  it('matches the Flutter and DevKit token sources', () => {
    expect(ckThemeColors.dark.primary).toBe('#D90709');
    expect(ckThemeColors.light.primary).toBe('#BF0000');
    expect(ckThemeColors.dark.background).toBe('#030304');
    expect(ckThemeColors.light.background).toBe('#F4F4F4');
    expect(ckThemeColors.dark.outlineVariant).toBe('#45464F');
    expect(ckThemeColors.light.outlineVariant).toBe('#BFC8CA');
    expect(ckColors.secondaryBlue).toBe('#026CC2');
    expect(statColors.win).toBe('#14A37F');
    expect(ckRadius).toMatchObject({ control: 12, chip: 16, card: 28, pill: 999 });
    expect(ckOpacity).toEqual({ border: 0.28, borderStrong: 0.32, fillMuted: 0.45 });
    expect(ckSpacing.md).toBe(12);
    expect(ckControlHeight.compact).toBe(44);
    expect(ckTypography.titleLarge.fontSize).toBe(24);
    expect(ckTypography.bodyMedium.fontSize).toBe(14);
    expect(ckMotion.standard).toBe(220);
  });

  it('resolves accessibility and platform policy deterministically', () => {
    expect(durationForMotion(220, true)).toBe(0);
    expect(colorWithAlpha('#D90709', 0.5)).toBe('#D9070980');
    expect(
      resolveGlassMode({
        platform: 'ios',
        nativeGlassAvailable: true,
        reduceTransparency: false,
        highContrast: false,
      }),
    ).toBe('native');
    expect(
      resolveGlassMode({
        platform: 'ios',
        nativeGlassAvailable: true,
        reduceTransparency: true,
        highContrast: false,
      }),
    ).toBe('opaque');
    expect(
      resolveGlassMode({
        platform: 'web',
        nativeGlassAvailable: false,
        reduceTransparency: false,
        highContrast: false,
      }),
    ).toBe('opaque');
  });

  it('matches responsive grid column behavior', () => {
    expect(resolveGridColumns({ width: 440, minItemWidth: 220, gap: 12 })).toBe(1);
    expect(resolveGridColumns({ width: 904, minItemWidth: 220, gap: 12 })).toBe(3);
  });
});
