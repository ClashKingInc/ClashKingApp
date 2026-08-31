import { fireEvent, render } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { ClanWarStatsRangeModal } from './clan-war-stats-range-modal';

async function renderModal(onApply = jest.fn()) {
  return {
    onApply,
    screen: await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ClanWarStatsRangeModal
            initialMode="wars"
            initialWarRange={50}
            initialDayRange={90}
            onClose={jest.fn()}
            onApply={onApply}
          />
        </CKThemeProvider>
      </I18nProvider>,
    ),
  };
}

describe('ClanWarStatsRangeModal', () => {
  it('matches Flutter recent-war defaults and five-war slider steps', async () => {
    const { screen, onApply } = await renderModal();

    expect(screen.getByText('War stats range')).toBeTruthy();
    expect(screen.getByText('Wars to include')).toBeTruthy();
    await fireEvent(screen.getByLabelText('Wars to include'), 'accessibilityAction', {
      nativeEvent: { actionName: 'increment' },
    });
    await fireEvent.press(screen.getByText('Apply'));

    expect(onApply).toHaveBeenCalledWith({ mode: 'wars', wars: 55, days: 90 });
  });

  it('uses the seven-to-365 day range and resets both saved values', async () => {
    const { screen, onApply } = await renderModal();

    await fireEvent.press(screen.getByLabelText('Days'));
    expect(screen.getByText('Days to include')).toBeTruthy();
    await fireEvent(screen.getByLabelText('Days to include'), 'accessibilityAction', {
      nativeEvent: { actionName: 'increment' },
    });
    await fireEvent.press(screen.getByText('Reset'));
    await fireEvent.press(screen.getByText('Apply'));

    expect(onApply).toHaveBeenCalledWith({ mode: 'wars', wars: 50, days: 90 });
  });
});
