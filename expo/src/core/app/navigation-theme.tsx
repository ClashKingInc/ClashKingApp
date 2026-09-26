import { DarkTheme, DefaultTheme, ThemeProvider } from 'expo-router';
import * as SystemUI from 'expo-system-ui';
import { useEffect, useMemo, type PropsWithChildren } from 'react';
import { View } from 'react-native';

import { useCKTheme, useCKThemeMode } from '../../ui/theme';
import { reportException } from '../observability/observability';

/** Keep the native stack and the window exposed by rounded swipe transitions in sync. */
export function NavigationTheme({ children }: PropsWithChildren) {
  const colors = useCKTheme();
  const mode = useCKThemeMode();
  const theme = useMemo(() => {
    const base = mode === 'dark' ? DarkTheme : DefaultTheme;
    return {
      ...base,
      colors: {
        ...base.colors,
        background: colors.background,
        card: colors.background,
        text: colors.onSurface,
        primary: colors.primary,
      },
    };
  }, [colors, mode]);

  useEffect(() => {
    void SystemUI.setBackgroundColorAsync(colors.background).catch((error) =>
      reportException(error, 'navigation.window_background'),
    );
  }, [colors.background]);

  return (
    <ThemeProvider value={theme}>
      <View
        testID="navigation-theme-background"
        style={{ flex: 1, backgroundColor: colors.background }}
      >
        {children}
      </View>
    </ThemeProvider>
  );
}
