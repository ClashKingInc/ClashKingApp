import {
  LinksAddEndpoint,
  LinksActivityEndpoint,
  LinksListEndpoint,
  LinksOrderEndpoint,
  LinksRemoveEndpoint,
  LinksVisibilityEndpoint,
} from '@clashking/api-contracts/expo';
import { ApiResponseError } from '@clashking/api-client';
import { Effect } from 'effect';

import { UnauthorizedException, type ContractApiService } from '../../core/api/contract-api';
import { STORAGE_KEYS } from '../../core/storage/storage';
import type { StringStore } from '../../services/storage/auth-storage';
import { parseCocAccountLink, type CocAccountLink } from './models';

export interface AccountMutationResult {
  readonly code: number;
  readonly message: string | null;
  readonly account: CocAccountLink | null;
}

export interface AccountVerificationResult {
  readonly success: boolean;
  readonly message: string | null;
}

export type AccountErrorReporter = (operation: string, error: unknown) => void;
export type SelectedTagChangeHandler = (tag: string | null) => Promise<void>;

export class AccountHttpException extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'AccountHttpException';
  }
}

export class CocAccountService {
  private currentUserId: string | null = null;
  private accountLinks: CocAccountLink[] = [];
  private selectedPlayerTag: string | null = null;
  private lastRefreshedAt: Date | null = null;
  private bootstrapCoordinator: ((userId: string | null) => Promise<void>) | null = null;
  private selectedTagChangeHandler: SelectedTagChangeHandler | null = null;
  private readonly listeners = new Set<() => void>();

  constructor(
    private readonly api: ContractApiService,
    private readonly preferences: StringStore,
    private readonly reportError?: AccountErrorReporter,
  ) {}

  get accounts(): readonly CocAccountLink[] {
    return this.accountLinks;
  }

  get verifiedAccounts(): readonly CocAccountLink[] {
    return this.accountLinks.filter((account) => account.isVerified);
  }

  get hasVerifiedAccounts(): boolean {
    return this.verifiedAccounts.length > 0;
  }

  get selectedTag(): string | null {
    return this.selectedPlayerTag;
  }

  get lastRefresh(): Date | null {
    return this.lastRefreshedAt;
  }

  get userId(): string | null {
    return this.currentUserId;
  }

  subscribe(listener: () => void): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  setBootstrapCoordinator(coordinator: (userId: string | null) => Promise<void>): void {
    this.bootstrapCoordinator = coordinator;
  }

  setSelectedTagChangeHandler(handler: SelectedTagChangeHandler): void {
    this.selectedTagChangeHandler = handler;
  }

  async initializeForCurrentUser(userId: string | null): Promise<void> {
    if (this.bootstrapCoordinator !== null) {
      await this.bootstrapCoordinator(userId);
      return;
    }
    this.setCurrentUserId(userId);
    await this.loadSelectedTag();
    await this.fetchAccounts();
  }

  setCurrentUserId(userId: string | null): void {
    const normalized = userId?.trim() ?? '';
    this.currentUserId = normalized.length === 0 ? null : normalized;
  }

  clearAccountData(): void {
    this.accountLinks = [];
    this.selectedPlayerTag = null;
    this.lastRefreshedAt = null;
    this.notify();
  }

  updateRefreshTime(now = new Date()): void {
    this.lastRefreshedAt = now;
    this.notify();
  }

  async fetchAccounts(): Promise<readonly CocAccountLink[]> {
    try {
      const data = await Effect.runPromise(
        this.api.execute(LinksListEndpoint, {
          path: { userId: this.requireUserId() },
          query: {},
          body: {},
        }),
      );
      this.accountLinks = data.items.map(parseCocAccountLink);
      const previousSelection = this.selectedPlayerTag;
      await this.initializeSelectedTag();
      if (this.selectedPlayerTag === previousSelection) this.notify();
      return this.accountLinks;
    } catch (error) {
      this.report('accounts.fetch', error);
      throw error;
    }
  }

  async recordActivity(): Promise<void> {
    await Effect.runPromise(
      this.api.execute(LinksActivityEndpoint, {
        path: { userId: this.requireUserId() },
        query: {},
        body: {},
      }),
    );
  }

  async addAccount(playerTag: string): Promise<AccountMutationResult> {
    return this.addAccountRequest(playerTag);
  }

  async addAccountWithVerification(
    playerTag: string,
    apiToken: string,
  ): Promise<AccountMutationResult> {
    return this.addAccountRequest(playerTag, apiToken);
  }

  async addAccountWithToken(
    playerTag: string,
    apiToken: string,
  ): Promise<AccountVerificationResult> {
    try {
      const response = await Effect.runPromise(
        this.api.executeStatus(LinksAddEndpoint, {
          path: { userId: this.requireUserId() },
          query: {},
          body: { player_tag: playerTag, api_token: apiToken },
        }),
      );
      if (response.ok) {
        const returnedAccount = normalizeAccount(response.value.account);
        await this.fetchAccounts();
        if (returnedAccount !== null) {
          this.accountLinks = this.accountLinks.map((account) =>
            account.playerTag === playerTag
              ? {
                  ...account,
                  raw: {
                    ...account.raw,
                    name: returnedAccount.raw.name,
                    townHallLevel: returnedAccount.raw.townHallLevel,
                  },
                }
              : account,
          );
          this.notify();
        }
        return { success: true, message: null };
      }
      if (response.status === 403) {
        return { success: false, message: 'Invalid API token for this account' };
      }
      if (response.status === 404) {
        return { success: false, message: 'Account not found' };
      }
      return {
        success: false,
        message: 'Failed to add account. Please try again.',
      };
    } catch (error) {
      if (!(error instanceof UnauthorizedException)) this.report('coc_account.add', error);
      return {
        success: false,
        message:
          error instanceof UnauthorizedException
            ? 'User not authenticated'
            : 'Failed to add account. Please try again.',
      };
    }
  }

  async verifyAccount(playerTag: string, apiToken: string): Promise<AccountVerificationResult> {
    try {
      const response = await Effect.runPromise(
        this.api.executeStatus(LinksAddEndpoint, {
          path: { userId: this.requireUserId() },
          query: {},
          body: { player_tag: playerTag, api_token: apiToken },
        }),
      );
      if (response.ok) {
        this.accountLinks = this.accountLinks.map((account) =>
          account.playerTag === playerTag
            ? {
                ...account,
                isVerified: true,
                raw: { ...account.raw, is_verified: true },
              }
            : account,
        );
        this.notify();
        return { success: true, message: null };
      }
      if (response.status === 403) {
        return { success: false, message: 'Invalid API token for this account' };
      }
      if (response.status === 404) {
        return { success: false, message: 'Account not found' };
      }
      return {
        success: false,
        message: 'Verification failed. Please try again.',
      };
    } catch (error) {
      if (!(error instanceof UnauthorizedException)) this.report('coc_account.add', error);
      return {
        success: false,
        message:
          error instanceof UnauthorizedException
            ? 'User not authenticated'
            : 'Verification failed. Please try again.',
      };
    }
  }

  async removeAccount(playerTag: string): Promise<boolean> {
    try {
      await Effect.runPromise(
        this.api.execute(LinksRemoveEndpoint, {
          path: { userId: this.requireUserId(), playerTag },
          query: {},
          body: {},
        }),
      );
      this.accountLinks = this.accountLinks.filter((account) => account.playerTag !== playerTag);
      const previousSelection = this.selectedPlayerTag;
      await this.initializeSelectedTag();
      if (this.selectedPlayerTag === previousSelection) this.notify();
      return true;
    } catch (error) {
      this.report('accounts.remove', error);
      return false;
    }
  }

  async updateAccountHidden(playerTag: string, hidden: boolean): Promise<void> {
    try {
      await Effect.runPromise(
        this.api.execute(LinksVisibilityEndpoint, {
          path: { userId: this.requireUserId(), playerTag },
          query: {},
          body: { hidden },
        }),
      );
      this.accountLinks = this.accountLinks.map((account) =>
        account.playerTag === playerTag
          ? { ...account, hidden, raw: { ...account.raw, hidden } }
          : account,
      );
      this.notify();
    } catch (error) {
      this.report('accounts.visibility', error);
      throw new AccountHttpException(
        error instanceof ApiResponseError ? error.status : 500,
        'Failed to update account visibility',
      );
    }
  }

  async updateAccountOrder(playerTags: readonly string[]): Promise<boolean> {
    const previous = [...this.accountLinks];
    const requested = playerTags.map((tag) => tag.toUpperCase());
    const byTag = new Map(
      this.accountLinks.map((account) => [account.playerTag.toUpperCase(), account]),
    );
    this.accountLinks = [
      ...requested.flatMap((tag) => (byTag.has(tag) ? [byTag.get(tag)!] : [])),
      ...this.accountLinks.filter(
        (account) => !requested.includes(account.playerTag.toUpperCase()),
      ),
    ];
    this.notify();
    try {
      await Effect.runPromise(
        this.api.execute(LinksOrderEndpoint, {
          path: { userId: this.requireUserId() },
          query: {},
          body: { ordered_tags: [...playerTags] },
        }),
      );
      return true;
    } catch (error) {
      this.accountLinks = previous;
      this.notify();
      this.report('accounts.order', error);
      return false;
    }
  }

  async loadSelectedTag(): Promise<string | null> {
    const stored = await this.preferences.getItem(STORAGE_KEYS.selectedTag);
    this.selectedPlayerTag = stored === null || stored.length === 0 ? null : stored;
    this.notify();
    return this.selectedPlayerTag;
  }

  async initializeSelectedTag(): Promise<string | null> {
    const selected = this.accountLinks.find(
      (account) => account.playerTag.toUpperCase() === this.selectedPlayerTag?.toUpperCase(),
    );
    const next = selected?.playerTag ?? this.accountLinks[0]?.playerTag ?? null;
    if (next !== this.selectedPlayerTag) await this.setSelectedTag(next);
    return this.selectedPlayerTag;
  }

  async setSelectedTag(tag: string | null): Promise<void> {
    this.selectedPlayerTag = tag;
    if (tag === null) await this.preferences.removeItem(STORAGE_KEYS.selectedTag);
    else await this.preferences.setItem(STORAGE_KEYS.selectedTag, tag);
    this.notify();
    if (this.selectedTagChangeHandler !== null) {
      try {
        await this.selectedTagChangeHandler(tag);
      } catch (error) {
        this.report('accounts.selection', error);
      }
    }
  }

  private async addAccountRequest(
    playerTag: string,
    apiToken?: string,
  ): Promise<AccountMutationResult> {
    try {
      const response = await Effect.runPromise(
        this.api.executeStatus(LinksAddEndpoint, {
          path: { userId: this.requireUserId() },
          query: {},
          body: {
            player_tag: playerTag,
            ...(apiToken === undefined ? {} : { api_token: apiToken }),
          },
        }),
      );
      if (!response.ok) {
        this.report(
          'coc_account.add',
          new AccountHttpException(
            response.status,
            `Failed to add CoC account (${response.status})`,
          ),
        );
      }
      const data = response.ok ? response.value : response.body;
      const account = response.ok
        ? normalizeAccount(response.value.account)
        : response.status === 409
          ? normalizeAccount(response.body.account)
          : null;
      if (response.ok && account !== null) {
        this.accountLinks = [
          ...this.accountLinks.filter((existing) => existing.playerTag !== account.playerTag),
          account,
        ];
        this.notify();
      }
      return {
        code: response.status,
        message: extractErrorMessage(data),
        account: apiToken === undefined || response.status === 200 ? account : null,
      };
    } catch (error) {
      if (!(error instanceof UnauthorizedException)) this.report('coc_account.add', error);
      return {
        code:
          error instanceof UnauthorizedException
            ? 401
            : error instanceof ApiResponseError
              ? error.status
              : 500,
        message:
          error instanceof UnauthorizedException
            ? 'User not authenticated'
            : 'Internal server error',
        account: null,
      };
    }
  }

  private requireUserId(): string {
    if (this.currentUserId === null) {
      throw new UnauthorizedException('User not authenticated');
    }
    return this.currentUserId;
  }

  private report(operation: string, error: unknown): void {
    this.reportError?.(operation, error);
  }

  private notify(): void {
    for (const listener of this.listeners) listener();
  }
}

function normalizeAccount(value: unknown): CocAccountLink | null {
  if (!isRecord(value)) return null;
  const playerTag = String(value.player_tag ?? value.tag ?? '');
  if (playerTag.length === 0) return null;
  return parseCocAccountLink({
    ...value,
    player_tag: playerTag,
    tag: value.tag ?? playerTag,
    name: value.name ?? 'Unknown Player',
    townHallLevel: value.townHallLevel ?? 1,
    is_verified: value.is_verified ?? false,
    hidden: value.hidden ?? false,
  });
}

function extractErrorMessage(value: Record<string, unknown>): string | null {
  if (typeof value.message === 'string') return value.message;
  if (typeof value.detail === 'string') return value.detail;
  if (isRecord(value.detail) && typeof value.detail.message === 'string') {
    return value.detail.message;
  }
  return null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
