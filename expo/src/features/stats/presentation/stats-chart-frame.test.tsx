import { act, fireEvent, render, waitFor } from '@testing-library/react-native';
import { Image, StyleSheet, Text } from 'react-native';
import { captureRef } from 'react-native-view-shot';
import * as Clipboard from 'expo-clipboard';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { StatsChartFrame } from './stats-chart-frame';

jest.mock('react-native-view-shot', () => ({ captureRef: jest.fn(async () => 'png-data') }));
jest.mock('expo-clipboard', () => ({ setImageAsync: jest.fn(async () => {}) }));

beforeEach(() => {
  jest.clearAllMocks();
  jest.spyOn(Image, 'prefetch').mockResolvedValue(true);
  jest.mocked(captureRef).mockResolvedValue('png-data');
  jest.mocked(Clipboard.setImageAsync).mockResolvedValue();
});
afterEach(() => jest.restoreAllMocks());

test('copies a branded chart and reports clipboard failure without claiming success', async () => {
  const view = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="dark">
        <StatsChartFrame title="Usage" testID="usage">
          <Text>Chart content</Text>
        </StatsChartFrame>
      </CKThemeProvider>
    </I18nProvider>,
  );
  expect(view.queryByText('ClashKing')).toBeNull();
  expect(view.getByText('Chart content')).toBeTruthy();
  await act(async () => fireEvent.press(view.getByTestId('usage-copy')));
  expect(view.getByText('ClashKing', { includeHiddenElements: true })).toBeTruthy();
  await act(async () =>
    fireEvent(view.getByTestId('stats-chart-export', { includeHiddenElements: true }), 'layout', {
      nativeEvent: { layout: { width: 360, height: 250 } },
    }),
  );
  await waitFor(() => expect(Clipboard.setImageAsync).toHaveBeenCalledWith('png-data'));
  expect(captureRef).toHaveBeenCalled();
  expect(view.getByRole('button', { name: 'Copied to clipboard' })).toBeTruthy();
  jest.mocked(Clipboard.setImageAsync).mockRejectedValueOnce(new Error('clipboard unavailable'));
  await act(async () => fireEvent.press(view.getByTestId('usage-copy')));
  await act(async () =>
    fireEvent(view.getByTestId('stats-chart-export', { includeHiddenElements: true }), 'layout', {
      nativeEvent: { layout: { width: 360, height: 250 } },
    }),
  );
  await waitFor(() => expect(view.getByText('Could not copy chart. Try again.')).toBeTruthy());
  expect(view.queryByRole('button', { name: 'Copied to clipboard' })).toBeNull();
});

test('does not report success when chart capture fails', async () => {
  jest.mocked(captureRef).mockRejectedValueOnce(new Error('capture unavailable'));
  const view = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="dark">
        <StatsChartFrame title="Usage" testID="usage">
          <Text>Chart content</Text>
        </StatsChartFrame>
      </CKThemeProvider>
    </I18nProvider>,
  );
  await act(async () => fireEvent.press(view.getByTestId('usage-copy')));
  await act(async () =>
    fireEvent(view.getByTestId('stats-chart-export', { includeHiddenElements: true }), 'layout', {
      nativeEvent: { layout: { width: 360, height: 250 } },
    }),
  );
  expect(view.getByText('Could not copy chart. Try again.')).toBeTruthy();
  expect(Clipboard.setImageAsync).not.toHaveBeenCalled();
});

test('exports expanded content with padding and rounded corners, without nested copy buttons', async () => {
  const view = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="dark">
        <StatsChartFrame
          title="TH18"
          testID="townhall"
          copyPlacement="footer"
          exportContent={
            <StatsChartFrame title="Star rates" testID="nested">
              <Text>Full statistics and graph</Text>
            </StatsChartFrame>
          }
        >
          <Text>Collapsed card</Text>
        </StatsChartFrame>
      </CKThemeProvider>
    </I18nProvider>,
  );
  expect(view.queryByText('Full statistics and graph', { includeHiddenElements: true })).toBeNull();
  const copyStyle = StyleSheet.flatten(view.getByTestId('townhall-copy').props.style);
  expect(copyStyle.alignSelf).toBe('flex-end');
  expect(copyStyle.position).toBeUndefined();
  await act(async () => fireEvent.press(view.getByTestId('townhall-copy')));
  expect(view.getByText('Full statistics and graph', { includeHiddenElements: true })).toBeTruthy();
  expect(view.queryByTestId('nested-copy', { includeHiddenElements: true })).toBeNull();
  expect(view.getByTestId('stats-chart-export', { includeHiddenElements: true })).toHaveStyle({
    padding: 20,
    borderRadius: 24,
    width: 400,
  });
});
