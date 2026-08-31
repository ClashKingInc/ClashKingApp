import { fireEvent, render, waitFor } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { AccountVerificationDialog } from './account-verification-dialog';

it('shows localized feedback when Clash settings cannot be opened', async () => {
  const screen = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="light">
        <AccountVerificationDialog
          onCancel={jest.fn()}
          onOpenSettings={() => false}
          onVerified={jest.fn()}
          onVerify={async () => ({ success: false, message: null })}
          playerName="Player"
          playerTag="#TAG"
          townHallLevel={18}
          visible
        />
      </CKThemeProvider>
    </I18nProvider>,
  );
  await fireEvent.press(screen.getByRole('link'));
  await waitFor(() =>
    expect(screen.getAllByText(/could not open Clash of Clans/i)).toHaveLength(1),
  );
});
