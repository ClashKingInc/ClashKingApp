import { UnauthorizedException, type ApiClient, type ApiResponse } from '../../core/api/client';
import { STORAGE_KEYS } from '../../core/storage/storage';
import type { StringStore } from '../../services/storage/auth-storage';
import { expectRecord, parseCocAccountLink, type CocAccountLink } from './models';

const ALL_HTTP_STATUSES = Array.from({ length: 500 }, (_, index) => index + 100);

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
  private readonly listeners = new Set<() => void>();

  constructor(
    private readonly api: ApiClient,
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

  async initializeForCurrentUser(userId: string | null): Promise<void> {
    if (this.bootstrapCoordinator !== null) {
      await this.bootstrapCoordinator(userId);
      return;
    }
    this.setCurrentUserId(userId);
    await Promise.all([this.loadSelectedTag(), this.fetchAccounts()]);
    await this.initializeSelectedTag();
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
      const response = await this.rawRequest(this.linksEndpoint(), 'GET');
      if (response.status !== 200) {
        throw new AccountHttpException(
          response.status,
          `Failed to fetch CoC accounts (${response.status})`,
        );
      }
      const data = parseResponseRecord(response, 'CoC accounts payload');
      if (!Array.isArray(data.items)) {
        throw new TypeError('Invalid CoC accounts payload');
      }
      this.accountLinks = data.items.map(parseCocAccountLink);
      this.notify();
      return this.accountLinks;
    } catch (error) {
      this.report('accounts.fetch', error);
      throw error;
    }
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
      const response = await this.rawRequest(this.linksEndpoint(), 'POST', {
        player_tag: playerTag,
        api_token: apiToken,
      });
      if (response.status >= 200 && response.status < 300) {
        const data = parseOptionalResponseRecord(response);
        const returnedAccount = normalizeAccount(data.account);
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
            : `Failed to add account: ${String(error)}`,
      };
    }
  }

  async verifyAccount(playerTag: string, apiToken: string): Promise<AccountVerificationResult> {
    try {
      const response = await this.rawRequest(this.linksEndpoint(), 'POST', {
        player_tag: playerTag,
        api_token: apiToken,
      });
      if (response.status >= 200 && response.status < 300) {
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
            : `Verification failed: ${String(error)}`,
      };
    }
  }

  async removeAccount(playerTag: string): Promise<boolean> {
    try {
      const response = await this.rawRequest(
        this.linksEndpoint(encodeURIComponent(playerTag)),
        'DELETE',
      );
      if (response.status < 200 || response.status >= 300) {
        this.report(
          'accounts.remove',
          new AccountHttpException(
            response.status,
            `Failed to remove CoC account (${response.status})`,
          ),
        );
        return false;
      }
      this.accountLinks = this.accountLinks.filter((account) => account.playerTag !== playerTag);
      this.notify();
      return true;
    } catch (error) {
      this.report('accounts.remove', error);
      return false;
    }
  }

  async updateAccountHidden(playerTag: string, hidden: boolean): Promise<void> {
    try {
      const response = await this.rawRequest(
        this.linksEndpoint(encodeURIComponent(playerTag)),
        'PATCH',
        { hidden },
      );
      if (response.status < 200 || response.status >= 300) {
        throw new AccountHttpException(
          response.status,
          `Failed to update account visibility (${response.status})`,
        );
      }
      this.accountLinks = this.accountLinks.map((account) =>
        account.playerTag === playerTag
          ? { ...account, hidden, raw: { ...account.raw, hidden } }
          : account,
      );
      this.notify();
    } catch (error) {
      this.report('accounts.visibility', error);
      throw error;
    }
  }

  async updateAccountOrder(playerTags: readonly string[]): Promise<boolean> {
    const response = await this.rawRequest(this.linksEndpoint('order'), 'PUT', {
      ordered_tags: playerTags,
    });
    if (response.status < 200 || response.status >= 300) {
      this.report(
        'accounts.order',
        new AccountHttpException(
          response.status,
          `Failed to update account order (${response.status})`,
        ),
      );
      return false;
    }
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
    return true;
  }

  async loadSelectedTag(): Promise<string | null> {
    const stored = await this.preferences.getItem(STORAGE_KEYS.selectedTag);
    this.selectedPlayerTag = stored === null || stored.length === 0 ? null : stored;
    this.notify();
    return this.selectedPlayerTag;
  }

  async initializeSelectedTag(): Promise<string | null> {
    if (this.accountLinks.length > 0 && this.selectedPlayerTag === null) {
      await this.setSelectedTag(this.accountLinks[0]!.playerTag);
    }
    return this.selectedPlayerTag;
  }

  async setSelectedTag(tag: string | null): Promise<void> {
    this.selectedPlayerTag = tag;
    if (tag === null) await this.preferences.removeItem(STORAGE_KEYS.selectedTag);
    else await this.preferences.setItem(STORAGE_KEYS.selectedTag, tag);
    this.notify();
  }

  private async addAccountRequest(
    playerTag: string,
    apiToken?: string,
  ): Promise<AccountMutationResult> {
    try {
      const response = await this.rawRequest(this.linksEndpoint(), 'POST', {
        player_tag: playerTag,
        ...(apiToken === undefined ? {} : { api_token: apiToken }),
      });
      if (response.status < 200 || response.status >= 300) {
        this.report(
          'coc_account.add',
          new AccountHttpException(
            response.status,
            `Failed to add CoC account (${response.status})`,
          ),
        );
      }
      const data = parseOptionalResponseRecord(response);
      const account = normalizeAccount(data.account);
      if (response.status === 200 && account !== null) {
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
        code: error instanceof UnauthorizedException ? 401 : 500,
        message:
          error instanceof UnauthorizedException
            ? 'User not authenticated'
            : 'Internal server error',
        account: null,
      };
    }
  }

  private linksEndpoint(path?: string): string {
    if (this.currentUserId === null) {
      throw new UnauthorizedException('User not authenticated');
    }
    const root = `/links/${encodeURIComponent(this.currentUserId)}`;
    return path === undefined ? root : `${root}/${path}`;
  }

  private rawRequest(
    endpoint: string,
    method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE',
    body?: unknown,
  ): Promise<ApiResponse> {
    return this.api.request(endpoint, {
      method,
      body,
      requiresAuth: true,
      acceptedStatuses: ALL_HTTP_STATUSES,
    });
  }

  private report(operation: string, error: unknown): void {
    this.reportError?.(operation, error);
  }

  private notify(): void {
    for (const listener of this.listeners) listener();
  }
}

function parseResponseRecord(response: ApiResponse, label: string): Record<string, unknown> {
  return expectRecord(JSON.parse(response.bodyText) as unknown, label);
}

function parseOptionalResponseRecord(response: ApiResponse): Record<string, unknown> {
  if (response.bodyText.trim().length === 0) return {};
  try {
    const decoded: unknown = JSON.parse(response.bodyText);
    return isRecord(decoded) ? decoded : {};
  } catch {
    return {};
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
