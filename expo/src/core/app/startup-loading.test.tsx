import { act, render } from '@testing-library/react-native';
import { Animated, StyleSheet } from 'react-native';

import { I18nProvider } from '../../i18n';
import { CKThemeProvider } from '../../ui';
import { StartupLoadingScreen } from './startup-loading';

jest.mock('../../ui/mobile-web-image', () => {
  const { View } = jest.requireActual<typeof import('react-native')>('react-native');
  return { MobileWebImage: View };
});

describe('startup loading sequence', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => jest.useRealTimers());

  it('advances through Flutter statuses while real bootstrap remains mounted', async () => {
    const timingSpy = jest.spyOn(Animated, 'timing');
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <StartupLoadingScreen />
        </CKThemeProvider>
      </I18nProvider>,
    );

    const readFirstMessageOpacity = () =>
      StyleSheet.flatten(screen.getByText('Loading your villages...').props.style).opacity;
    expect(readFirstMessageOpacity()).toBe(0);
    expect(timingSpy).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ duration: 200, toValue: 1 }),
    );
    await act(async () => {
      jest.advanceTimersByTime(1_200);
    });
    expect(screen.getByText('Fetching clan data...')).toBeTruthy();
    await act(async () => {
      jest.advanceTimersByTime(1_200);
    });
    expect(screen.getByText('Analyzing war stats...')).toBeTruthy();
  });
});
