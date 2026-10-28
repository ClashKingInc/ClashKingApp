import { isAdaptiveIOSDevice, isDuoDevice } from './adaptive-layout';
import { createContext, createElement, useContext, useEffect, type PropsWithChildren } from 'react';
import { Appearance, Platform, useColorScheme, useWindowDimensions } from 'react-native';
import { TabletTypographyContext } from './typography-context';

import { ckThemeColors, type CKThemeColors, type CKThemeMode } from './tokens';

export type CKThemePreference = CKThemeMode | 'system';

const CKThemePreferenceContext = createContext<CKThemePreference>('dark');

export function CKThemeProvider({
  preference,
  children,
}: PropsWithChildren<{ preference: CKThemePreference }>) {
  const { width } = useWindowDimensions();
  const tabletTypography =
    Platform.OS === 'ios' && Platform.isPad === true && !isDuoDevice && width >= 640;
  useEffect(() => {
    if (!isAdaptiveIOSDevice) return;
    // Native bars and sheets must follow the saved app theme. Reset the
    // override for System so later system appearance changes still propagate.
    Appearance.setColorScheme(preference === 'system' ? 'auto' : preference);
    return () => Appearance.setColorScheme('auto');
  }, [preference]);
  return createElement(
    CKThemePreferenceContext.Provider,
    { value: preference },
    createElement(TabletTypographyContext.Provider, { value: tabletTypography }, children),
  );
}

export function resolveCKTheme(mode: CKThemeMode): CKThemeColors {
  return ckThemeColors[mode];
}

export function useCKThemeMode(): CKThemeMode {
  const preference = useContext(CKThemePreferenceContext);
  const systemMode: CKThemeMode = useColorScheme() === 'dark' ? 'dark' : 'light';
  return preference === 'system' ? systemMode : preference;
}

export function useCKTheme(): CKThemeColors {
  return resolveCKTheme(useCKThemeMode());
}
