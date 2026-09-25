import { describe, expect, it, jest } from '@jest/globals';
import { act, fireEvent, render } from '@testing-library/react-native';
import { useState } from 'react';
import { Text } from 'react-native';

import { DestinationStack } from '../destination-stack';

jest.mock('expo-router/native-stack', () => {
  const React = jest.requireActual<typeof import('react')>('react');
  const { Pressable, Text, View } =
    jest.requireActual<typeof import('react-native')>('react-native');
  type MockRoute = 'Grid' | 'Detail';
  type MockScreen = {
    name: MockRoute;
    component: React.ComponentType<{ navigation: MockNavigation }>;
  };
  type MockNavigation = {
    getState: () => { index: number; routes: { name: MockRoute }[] };
    navigate: (route: MockRoute) => void;
    pop: () => void;
    addListener: (event: string, listener: () => void) => () => void;
  };

  function MockNavigator({ children }: { children: React.ReactNode }) {
    const [index, setIndex] = React.useState(0);
    const [detailRemoveListeners] = React.useState(() => new Set<() => void>());
    const navigation: MockNavigation = {
      getState: () => ({
        index,
        routes: [{ name: 'Grid' }, ...(index ? [{ name: 'Detail' as const }] : [])],
      }),
      navigate: () => setIndex(1),
      pop: () => {
        if (!index) return;
        detailRemoveListeners.forEach((listener) => listener());
        setIndex(0);
      },
      addListener: (event, listener) => {
        if (event === 'beforeRemove') detailRemoveListeners.add(listener);
        return () => detailRemoveListeners.delete(listener);
      },
    };
    const screens = React.Children.toArray(children).map(
      (child) => (child as React.ReactElement<MockScreen>).props,
    );
    const Grid = screens.find((screen) => screen.name === 'Grid')!.component;
    const Detail = screens.find((screen) => screen.name === 'Detail')!.component;
    return React.createElement(
      View,
      null,
      React.createElement(Text, { testID: 'route-depth' }, index + 1),
      React.createElement(
        View,
        { style: { display: index ? 'none' : 'flex' } },
        React.createElement(Grid, { navigation }),
      ),
      index ? React.createElement(Detail, { navigation }) : null,
      React.createElement(Pressable, { testID: 'native-back', onPress: navigation.pop }),
    );
  }

  return {
    createNativeStackNavigator: () => ({
      Navigator: MockNavigator,
      Screen: () => null,
    }),
  };
});

function Harness({
  initiallyFocused = false,
  onOuterBack = () => undefined,
  onDetailClose = () => undefined,
}: {
  initiallyFocused?: boolean;
  onOuterBack?: () => void;
  onDetailClose?: () => void;
}) {
  const [focused, setFocused] = useState(initiallyFocused);
  return (
    <>
      <Text testID="focused">{String(focused)}</Text>
      <Text onPress={() => setFocused(true)}>Open detail</Text>
      <Text onPress={() => setFocused(false)}>Header back</Text>
      <DestinationStack
        focused={focused}
        onCloseDetail={() => {
          onDetailClose();
          setFocused(false);
        }}
        grid={<Text>Grid content</Text>}
        detail={<Text>Detail content</Text>}
      />
      <Text onPress={onOuterBack}>Outer back</Text>
    </>
  );
}

describe('DestinationStack', () => {
  it('keeps Grid under Detail and synchronizes header close without leaving the parent route', async () => {
    const outerBack = jest.fn();
    const detailClose = jest.fn();
    const view = await render(<Harness onOuterBack={outerBack} onDetailClose={detailClose} />);
    expect(view.getByTestId('route-depth').props.children).toBe(1);
    await act(async () => fireEvent.press(view.getByText('Open detail')));
    expect(view.getByTestId('route-depth').props.children).toBe(2);
    expect(view.getByText('Detail content')).toBeTruthy();
    await act(async () => fireEvent.press(view.getByText('Header back')));
    expect(view.getByTestId('route-depth').props.children).toBe(1);
    expect(view.getByText('Grid content')).toBeTruthy();
    expect(outerBack).not.toHaveBeenCalled();
    expect(detailClose).not.toHaveBeenCalled();
  });

  it('treats native swipe/back as closing Detail, including a deep-linked initial detail', async () => {
    const outerBack = jest.fn();
    const detailClose = jest.fn();
    const view = await render(
      <Harness initiallyFocused onOuterBack={outerBack} onDetailClose={detailClose} />,
    );
    expect(view.getByTestId('route-depth').props.children).toBe(2);
    await act(async () => fireEvent.press(view.getByTestId('native-back')));
    expect(view.getByTestId('focused').props.children).toBe('false');
    expect(view.getByTestId('route-depth').props.children).toBe(1);
    expect(outerBack).not.toHaveBeenCalled();
    expect(detailClose).toHaveBeenCalledTimes(1);
    await act(async () => fireEvent.press(view.getByText('Open detail')));
    expect(view.getByTestId('route-depth').props.children).toBe(2);
  });
});
