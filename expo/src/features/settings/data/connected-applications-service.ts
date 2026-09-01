import { ResponseFormatException, type ApiClient } from '../../../core/api/client';

export const CONNECTED_APPLICATION_GRANTS_ENDPOINT = '/links/shared/grants';

export type ConnectedApplicationAccessMode = 'selected' | 'all_current_and_future';

export interface ConnectedApplication {
  readonly id: string;
  readonly name: string;
  readonly developerName?: string;
}

export interface ConnectedApplicationGrant {
  readonly accessMode: ConnectedApplicationAccessMode;
  readonly selectedPlayerTags: readonly string[];
  readonly connectedAt: string;
  readonly updatedAt: string;
}

export interface ConnectedApplicationGrantItem {
  readonly application: ConnectedApplication;
  readonly grant: ConnectedApplicationGrant;
}

export interface ConnectedApplicationsServiceContract {
  load(): Promise<readonly ConnectedApplicationGrantItem[]>;
  revoke(applicationId: string): Promise<void>;
}

export class ConnectedApplicationsService implements ConnectedApplicationsServiceContract {
  constructor(private readonly api: ApiClient) {}

  load(): Promise<readonly ConnectedApplicationGrantItem[]> {
    return this.api.requestJson(
      CONNECTED_APPLICATION_GRANTS_ENDPOINT,
      { requiresAuth: true },
      decodeGrantList,
    );
  }

  async revoke(applicationId: string): Promise<void> {
    await this.api.delete(
      `${CONNECTED_APPLICATION_GRANTS_ENDPOINT}/${encodeURIComponent(applicationId)}`,
      { requiresAuth: true, acceptedStatuses: [204] },
    );
  }
}

export function decodeGrantList(value: unknown): readonly ConnectedApplicationGrantItem[] {
  const root = expectRecord(value, 'connected application grants');
  if (!Array.isArray(root.items)) {
    throw formatError('Connected application grants must contain an items array.');
  }
  return root.items.map((item, index) => decodeGrantItem(item, index));
}

function decodeGrantItem(value: unknown, index: number): ConnectedApplicationGrantItem {
  const item = expectRecord(value, `connected application grant ${index}`);
  const application = expectRecord(item.application, `connected application ${index}`);
  const grant = expectRecord(item.grant, `connected application access grant ${index}`);
  const accessMode = expectString(grant.access_mode, 'grant.access_mode');
  if (accessMode !== 'selected' && accessMode !== 'all_current_and_future') {
    throw formatError('Connected application grant has an invalid access_mode.');
  }
  if (!Array.isArray(grant.selected_player_tags)) {
    throw formatError('Connected application grant selected_player_tags must be an array.');
  }
  const selectedPlayerTags = grant.selected_player_tags.map((tag) =>
    expectString(tag, 'grant.selected_player_tags[]'),
  );
  const developerName = optionalString(application.developer_name, 'application.developer_name');
  return {
    application: {
      id: expectString(application.id, 'application.id'),
      name: expectString(application.name, 'application.name'),
      ...(developerName === undefined ? {} : { developerName }),
    },
    grant: {
      accessMode,
      selectedPlayerTags,
      connectedAt: expectString(grant.connected_at, 'grant.connected_at'),
      updatedAt: expectString(grant.updated_at, 'grant.updated_at'),
    },
  };
}

function expectRecord(value: unknown, label: string): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw formatError(`Invalid ${label} response.`);
  }
  return value as Record<string, unknown>;
}

function expectString(value: unknown, label: string): string {
  if (typeof value !== 'string') throw formatError(`${label} must be a string.`);
  return value;
}

function optionalString(value: unknown, label: string): string | undefined {
  if (value === undefined || value === null) return undefined;
  return expectString(value, label);
}

function formatError(message: string): ResponseFormatException {
  return new ResponseFormatException(message);
}
