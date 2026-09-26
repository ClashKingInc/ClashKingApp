import { act, fireEvent, render } from '@testing-library/react-native';
import { Animated, Text, useWindowDimensions } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import {
  ClanSpringTransition,
  ClanSpringTarget,
  validClanSpringOrigin,
  type ClanSpringOrigin,
} from './clan-spring-transition';
import * as Accessibility from '../../../ui/accessibility';

jest.mock('react-native', () => {
  const actual = jest.requireActual('react-native');
  const React = jest.requireActual('react');
  const MockView = React.forwardRef(function MockView(props: { testID?: string }, ref: unknown) {
    React.useImperativeHandle(ref, () => ({
      measureInWindow: (
        callback: (x: number, y: number, width: number, height: number) => void,
      ) => {
        if (props.testID === 'clan-spring-target-badge') callback(148, 100, 94, 94);
        if (props.testID === 'clan-spring-target-name') callback(120, 205, 150, 27);
      },
    }));
    return React.createElement(actual.View, props);
  });
  return Object.defineProperties(Object.create(actual), {
    useWindowDimensions: { value: () => ({ width: 390, height: 844, scale: 3, fontScale: 1 }) },
    View: { value: MockView },
  });
});

const origin: ClanSpringOrigin = {
  card: { x: 16, y: 100, width: 280, height: 130 },
  badge: { x: 30, y: 114, width: 64, height: 64 },
  name: { x: 106, y: 114, width: 100, height: 22 },
  viewport: { width: 390, height: 844 },
  badgeUrl: 'https://example.test/badge.png',
  title: 'Clan',
};
beforeEach(() => {
  jest
    .spyOn(Accessibility, 'useCKAccessibility')
    .mockReturnValue({ reduceMotion: false, reduceTransparency: false, highContrast: false });
});
afterEach(() => {
  jest.restoreAllMocks();
  jest.useRealTimers();
});
test('rejects stale, offscreen, and invalid source geometry', () => {
  expect(validClanSpringOrigin(origin, 390, 844)).toBe(true);
  expect(validClanSpringOrigin(origin, 844, 390)).toBe(false);
  expect(validClanSpringOrigin({ ...origin, card: { ...origin.card, y: -1 } }, 390, 844)).toBe(
    false,
  );
  expect(validClanSpringOrigin({ ...origin, name: { ...origin.name, width: NaN } }, 390, 844)).toBe(
    false,
  );
});
function Harness({ onComplete = () => {} }: { onComplete?: () => void }) {
  const { width, height } = useWindowDimensions();
  return (
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width, height },
        insets: { top: 59, bottom: 34, left: 0, right: 0 },
      }}
    >
      <ClanSpringTransition
        origin={{ ...origin, viewport: { width, height } }}
        onComplete={onComplete}
      >
        <Text>Detail already mounted</Text>
        <ClanSpringTarget part="badge">
          <Text>Actual badge</Text>
        </ClanSpringTarget>
        <ClanSpringTarget part="name">
          <Text>Actual name</Text>
        </ClanSpringTarget>
      </ClanSpringTransition>
    </SafeAreaProvider>
  );
}
test('mounts content immediately, hides duplicate identity, and falls back if native measurement is unavailable', async () => {
  const done = jest.fn();
  const view = await render(<Harness onComplete={done} />);
  expect(view.getByText('Detail already mounted')).toBeTruthy();
  expect(view.getByTestId('clan-spring-target-name').props.style.opacity).toBe(0);
  await act(async () => new Promise((resolve) => setTimeout(resolve, 140)));
  expect(view.getByTestId('clan-spring-target-name').props.style.opacity).toBe(1);
  expect(done).toHaveBeenCalledTimes(1);
});
test('reduced motion skips the spring without hiding content', async () => {
  jest
    .spyOn(Accessibility, 'useCKAccessibility')
    .mockReturnValue({ reduceMotion: true, reduceTransparency: false, highContrast: false });
  const spring = jest.spyOn(Animated, 'spring');
  const view = await render(<Harness />);
  expect(view.getByText('Detail already mounted')).toBeTruthy();
  expect(view.getByTestId('clan-spring-target-name').props.style.opacity).toBe(1);
  expect(spring).not.toHaveBeenCalled();
});

test('waits for both measured targets and hands identity back only when the spring settles', async () => {
  const done = jest.fn();
  let settle: ((result: { finished: boolean }) => void) | undefined;
  const spring = jest.spyOn(Animated, 'spring').mockImplementation(() => ({
    start: (callback) => {
      settle = callback;
    },
    stop: jest.fn(),
    reset: jest.fn(),
  }));
  const view = await render(<Harness onComplete={done} />);
  await fireEvent(view.getByTestId('clan-spring-target-badge'), 'layout', {});
  expect(spring).not.toHaveBeenCalled();
  await fireEvent(view.getByTestId('clan-spring-target-name'), 'layout', {});
  expect(spring).toHaveBeenCalledTimes(1);
  expect(spring).toHaveBeenCalledWith(
    expect.anything(),
    expect.objectContaining({ useNativeDriver: true, overshootClamping: true }),
  );
  expect(view.getByTestId('clan-spring-target-name').props.style.opacity).toBe(0);
  await act(async () => settle?.({ finished: true }));
  expect(view.getByTestId('clan-spring-target-name').props.style.opacity).toBe(1);
  expect(done).toHaveBeenCalledTimes(1);
});

test('a touch immediately finishes the effect without swallowing interaction', async () => {
  const done = jest.fn();
  const view = await render(<Harness onComplete={done} />);
  await fireEvent(view.getByTestId('clan-spring-transition'), 'touchStart', {});
  expect(view.getByTestId('clan-spring-target-name').props.style.opacity).toBe(1);
  expect(done).toHaveBeenCalledTimes(1);
});
