import { SubscriptionStatus } from './subscription-status';
import { createContractTestApi } from '../../core/api/contract-api.testing';
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
    const fetchImplementation = jest.fn(
      async () =>
        new Response(
          JSON.stringify({
            provider: 'stripe',
            active: true,
            status: 'active',
            checkoutEnabled: true,
            assignedServerId: null,
            rosterAssistantSpentUsd: 0,
            rosterAssistantRemainingUsd: 5,
            bookmarkNotificationsLimit: 10,
            rosterAssistantMonthlyCreditUsd: 5,
          }),
        ),
    );
    const service = new SubscriptionService(
      createContractTestApi({
        baseUrl: 'https://api.test',
        tokenProvider: { getAccessToken: async () => 'token' },
        fetchImplementation,
      }),
    );

    await expect(service.load()).resolves.toMatchObject({ active: true, status: 'active' });
    const request = (fetchImplementation.mock.calls as unknown as [Request][])[0]![0];
    expect(request.url).toBe('https://api.test/v2/billing/subscription');
    expect(request.headers.get('authorization')).toBe('Bearer token');
  });
});
