import { subscriptionBackDirection } from './subscription-root';

jest.mock('../../core/app/runtime-context', () => ({ useAppRuntime: jest.fn() }));

describe('SubscriptionRoot', () => {
  it('uses the platform back direction for left-to-right and right-to-left locales', () => {
    expect(subscriptionBackDirection(false)).toBe('ltr');
    expect(subscriptionBackDirection(true)).toBe('rtl');
  });
});
