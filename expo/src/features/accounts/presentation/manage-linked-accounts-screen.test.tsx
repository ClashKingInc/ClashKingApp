import { act, fireEvent, render, waitFor } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { ManageLinkedAccountsScreen } from './manage-linked-accounts-screen';
import type { LinkedAccountPresentationService } from './contracts';

jest.mock('../../../ui/accessibility', () => ({
  useCKAccessibility: () => ({
    reduceMotion: false,
    reduceTransparency: false,
    highContrast: false,
  }),
}));

jest.mock('react-native-draggable-flatlist', () => {
  const ReactModule = jest.requireActual<typeof import('react')>('react');
  const { View: MockView } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    __esModule: true,
    ScaleDecorator: ({ children }: { children: React.ReactNode }) => children,
    NestableScrollContainer: ({ children }: { children: React.ReactNode }) =>
      ReactModule.createElement(MockView, null, children),
    default: ({
      data,
      renderItem,
      ListHeaderComponent,
      ListEmptyComponent,
    }: {
      data: readonly unknown[];
      renderItem: (parameters: Record<string, unknown>) => React.ReactNode;
      ListHeaderComponent?: React.ReactNode;
      ListEmptyComponent?: React.ReactNode;
    }) =>
      ReactModule.createElement(
        MockView,
        null,
        ListHeaderComponent,
        data.length === 0 ? ListEmptyComponent : null,
        data.map((item, index) =>
          ReactModule.createElement(
            ReactModule.Fragment,
            { key: index },
            renderItem({ item, index, drag: jest.fn(), isActive: false, getIndex: () => index }),
          ),
        ),
      ),
  };
});

const service: LinkedAccountPresentationService = {
  accounts: [],
  addAccount: async () => ({ code: 500, message: null, account: null }),
  addAccountWithToken: async () => ({ success: false, message: null }),
  removeAccount: async () => false,
  updateAccountOrder: async () => true,
};

describe('first linked-account continuation', () => {
  it('hydrates account identity when player profiles arrive after the links', async () => {
    const props = {
      continueLabel: 'Continue',
      firstConnection: false,
      initialAccounts: [
        {
          playerTag: '#ABC',
          name: '#ABC',
          townHallLevel: 1,
          isVerified: true,
          hidden: false,
          raw: {},
        },
      ],
      onBack: jest.fn(),
      onContinue: jest.fn(),
      onOpenGameSettings: jest.fn(),
      service,
    } as const;
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ManageLinkedAccountsScreen {...props} />
        </CKThemeProvider>
      </I18nProvider>,
    );

    expect(screen.getAllByText('#ABC')).toHaveLength(2);
    await act(async () => {
      screen.rerender(
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <ManageLinkedAccountsScreen
              {...props}
              playerProfiles={[{ tag: '#abc', name: 'Hydrated Player', townHallLevel: 18 }]}
            />
          </CKThemeProvider>
        </I18nProvider>,
      );
    });

    await waitFor(() => expect(screen.getByText('Hydrated Player')).toBeTruthy());
  });

  it('keeps Flutter blocking skeleton visible until account bootstrap completes', async () => {
    let resolve!: () => void;
    const continuation = new Promise<void>((done) => {
      resolve = done;
    });
    const onContinue = jest.fn(() => continuation);
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ManageLinkedAccountsScreen
            continueLabel="Continue"
            firstConnection
            initialAccounts={[
              {
                playerTag: '#ABC',
                name: 'Player',
                townHallLevel: 17,
                isVerified: true,
                hidden: false,
                raw: {},
              },
            ]}
            onContinue={onContinue}
            onOpenGameSettings={jest.fn()}
            service={service}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    fireEvent.press(screen.getByRole('button', { name: 'Continue' }));
    await waitFor(() => expect(onContinue).toHaveBeenCalledTimes(1));
    expect(screen.getByTestId('skeleton-loading-dialog')).toBeTruthy();

    await act(async () => resolve());
    await waitFor(() => expect(screen.queryByTestId('skeleton-loading-dialog')).toBeNull());
  });

  it('re-enters verified-account setup after removing the final verified link', async () => {
    const onBack = jest.fn();
    const onContinue = jest.fn();
    const removeAccount = jest.fn(async () => true);
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ManageLinkedAccountsScreen
            continueLabel="Continue"
            firstConnection={false}
            initialAccounts={[
              {
                playerTag: '#ABC',
                name: 'Player',
                townHallLevel: 17,
                isVerified: true,
                hidden: false,
                raw: {},
              },
            ]}
            onBack={onBack}
            onContinue={onContinue}
            onOpenGameSettings={jest.fn()}
            service={{ ...service, removeAccount }}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    await act(async () => {
      fireEvent.press(screen.getByRole('button', { name: 'Remove account' }));
    });
    await waitFor(() => expect(removeAccount).toHaveBeenCalledWith('#ABC'));

    const continueButton = screen.getByRole('button', { name: 'Continue' });
    expect(continueButton.props.accessibilityState).toEqual(
      expect.objectContaining({ disabled: true }),
    );
    fireEvent.press(screen.getByRole('button', { name: 'Back' }));
    expect(onBack).not.toHaveBeenCalled();
    expect(onContinue).not.toHaveBeenCalled();
  });

  it('shows Flutter retry UI for a 500 and refreshes bootstrap after retry succeeds', async () => {
    const addAccount = jest
      .fn()
      .mockResolvedValueOnce({ code: 500, message: null, account: null })
      .mockResolvedValueOnce({
        code: 200,
        message: null,
        account: {
          playerTag: '#NEW',
          isVerified: true,
          hidden: false,
          raw: { name: 'New Player', townHallLevel: 18 },
        },
      });
    const onRefresh = jest.fn(async () => undefined);
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ManageLinkedAccountsScreen
            continueLabel="Continue"
            initialAccounts={[]}
            onContinue={jest.fn()}
            onOpenGameSettings={jest.fn()}
            onRefresh={onRefresh}
            service={{ ...service, addAccount }}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    await fireEvent.changeText(screen.getByLabelText('Player Tag (#ABC123)'), '#NEW');
    await fireEvent.press(screen.getByRole('button', { name: 'Add account' }));
    await waitFor(() => expect(screen.getByRole('button', { name: 'Retry' })).toBeTruthy());
    await fireEvent.press(screen.getByRole('button', { name: 'Retry' }));
    await waitFor(() => expect(screen.getByText('New Player')).toBeTruthy());
    expect(addAccount).toHaveBeenCalledTimes(2);
    expect(onRefresh).toHaveBeenCalledTimes(1);
  });

  it('verifies in place, reports success, and refreshes account bootstrap', async () => {
    const onRefresh = jest.fn(async () => undefined);
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ManageLinkedAccountsScreen
            continueLabel="Continue"
            firstConnection
            initialAccounts={[
              {
                playerTag: '#ONE',
                name: 'One',
                townHallLevel: 17,
                isVerified: false,
                hidden: false,
                raw: {},
              },
              {
                playerTag: '#TWO',
                name: 'Two',
                townHallLevel: 18,
                isVerified: true,
                hidden: false,
                raw: {},
              },
            ]}
            onContinue={jest.fn()}
            onOpenGameSettings={jest.fn()}
            onRefresh={onRefresh}
            service={{
              ...service,
              accounts: [
                {
                  playerTag: '#ONE',
                  isVerified: true,
                  hidden: false,
                  raw: { name: 'One', townHallLevel: 17 },
                },
                {
                  playerTag: '#TWO',
                  isVerified: true,
                  hidden: false,
                  raw: { name: 'Two', townHallLevel: 18 },
                },
              ],
              addAccountWithToken: async () => ({ success: true, message: null }),
            }}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    await fireEvent.press(screen.getByRole('button', { name: 'Verify' }));
    await waitFor(() => expect(screen.getByLabelText('Account API Token')).toBeTruthy());
    await fireEvent.changeText(screen.getByLabelText('Account API Token'), 'token');
    await fireEvent.press(screen.getAllByRole('button', { name: 'Verify' }).at(-1)!);
    await waitFor(() => expect(onRefresh).toHaveBeenCalledTimes(1));
    expect(screen.getByText('Account verified successfully!')).toBeTruthy();
    const names = screen.getAllByText(/^(One|Two)$/).map(({ props }) => props.children);
    expect(names).toEqual(['One', 'Two']);
  });

  it('inserts an account transferred by API-token verification', async () => {
    const transferred = {
      playerTag: '#NEW',
      isVerified: true,
      hidden: false,
      raw: { name: 'Transferred', townHallLevel: 16 },
    };
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ManageLinkedAccountsScreen
            continueLabel="Continue"
            firstConnection
            initialAccounts={[]}
            onContinue={jest.fn()}
            onOpenGameSettings={jest.fn()}
            service={{
              ...service,
              accounts: [transferred],
              addAccount: async () => ({
                code: 409,
                message: 'Account linked elsewhere',
                account: transferred,
              }),
              addAccountWithToken: async () => ({ success: true, message: null }),
            }}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    await fireEvent.changeText(screen.getByLabelText('Player Tag (#ABC123)'), '#NEW');
    await fireEvent.press(screen.getByRole('button', { name: 'Add account' }));
    await fireEvent.changeText(screen.getByLabelText('Account API Token'), 'token');
    await fireEvent.press(screen.getAllByRole('button', { name: 'Verify' }).at(-1)!);

    await waitFor(() => expect(screen.getByText('Transferred')).toBeTruthy());
  });
});
