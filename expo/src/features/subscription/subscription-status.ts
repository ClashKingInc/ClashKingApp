export class SubscriptionStatus {
  constructor(
    readonly provider = 'stripe',
    readonly status = 'none',
    readonly active = false,
    readonly bookmarkNotificationsLimit = 0,
    readonly rosterAssistantMonthlyCreditUsd = 0,
  ) {}

  static fromJson(value: unknown): SubscriptionStatus {
    const json = isRecord(value) ? value : {};
    return new SubscriptionStatus(
      typeof json.provider === 'string' ? json.provider : 'stripe',
      typeof json.status === 'string' ? json.status : 'none',
      json.active === true,
      Math.trunc(numberValue(json.bookmarkNotificationsLimit)),
      numberValue(json.rosterAssistantMonthlyCreditUsd),
    );
  }
}

function numberValue(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
