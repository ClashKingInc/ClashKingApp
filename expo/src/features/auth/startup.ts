import type { AuthService } from './auth-service';
import type { CocAccountService } from './account-service';

export type StartupDestination = 'login' | 'account-setup' | 'home';

export interface StartupResult {
  readonly destination: StartupDestination;
  readonly authenticated: boolean;
  readonly hasVerifiedAccount: boolean;
}

/** One startup rule for cold start and post-login: Home requires verification. */
export async function initializeAuthAndAccounts(
  auth: AuthService,
  accounts: CocAccountService,
): Promise<StartupResult> {
  await auth.initializeAuth();
  return initializeAccountsForCurrentAuth(auth, accounts);
}

/** Shared by cold start and the post-login gate after AuthService has a session. */
export async function initializeAccountsForCurrentAuth(
  auth: Pick<AuthService, 'canUseApp' | 'state'>,
  accounts: CocAccountService,
): Promise<StartupResult> {
  if (!auth.canUseApp) {
    return {
      destination: 'login',
      authenticated: false,
      hasVerifiedAccount: false,
    };
  }
  const userId = auth.state.currentUser?.userId ?? null;
  await accounts.initializeForCurrentUser(userId);
  return startupDecision(auth.canUseApp, accounts.hasVerifiedAccounts);
}

export function startupDecision(
  authenticated: boolean,
  hasVerifiedAccount: boolean,
): StartupResult {
  return {
    destination: !authenticated ? 'login' : hasVerifiedAccount ? 'home' : 'account-setup',
    authenticated,
    hasVerifiedAccount: authenticated && hasVerifiedAccount,
  };
}
