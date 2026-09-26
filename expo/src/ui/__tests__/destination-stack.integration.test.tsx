import { describe, expect, it, jest } from '@jest/globals';
import { act, fireEvent, render } from '@testing-library/react-native';
import { NavigationContainer } from 'expo-router/react-navigation';
import { createNativeStackNavigator } from 'expo-router/native-stack';
import { createRef, useEffect, useState, type ComponentRef } from 'react';
import { Text } from 'react-native';

import { DestinationStack } from '../destination-stack';
import { CKThemeProvider, resolveCKTheme } from '../theme';

const OuterStack = createNativeStackNavigator<{ Home: undefined; Utility: undefined }>();

function GridContent({ onMount }: { onMount: () => void }) {
  useEffect(() => onMount(), [onMount]);
  return <Text>Persistent grid</Text>;
}

function Harness({
  onGridMount,
  onDetailClose,
}: {
  onGridMount: () => void;
  onDetailClose: () => void;
}) {
  const [focused, setFocused] = useState(true);
  return (
    <>
      <Text testID="focus-state">{String(focused)}</Text>
      <Text onPress={() => setFocused(true)}>Reopen detail</Text>
      <DestinationStack
        focused={focused}
        onCloseDetail={() => {
          onDetailClose();
          setFocused(false);
        }}
        grid={<GridContent onMount={onGridMount} />}
        detail={<Text>Focused detail</Text>}
      />
    </>
  );
}

describe('DestinationStack with the bundled navigator', () => {
  it('retains Grid under Detail through native pop and reopen', async () => {
    const navigationRef = createRef<ComponentRef<typeof NavigationContainer>>();
    const onGridMount = jest.fn();
    const onDetailClose = jest.fn();
    const view = await render(
      <CKThemeProvider preference="dark">
        <NavigationContainer ref={navigationRef}>
          <Harness onGridMount={onGridMount} onDetailClose={onDetailClose} />
        </NavigationContainer>
      </CKThemeProvider>,
    );

    expect(navigationRef.current?.getRootState().routes.map((route) => route.name)).toEqual([
      'Grid',
      'Detail',
    ]);
    expect(navigationRef.current?.getCurrentOptions()).toMatchObject({
      fullScreenGestureEnabled: false,
      contentStyle: { backgroundColor: resolveCKTheme('dark').background },
    });
    expect(onGridMount).toHaveBeenCalledTimes(1);
    await act(async () => {
      const state = navigationRef.current?.getRootState();
      navigationRef.current?.dispatch({ type: 'POP', payload: { count: 1 }, target: state?.key });
    });
    expect(view.getByTestId('focus-state').props.children).toBe('false');
    expect(onDetailClose).toHaveBeenCalledTimes(1);
    expect(navigationRef.current?.getRootState().routes.map((route) => route.name)).toEqual([
      'Grid',
    ]);
    expect(onGridMount).toHaveBeenCalledTimes(1);

    await act(async () => fireEvent.press(view.getByText('Reopen detail')));
    expect(navigationRef.current?.getRootState().routes.map((route) => route.name)).toEqual([
      'Grid',
      'Detail',
    ]);
    expect(onGridMount).toHaveBeenCalledTimes(1);
  });

  it('routes untargeted back to Detail before leaving the Utility page', async () => {
    const navigationRef = createRef<ComponentRef<typeof NavigationContainer>>();
    const onGridMount = jest.fn();
    const onDetailClose = jest.fn();
    const Home = () => <Text>Home page</Text>;
    const Utility = () => <Harness onGridMount={onGridMount} onDetailClose={onDetailClose} />;
    const view = await render(
      <CKThemeProvider preference="dark">
        <NavigationContainer ref={navigationRef}>
          <OuterStack.Navigator initialRouteName="Home" screenOptions={{ headerShown: false }}>
            <OuterStack.Screen name="Home" component={Home} />
            <OuterStack.Screen name="Utility" component={Utility} />
          </OuterStack.Navigator>
        </NavigationContainer>
      </CKThemeProvider>,
    );

    await act(async () => {
      navigationRef.current?.dispatch({ type: 'NAVIGATE', payload: { name: 'Utility' } });
    });
    expect(navigationRef.current?.getRootState().routes.map((route) => route.name)).toEqual([
      'Home',
      'Utility',
    ]);
    expect(
      navigationRef.current
        ?.getRootState()
        .routes.find((route) => route.name === 'Utility')
        ?.state?.routes.map((route) => route.name),
    ).toEqual(['Grid', 'Detail']);
    expect(view.getByText('Focused detail')).toBeTruthy();
    expect(onGridMount).toHaveBeenCalledTimes(1);

    await act(async () => navigationRef.current?.goBack());
    expect(navigationRef.current?.getRootState().routes.map((route) => route.name)).toEqual([
      'Home',
      'Utility',
    ]);
    expect(
      navigationRef.current
        ?.getRootState()
        .routes.find((route) => route.name === 'Utility')
        ?.state?.routes.map((route) => route.name),
    ).toEqual(['Grid']);
    expect(view.getByTestId('focus-state').props.children).toBe('false');
    expect(onDetailClose).toHaveBeenCalledTimes(1);
    expect(onGridMount).toHaveBeenCalledTimes(1);

    await act(async () => navigationRef.current?.goBack());
    expect(navigationRef.current?.getRootState().routes.map((route) => route.name)).toEqual([
      'Home',
    ]);
    expect(view.getByText('Home page')).toBeTruthy();
  });
});
