import { fireEvent, render } from '@testing-library/react-native';
import type { ReactNode } from 'react';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { AccountRow } from './manage-linked-accounts-screen';

jest.mock('react-native-draggable-flatlist', () => {
  return {
    ScaleDecorator: ({ children }: { children: ReactNode }) => children,
  };
});

describe('linked-account drag handle', () => {
  it('starts continuous reordering only from the handle', async () => {
    const drag = jest.fn();
    const verify = jest.fn();
    const remove = jest.fn();
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <AccountRow
            item={{
              playerTag: '#ABC',
              name: 'Player',
              townHallLevel: 17,
              isVerified: false,
              hidden: false,
              raw: {},
            }}
            getIndex={() => 0}
            drag={drag}
            isActive={false}
            deleting={false}
            onRemove={remove}
            onVerify={verify}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    await fireEvent(screen.getByText('Player'), 'longPress');
    expect(drag).not.toHaveBeenCalled();

    await fireEvent(screen.getByTestId('account-drag-handle-#ABC'), 'longPress');
    expect(drag).toHaveBeenCalledTimes(1);

    await fireEvent.press(screen.getByRole('button', { name: 'Verify' }));
    await fireEvent.press(screen.getByRole('button', { name: 'Remove account' }));
    expect(verify).toHaveBeenCalledTimes(1);
    expect(remove).toHaveBeenCalledTimes(1);
  });
});
