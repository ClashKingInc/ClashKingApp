import type { AccountMutationResult, AccountVerificationResult } from '../../auth/account-service';
import type { CocAccountLink } from '../../auth/models';

export interface LinkedAccountPresentationService {
  readonly accounts: readonly CocAccountLink[];
  addAccount(playerTag: string): Promise<AccountMutationResult>;
  addAccountWithToken(playerTag: string, apiToken: string): Promise<AccountVerificationResult>;
  removeAccount(playerTag: string): Promise<boolean>;
  updateAccountOrder(playerTags: readonly string[]): Promise<boolean>;
}

export type LinkedAccountItem = CocAccountLink & {
  readonly name: string;
  readonly townHallLevel: number;
};

export function accountPresentationItem(
  account: CocAccountLink,
  profile?: { readonly name: string; readonly townHallLevel: number } | null,
): LinkedAccountItem {
  const rawName = typeof account.raw.name === 'string' ? account.raw.name.trim() : '';
  const rawTownHall =
    typeof account.raw.townHallLevel === 'number' ? Math.trunc(account.raw.townHallLevel) : 0;
  return {
    ...account,
    name: rawName || profile?.name || account.playerTag,
    townHallLevel: Math.max(1, rawTownHall || profile?.townHallLevel || 1),
  };
}

export function linkedAccountTags(
  accounts: readonly Pick<LinkedAccountItem, 'playerTag'>[],
): string[] {
  return accounts.map((account) => account.playerTag);
}
