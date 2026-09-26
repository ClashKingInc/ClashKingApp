import { act, fireEvent, render } from '@testing-library/react-native';
import { NavigationContainer } from 'expo-router/react-navigation';
import { createNativeStackNavigator } from 'expo-router/native-stack';
import { createRef, useState, type ComponentRef } from 'react';
import { Text } from 'react-native';

import { LinkParametersContext } from '../../../core/deep-links/link-parameters';
import {
  applyNativeSecondaryRouteTransition,
  nativeSecondaryRouteTransition,
} from '../../../core/app/native-secondary-navigation';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui/theme';
import { SettingsRoot } from './settings-root';

jest.mock('../../../core/assets/local-asset-cache', () => ({
  localImageCache: { subscribe: () => () => {}, getSize: () => 0 },
}));
jest.mock('../../../core/app/runtime-context', () => {
  const subscribe = () => () => {};
  const state = { isFeatureEnabled: () => true, themePreference: 'dark' };
  const runtime = {
    players: { subscribe, profiles: [] },
    bookmarks: { subscribe, clans: [] },
    accounts: { subscribe, accounts: [] },
    clans: { subscribe, clans: new Map() },
    appIcons: { supportsAlternateIcons: async () => false },
    warWidgets: { cacheClanOptions: async () => {} },
    notificationSettingsDebug: null,
    auth: { state: { currentUser: {} } },
  };
  return { useAppRuntime: () => runtime, useAppState: () => state };
});
jest.mock('./settings-runtime', () => ({ getVersionDeviceLabel: async () => '0.4.2' }));
jest.mock('./settings-screen', () => {
  const { Text } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    SettingsScreen: ({ actions }: { actions: { open: (scene: string) => void } }) => (
      <Text onPress={() => actions.open('notifications')}>Open notifications</Text>
    ),
  };
});
jest.mock('./notification-settings-screen', () => {
  const { Text } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    NotificationSettingsScreen: ({
      onBack,
      onManagePlayers,
    }: {
      onBack: () => void;
      onManagePlayers?: () => void;
    }) => (
      <>
        <Text onPress={onBack}>Notifications back</Text>
        <Text onPress={onManagePlayers}>Linked players</Text>
      </>
    ),
  };
});

const OuterStack = createNativeStackNavigator<{ Home: undefined; Settings: undefined }>();

it('leaves both nested Notifications and outer Settings when opening Linked players', async () => {
  const navigation = createRef<ComponentRef<typeof NavigationContainer>>();
  const dismissTo = jest.fn(() => {
    navigation.current?.dispatch({
      type: 'POP_TO',
      target: navigation.current.getRootState().key,
      payload: { name: 'Home' },
    });
  });
  function Harness() {
    const [primary, setPrimary] = useState('Home content');
    return (
      <OuterStack.Navigator screenOptions={{ headerShown: false }}>
        <OuterStack.Screen name="Home">{() => <Text>{primary}</Text>}</OuterStack.Screen>
        <OuterStack.Screen name="Settings">
          {() => (
            <SettingsRoot
              onClose={jest.fn()}
              onManagePlayers={() => {
                setPrimary('Players: Linked');
                applyNativeSecondaryRouteTransition(
                  nativeSecondaryRouteTransition(['utility:settings::0'], []),
                  { dismissTo, push: jest.fn(), replace: jest.fn() },
                );
              }}
            />
          )}
        </OuterStack.Screen>
      </OuterStack.Navigator>
    );
  }
  const view = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="dark">
        <NavigationContainer ref={navigation}>
          <Harness />
        </NavigationContainer>
      </CKThemeProvider>
    </I18nProvider>,
  );
  await act(async () => navigation.current?.navigate('Settings' as never));
  await fireEvent.press(view.getByText('Open notifications'));
  await fireEvent.press(view.getByText('Linked players'));
  expect(dismissTo).toHaveBeenCalledWith('/');
  expect(navigation.current?.getRootState().routes.map(({ name }) => name)).toEqual(['Home']);
  expect(view.getByText('Players: Linked')).toBeTruthy();
  expect(view.queryByText('Notifications back')).toBeNull();
});

it.each([false, true])(
  'returns Notifications to Settings before Home, including deep links (%s)',
  async (deepLinked) => {
    const navigation = createRef<ComponentRef<typeof NavigationContainer>>();
    const close = jest.fn();
    const Home = () => <Text>Home</Text>;
    const Settings = () => (
      <LinkParametersContext.Provider value={deepLinked ? { section: 'notifications' } : {}}>
        <SettingsRoot onClose={close} />
      </LinkParametersContext.Provider>
    );
    const view = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <NavigationContainer ref={navigation}>
            <OuterStack.Navigator screenOptions={{ headerShown: false }}>
              <OuterStack.Screen name="Home" component={Home} />
              <OuterStack.Screen name="Settings" component={Settings} />
            </OuterStack.Navigator>
          </NavigationContainer>
        </CKThemeProvider>
      </I18nProvider>,
    );
    await act(async () => navigation.current?.navigate('Settings' as never));
    if (!deepLinked) await fireEvent.press(view.getByText('Open notifications'));
    expect(view.getByText('Notifications back')).toBeTruthy();
    expect(navigation.current?.getCurrentOptions()).toMatchObject({ gestureEnabled: true });

    // Native gesture completion and hardware back both pop this nested route.
    await act(async () => navigation.current?.goBack());
    expect(navigation.current?.getRootState().routes.map(({ name }) => name)).toEqual([
      'Home',
      'Settings',
    ]);
    expect(view.getByText('Open notifications')).toBeTruthy();
    expect(close).not.toHaveBeenCalled();

    await fireEvent.press(view.getByText('Open notifications'));
    await fireEvent.press(view.getByText('Notifications back'));
    expect(view.getByText('Open notifications')).toBeTruthy();
    expect(close).not.toHaveBeenCalled();

    await act(async () => navigation.current?.goBack());
    expect(navigation.current?.getRootState().routes.map(({ name }) => name)).toEqual(['Home']);
  },
);
