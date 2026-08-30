import { createContext, createElement, useContext, type PropsWithChildren } from 'react';
import { useColorScheme } from 'react-native';

import { ckThemeColors, type CKThemeColors, type CKThemeMode } from './tokens';

export type CKThemePreference = CKThemeMode | 'system';

const CKThemePreferenceContext = createContext<CKThemePreference>('system');

export function CKThemeProvider({
  preference,
  children,
}: PropsWithChildren<{ preference: CKThemePreference }>) {
  return createElement(CKThemePreferenceContext.Provider, { value: preference }, children);
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
