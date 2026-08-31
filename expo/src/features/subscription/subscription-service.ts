import type { ApiClient } from '../../core/api/client';
import { SubscriptionStatus } from './subscription-status';

export class SubscriptionService {
  static readonly statusEndpoint = '/billing/subscription';

  constructor(private readonly api: ApiClient) {}

  async load(): Promise<SubscriptionStatus> {
    const json = await this.api.requestRecord(SubscriptionService.statusEndpoint, {
      requiresAuth: true,
    });
    return SubscriptionStatus.fromJson(json);
  }
}
