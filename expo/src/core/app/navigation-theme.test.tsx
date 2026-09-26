import { render } from '@testing-library/react-native';
import { useTheme } from 'expo-router';
import * as SystemUI from 'expo-system-ui';
import { Text } from 'react-native';
import { CKThemeProvider, resolveCKTheme } from '../../ui/theme';
import { NavigationTheme } from './navigation-theme';

jest.mock('expo-system-ui', () => ({ setBackgroundColorAsync: jest.fn().mockResolvedValue(null) }));

function ThemeProbe() {
  const theme = useTheme();
  return (
    <Text>{`${theme.dark}:${String(theme.colors.background)}:${String(theme.colors.card)}`}</Text>
  );
}

test('navigation, root backing, and native window track the selected app theme', async () => {
  const view = await render(
    <CKThemeProvider preference="dark">
      <NavigationTheme>
        <ThemeProbe />
      </NavigationTheme>
    </CKThemeProvider>,
  );
  const dark = resolveCKTheme('dark').background;
  expect(view.getByText(`true:${dark}:${dark}`)).toBeTruthy();
  expect(view.getByTestId('navigation-theme-background').props.style.backgroundColor).toBe(dark);
  expect(SystemUI.setBackgroundColorAsync).toHaveBeenLastCalledWith(dark);
  await view.rerender(
    <CKThemeProvider preference="light">
      <NavigationTheme>
        <ThemeProbe />
      </NavigationTheme>
    </CKThemeProvider>,
  );
  const light = resolveCKTheme('light').background;
  expect(view.getByText(`false:${light}:${light}`)).toBeTruthy();
  expect(view.getByTestId('navigation-theme-background').props.style.backgroundColor).toBe(light);
  expect(SystemUI.setBackgroundColorAsync).toHaveBeenLastCalledWith(light);
});
