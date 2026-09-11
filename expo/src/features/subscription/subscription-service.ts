import { BillingSubscriptionEndpoint } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../core/api/contract-api';
import { SubscriptionStatus } from './subscription-status';

export class SubscriptionService {
  static readonly statusEndpoint = '/billing/subscription';

  constructor(private readonly api: ContractApiService) {}

  async load(): Promise<SubscriptionStatus> {
    const json = await Effect.runPromise(
      this.api.execute(BillingSubscriptionEndpoint, { path: {}, query: {}, body: {} }),
    );
    return SubscriptionStatus.fromJson(json);
  }
}
