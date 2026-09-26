import { act, cleanup, fireEvent, render } from '@testing-library/react-native';
import { Animated } from 'react-native';

import { I18nProvider } from '../../i18n';
import { CKThemeProvider } from '../../ui';
import { StartupLoadingScreen } from './startup-loading';

jest.mock('../../ui/mobile-web-image', () => {
  const { View } = jest.requireActual<typeof import('react-native')>('react-native');
  return { MobileWebImage: View };
});

describe('startup loading sequence', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(async () => {
    await cleanup();
    jest.useRealTimers();
  });

  it('shows localized OTA progress and wires the background action', async () => {
    const background = jest.fn();
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <StartupLoadingScreen
            update={{ downloading: true, progress: 0.35 }}
            onUpdateInBackground={background}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    expect(screen.getByText('Downloading update…')).toBeTruthy();
    // Preserve the source View's role/value props without claiming native
    // accessibility behavior, which requires a separately approved device check.
    const progress = screen.root!.queryAll(
      (node) => node.props.accessibilityRole === 'progressbar',
    )[0]!;
    expect(progress.props.accessibilityValue).toEqual({
      min: 0,
      max: 100,
      now: 35,
    });
    await fireEvent.press(screen.getByRole('button', { name: 'Update in background' }));
    expect(background).toHaveBeenCalledTimes(1);
  });

  it('plays once without fictional request stages or progress dots', async () => {
    const timingSpy = jest.spyOn(Animated, 'timing');
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <StartupLoadingScreen />
        </CKThemeProvider>
      </I18nProvider>,
    );

    expect(screen.getByTestId('startup-brand')).toBeTruthy();
    expect(timingSpy).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ duration: 770, toValue: 1, useNativeDriver: true }),
    );
    await act(async () => {
      jest.advanceTimersByTime(10_000);
    });
    expect(screen.queryByText('Loading your villages...')).toBeNull();
    expect(screen.queryByText('Fetching clan data...')).toBeNull();
    expect(screen.queryByRole('progressbar')).toBeNull();
    expect(timingSpy).toHaveBeenCalledTimes(1);
    timingSpy.mockRestore();
  });
});
