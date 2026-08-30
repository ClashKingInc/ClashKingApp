import type { CocAccountLink } from '../models';

export type PostAuthDestination = 'home' | 'account-setup';

export interface AuthPresentationService {
  signInWithDiscord(): Promise<void>;
  signInWithEmail(email: string, password: string): Promise<void>;
  registerWithEmail(email: string, password: string, username: string): Promise<unknown>;
  verifyEmailWithCode(email: string, code: string): Promise<void>;
  resendVerificationEmail(email: string): Promise<unknown>;
  forgotPassword(email: string): Promise<unknown>;
  resetPassword(email: string, resetCode: string, newPassword: string): Promise<void>;
}

export interface PostAuthPresentationProps {
  loadAccounts: () => Promise<readonly CocAccountLink[]>;
  onDestination: (destination: PostAuthDestination) => void;
  onFailure?: (error: unknown) => void;
}

export function verifiedAccountDestination(
  accounts: readonly CocAccountLink[],
): PostAuthDestination {
  return accounts.some((account) => account.isVerified) ? 'home' : 'account-setup';
}
