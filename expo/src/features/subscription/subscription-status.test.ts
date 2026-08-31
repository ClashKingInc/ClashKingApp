import { SubscriptionStatus } from './subscription-status';
import type { ApiClient } from '../../core/api/client';
import { SubscriptionService } from './subscription-service';

describe('SubscriptionStatus', () => {
  it('matches Flutter defaults and parses the current API contract', () => {
    expect(SubscriptionStatus.fromJson(null)).toEqual(
      new SubscriptionStatus('stripe', 'none', false, 0, 0),
    );
    expect(
      SubscriptionStatus.fromJson({
        provider: 'stripe',
        status: 'active',
        active: true,
        bookmarkNotificationsLimit: 10,
        rosterAssistantMonthlyCreditUsd: 5,
      }),
    ).toEqual(new SubscriptionStatus('stripe', 'active', true, 10, 5));
    expect(SubscriptionStatus.fromJson({ bookmarkNotificationsLimit: 10.9 })).toMatchObject({
      bookmarkNotificationsLimit: 10,
    });
  });
});

describe('SubscriptionService', () => {
  it('uses the authenticated Flutter endpoint and parses its response', async () => {
    const requestRecord = jest.fn(async () => ({ active: true, status: 'active' }));
    const service = new SubscriptionService({ requestRecord } as unknown as ApiClient);

    await expect(service.load()).resolves.toMatchObject({ active: true, status: 'active' });
    expect(requestRecord).toHaveBeenCalledWith('/billing/subscription', {
      requiresAuth: true,
    });
  });
});
