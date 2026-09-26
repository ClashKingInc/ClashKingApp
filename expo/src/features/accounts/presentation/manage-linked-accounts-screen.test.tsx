import { act, fireEvent, render, waitFor } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';

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

jest.mock('react-native-safe-area-context', () => {
  const actual = jest.requireActual('react-native-safe-area-context');
  return {
    ...actual,
    useSafeAreaInsets: () => ({ top: 47, right: 0, bottom: 34, left: 0 }),
  };
});

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
      containerStyle,
    }: {
      data: readonly unknown[];
      renderItem: (parameters: Record<string, unknown>) => React.ReactNode;
      ListHeaderComponent?: React.ReactNode;
      ListEmptyComponent?: React.ReactNode;
      containerStyle?: import('react-native').StyleProp<import('react-native').ViewStyle>;
    }) =>
      ReactModule.createElement(
        MockView,
        { testID: 'draggable-account-container', style: containerStyle },
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
  it('clears a failed Continue message when retry succeeds and gives empty failures meaningful text', async () => {
    const onContinue = jest
      .fn()
      .mockRejectedValueOnce(new Error(''))
      .mockResolvedValueOnce(undefined);
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <ManageLinkedAccountsScreen
            continueLabel="Continue"
            firstConnection
            initialAccounts={[
              {
                playerTag: '#ONE',
                name: 'One',
                townHallLevel: 18,
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
    await fireEvent.press(screen.getByRole('button', { name: 'Continue' }));
    await waitFor(() =>
      expect(screen.getByText(/Refresh failed: We couldn't complete your request/)).toBeTruthy(),
    );
    await fireEvent.press(screen.getByRole('button', { name: 'Continue' }));
    await waitFor(() => expect(onContinue).toHaveBeenCalledTimes(2));
    expect(screen.queryByText(/Refresh failed:/)).toBeNull();
  });

  it('keeps verification successful when optional hydration fails after token submission', async () => {
    const onRefresh = jest
      .fn()
      .mockRejectedValueOnce(new Error('Profile unavailable'));
    const linked = {
      playerTag: '#ONE',
      isVerified: true,
      hidden: false,
      raw: { name: 'One', townHallLevel: 18 },
    };
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <ManageLinkedAccountsScreen
            continueLabel="Continue"
            firstConnection
            initialAccounts={[]}
            onContinue={jest.fn()}
            onRefresh={onRefresh}
            onOpenGameSettings={jest.fn()}
            service={{
              ...service,
              accounts: [linked],
              addAccountWithToken: async () => ({ success: true, message: null }),
            }}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );
    await fireEvent.changeText(screen.getByLabelText('Player Tag (#ABC123)'), '#ONE');
    await fireEvent.press(screen.getByRole('button', { name: 'Add account' }));
    expect(screen.getByText('Verify Account')).toBeTruthy();
    expect(onRefresh).not.toHaveBeenCalled();
    await fireEvent.changeText(screen.getByLabelText('Account API Token'), 'token');
    await fireEvent.press(screen.getAllByRole('button', { name: 'Verify' }).at(-1)!);
    await waitFor(() =>
      expect(screen.getByText('Refresh failed: Profile unavailable')).toBeTruthy(),
    );
    expect(screen.getByText('Account verified successfully!')).toBeTruthy();
    expect(onRefresh).toHaveBeenCalledTimes(1);
  });

  it('explains an unavailable linking provider and keeps the token ready to retry', async () => {
    const addAccount = jest.fn();
    const addAccountWithToken = jest
      .fn()
      .mockResolvedValueOnce({
        success: false,
        message: 'Clash account lookup is unavailable',
      })
      .mockResolvedValueOnce({
        success: true,
        message: null,
      });
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <ManageLinkedAccountsScreen
            continueLabel="Continue"
            initialAccounts={[]}
            onContinue={jest.fn()}
            onOpenGameSettings={jest.fn()}
            service={{
              ...service,
              accounts: [{
                playerTag: '#2J8V28GV0',
                isVerified: true,
                hidden: false,
                raw: { name: 'Linked Player', townHallLevel: 18 },
              }],
              addAccount,
              addAccountWithToken,
            }}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );
    await fireEvent.changeText(screen.getByLabelText('Player Tag (#ABC123)'), '#2J8V28GV0');
    await fireEvent.press(screen.getByRole('button', { name: 'Add account' }));
    expect(addAccount).not.toHaveBeenCalled();
    expect(addAccountWithToken).not.toHaveBeenCalled();
    await fireEvent.changeText(screen.getByLabelText('Account API Token'), 'token');
    await fireEvent.press(screen.getAllByRole('button', { name: 'Verify' }).at(-1)!);
    await waitFor(() =>
      expect(screen.getByText('Clash account lookup is unavailable')).toBeTruthy(),
    );
    expect(screen.getByLabelText('Account API Token').props.value).toBe('token');
    await fireEvent.press(screen.getAllByRole('button', { name: 'Verify' }).at(-1)!);
    await waitFor(() => expect(screen.getByText('Linked Player')).toBeTruthy());
    expect(addAccountWithToken).toHaveBeenNthCalledWith(2, '#2J8V28GV0', 'token');
    expect(addAccount).not.toHaveBeenCalled();
  });

  it('gives the empty linking form a sized container and supports adding, verifying, and continuing', async () => {
    const account = {
      playerTag: '#NEW',
      isVerified: false,
      hidden: false,
      raw: { name: 'New Player', townHallLevel: 18 },
    };
    const addAccount = jest.fn();
    const addAccountWithToken = jest.fn(async () => ({ success: true, message: null }));
    const onContinue = jest.fn();
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ManageLinkedAccountsScreen
            continueLabel="Continue"
            initialAccounts={[]}
            onContinue={onContinue}
            onOpenGameSettings={jest.fn()}
            service={{
              ...service,
              accounts: [{ ...account, isVerified: true }],
              addAccount,
              addAccountWithToken,
            }}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    // DraggableFlatList wraps its list in a separate View: sizing only the inner
    // list leaves the welcome text, player-tag field, and empty state collapsed.
    expect(
      StyleSheet.flatten(screen.getByTestId('draggable-account-container').props.style),
    ).toEqual(expect.objectContaining({ flex: 1, minHeight: 0 }));
    expect(
      screen.getByText(
        'Please add one or more Clash of Clans accounts to your profile. You can add or remove accounts later.',
      ),
    ).toBeTruthy();
    expect(screen.getByText('Tap the + button to add your account')).toBeTruthy();
    expect(screen.getByText('No account linked to your profile found')).toBeTruthy();

    await fireEvent.press(screen.getByRole('button', { name: 'Continue' }));
    expect(onContinue).not.toHaveBeenCalled();
    await fireEvent.changeText(screen.getByLabelText('Player Tag (#ABC123)'), '#NEW');
    await fireEvent.press(screen.getByRole('button', { name: 'Add account' }));
    expect(screen.getByText('Verify Account')).toBeTruthy();
    expect(screen.getByLabelText('Account API Token')).toBeTruthy();
    expect(addAccount).not.toHaveBeenCalled();
    expect(addAccountWithToken).not.toHaveBeenCalled();
    expect(onContinue).not.toHaveBeenCalled();

    await fireEvent.press(screen.getAllByRole('button', { name: 'Verify' }).at(-1)!);
    expect(addAccountWithToken).not.toHaveBeenCalled();
    await fireEvent.changeText(screen.getByLabelText('Account API Token'), 'token');
    await fireEvent.press(screen.getAllByRole('button', { name: 'Verify' }).at(-1)!);
    await waitFor(() => expect(screen.getByText('Account verified successfully!')).toBeTruthy());
    expect(addAccountWithToken).toHaveBeenCalledWith('#NEW', 'token');
    expect(screen.getByText('New Player')).toBeTruthy();
    expect(screen.queryByText('No account linked to your profile found')).toBeNull();
    await fireEvent.press(screen.getByRole('button', { name: 'Continue' }));
    await waitFor(() => expect(onContinue).toHaveBeenCalledTimes(1));
  });

  it('keeps Continue above the device bottom inset while the account list owns scrolling', async () => {
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ManageLinkedAccountsScreen
            continueLabel="Continue"
            firstConnection
            initialAccounts={Array.from({ length: 12 }, (_, index) => ({
              playerTag: `#PLAYER${index}`,
              name: `Player ${index}`,
              townHallLevel: 17,
              isVerified: index === 0,
              hidden: false,
              raw: {},
            }))}
            onContinue={jest.fn()}
            onOpenGameSettings={jest.fn()}
            service={service}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    expect(
      StyleSheet.flatten(screen.getByTestId('linked-accounts-continue').props.style).paddingBottom,
    ).toBe(42);
    expect(screen.getByRole('button', { name: 'Continue' })).toBeTruthy();
    expect(
      StyleSheet.flatten(screen.getByTestId('draggable-account-container').props.style),
    ).toEqual(expect.objectContaining({ flex: 1, minHeight: 0 }));
  });

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

  it('reconciles a refreshed verified account snapshot into local screen state', async () => {
    const onContinue = jest.fn();
    const commonProps = {
      continueLabel: 'Continue',
      firstConnection: false,
      onContinue,
      onOpenGameSettings: jest.fn(),
      service,
    } as const;
    const account = {
      playerTag: '#GCPVU8CCG',
      name: 'Linked Player',
      townHallLevel: 17,
      hidden: false,
      raw: {},
    } as const;
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ManageLinkedAccountsScreen
            {...commonProps}
            initialAccounts={[{ ...account, isVerified: false }]}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );
    expect(screen.getByRole('button', { name: 'Verify' })).toBeTruthy();

    await act(async () => {
      screen.rerender(
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <ManageLinkedAccountsScreen
              {...commonProps}
              initialAccounts={[{ ...account, isVerified: true }]}
            />
          </CKThemeProvider>
        </I18nProvider>,
      );
    });

    await waitFor(() => expect(screen.getByText('Verified')).toBeTruthy());
    expect(screen.queryByRole('button', { name: 'Verify' })).toBeNull();
    expect(onContinue).not.toHaveBeenCalled();
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
    expect(continueButton.props.accessibilityState).not.toEqual(
      expect.objectContaining({ disabled: true }),
    );
    fireEvent.press(continueButton);
    await waitFor(() =>
      expect(
        screen.getByText(
          'Home needs at least one verified Clash account. Link an account or verify an existing link to continue.',
        ),
      ).toBeTruthy(),
    );
    fireEvent.press(screen.getByRole('button', { name: 'Back' }));
    expect(onBack).not.toHaveBeenCalled();
    expect(onContinue).not.toHaveBeenCalled();
  });

  it('keeps the verification dialog open after a failed link and refreshes after retry succeeds', async () => {
    const addAccount = jest.fn();
    const addAccountWithToken = jest
      .fn()
      .mockResolvedValueOnce({ success: false, message: 'Failed to add account. Please try again.' })
      .mockResolvedValueOnce({
        success: true,
        message: null,
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
            service={{
              ...service,
              accounts: [{
                playerTag: '#NEW',
                isVerified: true,
                hidden: false,
                raw: { name: 'New Player', townHallLevel: 18 },
              }],
              addAccount,
              addAccountWithToken,
            }}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    await fireEvent.changeText(screen.getByLabelText('Player Tag (#ABC123)'), '#NEW');
    await fireEvent.press(screen.getByRole('button', { name: 'Add account' }));
    expect(addAccount).not.toHaveBeenCalled();
    expect(addAccountWithToken).not.toHaveBeenCalled();
    await fireEvent.changeText(screen.getByLabelText('Account API Token'), 'token');
    await fireEvent.press(screen.getAllByRole('button', { name: 'Verify' }).at(-1)!);
    await waitFor(() =>
      expect(screen.getByText('Failed to add account. Please try again.')).toBeTruthy(),
    );
    expect(onRefresh).not.toHaveBeenCalled();
    await fireEvent.press(screen.getAllByRole('button', { name: 'Verify' }).at(-1)!);
    await waitFor(() => expect(screen.getByText('New Player')).toBeTruthy());
    expect(addAccountWithToken).toHaveBeenCalledTimes(2);
    expect(addAccount).not.toHaveBeenCalled();
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

  it('requires API-token verification before linking an account linked elsewhere', async () => {
    const transferred = {
      playerTag: '#NEW',
      isVerified: true,
      hidden: false,
      raw: { name: 'Transferred', townHallLevel: 16 },
    };
    const addAccountWithToken = jest.fn(async () => ({ success: true, message: null }));
    const addAccount = jest.fn();
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
              addAccount,
              addAccountWithToken,
            }}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    await fireEvent.changeText(screen.getByLabelText('Player Tag (#ABC123)'), '#NEW');
    await fireEvent.press(screen.getByRole('button', { name: 'Add account' }));
    await waitFor(() => expect(screen.getByText('Verify Account')).toBeTruthy());
    expect(screen.getByLabelText('Account API Token')).toBeTruthy();
    expect(screen.getAllByText('#NEW').length).toBeGreaterThan(0);
    expect(screen.queryByText('Failed to add the account. Please try again later.')).toBeNull();
    expect(addAccountWithToken).not.toHaveBeenCalled();
    expect(addAccount).not.toHaveBeenCalled();

    await fireEvent.changeText(screen.getByLabelText('Account API Token'), 'token');
    await fireEvent.press(screen.getAllByRole('button', { name: 'Verify' }).at(-1)!);

    await waitFor(() => expect(addAccountWithToken).toHaveBeenCalledWith('#NEW', 'token'));
    await waitFor(() => expect(screen.getByText('Transferred')).toBeTruthy());
    expect(addAccount).not.toHaveBeenCalled();
  });
});
