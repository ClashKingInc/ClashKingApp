import { refreshLinkedAccountsForCurrentAuth } from './startup';

function fixture() {
  const auth = {
    canUseApp: true,
    state: {
      accessToken: 'test',
      isAuthenticated: true,
      followerCount: null,
      currentUser: {
        userId: 'user',
        username: 'Player',
        avatarUrl: '',
        authMethods: [],
        email: null,
      },
    },
  };
  const accounts = {
    setCurrentUserId: jest.fn(),
    fetchAccounts: jest.fn(async () => []),
    hasVerifiedAccounts: true,
    initializeForCurrentUser: jest.fn(async () => {
      throw new Error('Optional player hydration failed');
    }),
  };
  return { auth, accounts };
}

it('continues with freshly verified links without awaiting optional profile hydration', async () => {
  const { auth, accounts } = fixture();
  await expect(refreshLinkedAccountsForCurrentAuth(auth, accounts)).resolves.toMatchObject({
    destination: 'home',
  });
  expect(accounts.fetchAccounts).toHaveBeenCalledTimes(1);
  expect(accounts.initializeForCurrentUser).not.toHaveBeenCalled();
});

it('does not hide a current failed link refresh behind previously verified state', async () => {
  const { auth, accounts } = fixture();
  accounts.fetchAccounts.mockRejectedValueOnce(new Error('Links unavailable'));
  await expect(refreshLinkedAccountsForCurrentAuth(auth, accounts)).rejects.toThrow(
    'Links unavailable',
  );
});

it('stays in setup when the fresh account list has no verified link', async () => {
  const { auth, accounts } = fixture();
  accounts.fetchAccounts.mockImplementationOnce(async () => {
    accounts.hasVerifiedAccounts = false;
    return [];
  });
  await expect(refreshLinkedAccountsForCurrentAuth(auth, accounts)).resolves.toMatchObject({
    destination: 'account-setup',
  });
});

it('does not continue when the session changes while links are refreshing', async () => {
  const { auth, accounts } = fixture();
  accounts.fetchAccounts.mockImplementationOnce(async () => {
    auth.canUseApp = false;
    return [];
  });
  await expect(refreshLinkedAccountsForCurrentAuth(auth, accounts)).resolves.toMatchObject({
    destination: 'login',
    authenticated: false,
  });
});
