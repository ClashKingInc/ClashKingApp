import { act, fireEvent, render } from '@testing-library/react-native';
import { Pressable, Text } from 'react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { AnalyticsLineChart } from './analytics-chart';
import { ChartInteractionBoundary } from './chart-interaction-boundary';

jest.mock('react-native-svg', () => ({
  __esModule: true,
  ...jest.requireActual('react-native-svg'),
  Polyline: jest.requireActual('react-native').View,
}));

const series = [
  {
    key: 'attacks',
    label: 'Attacks',
    points: [
      { day: '2026-09-15', value: 50 },
      { day: '2026-09-17', value: 60 },
    ],
  },
];

function Chart() {
  return (
    <I18nProvider locale="en">
      <CKThemeProvider preference="dark">
        <AnalyticsLineChart title="Attack trend" series={series} />
      </CKThemeProvider>
    </I18nProvider>
  );
}

test('starts without a selected point and announces missing intermediate dates while scrubbing accessibly', async () => {
  const view = await render(<Chart />);
  expect(view.getByRole('adjustable').props.accessibilityLabel).toBe('Attack trend');
  expect(view.queryByTestId('chart-selection-date')).toBeNull();
  expect(view.queryByTestId('chart-selection-value-attacks')).toBeNull();
  await act(async () =>
    view
      .getByRole('adjustable')
      .props.onAccessibilityAction({ nativeEvent: { actionName: 'decrement' } }),
  );
  const middle = view.getByRole('adjustable');
  expect(middle.props.accessibilityLabel).toContain('Sep 16');
  expect(middle.props.accessibilityLabel).toContain('Attacks: —');
  expect(middle.props.accessibilityValue.now).toBe(1);
  await act(async () =>
    middle.props.onAccessibilityAction({ nativeEvent: { actionName: 'increment' } }),
  );
  expect(view.getByRole('adjustable').props.accessibilityLabel).toContain('Attacks: 60');
  expect(view.getByTestId('chart-selection-date')).toBeTruthy();
  expect(view.getByTestId('chart-tooltip')).toHaveStyle({ position: 'absolute' });
});

test('a tap selects the nearest chart date without drawing a value across a missing day', async () => {
  const view = await render(<Chart />);
  const chart = view.getByRole('adjustable');
  await act(async () =>
    chart.props.onLayout({ nativeEvent: { layout: { width: 360, height: 192 } } }),
  );
  await act(async () => {
    chart.props.onTouchStart({ nativeEvent: { pageX: 200, pageY: 100 } });
    chart.props.onTouchEnd({ nativeEvent: { pageX: 200, pageY: 100, locationX: 200 } });
  });
  expect(view.getByRole('adjustable').props.accessibilityLabel).toContain('Sep 16');
  expect(view.getByRole('adjustable').props.accessibilityLabel).toContain('Attacks: —');
});

test('connects observed points across missing days with rounded joins', async () => {
  const view = await render(<Chart />);
  const line = view.getByTestId('chart-line-attacks');
  expect(line.props.points.split(' ')).toHaveLength(2);
  expect(line.props.strokeLinejoin).toBe('round');
  expect(line.props.strokeLinecap).toBe('round');
});

test('an outside touch dismisses chart details without taking the responder or swallowing actions', async () => {
  const outsideAction = jest.fn();
  const view = await render(
    <ChartInteractionBoundary>
      <Chart />
      <Pressable
        onPress={outsideAction}
        accessibilityRole="button"
        accessibilityLabel="Outside action"
      >
        <Text>Outside</Text>
      </Pressable>
    </ChartInteractionBoundary>,
  );
  await act(async () =>
    view
      .getByRole('adjustable')
      .props.onAccessibilityAction({ nativeEvent: { actionName: 'decrement' } }),
  );
  expect(view.getByTestId('chart-tooltip')).toBeTruthy();
  let claimsResponder: unknown;
  await act(async () => {
    claimsResponder = view
      .getByTestId('chart-interaction-boundary')
      .props.onStartShouldSetResponderCapture();
  });
  expect(claimsResponder).toBe(false);
  fireEvent.press(view.getByRole('button', { name: 'Outside action' }));
  expect(outsideAction).toHaveBeenCalledTimes(1);
  expect(view.queryByTestId('chart-tooltip')).toBeNull();
  expect(view.getByRole('adjustable').props.accessibilityLabel).toBe('Attack trend');
});

test('selecting another chart replaces prior details and accessibility escape dismisses them', async () => {
  const view = await render(
    <ChartInteractionBoundary>
      <Chart />
      <Chart />
    </ChartInteractionBoundary>,
  );
  await act(async () =>
    view
      .getAllByRole('adjustable')[0]!
      .props.onAccessibilityAction({ nativeEvent: { actionName: 'decrement' } }),
  );
  await act(async () =>
    view
      .getAllByRole('adjustable')[1]!
      .props.onAccessibilityAction({ nativeEvent: { actionName: 'decrement' } }),
  );
  expect(view.getAllByTestId('chart-tooltip')).toHaveLength(1);
  expect(view.getAllByRole('adjustable')[0]!.props.accessibilityLabel).toBe('Attack trend');
  await act(async () => view.getAllByRole('adjustable')[1]!.props.onAccessibilityEscape());
  expect(view.queryByTestId('chart-tooltip')).toBeNull();
});
