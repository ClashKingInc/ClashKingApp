import { subscribeSecondaryBackHandler } from './secondary-back-handler';

describe('subscribeSecondaryBackHandler', () => {
  it('does not intercept back presses when no secondary route is active', () => {
    const addEventListener = jest.fn(
      (_eventName: 'hardwareBackPress', _handler: () => boolean | null | undefined) => ({
        remove: jest.fn(),
      }),
    );

    expect(
      subscribeSecondaryBackHandler(false, jest.fn(), {
        addEventListener,
      }),
    ).toBeUndefined();
    expect(addEventListener).not.toHaveBeenCalled();
  });

  it('closes the active secondary route and consumes the back press', () => {
    const closeSecondary = jest.fn();
    const remove = jest.fn();
    let registeredHandler: (() => boolean | null | undefined) | undefined;
    const addEventListener = jest.fn(
      (_eventName: 'hardwareBackPress', handler: () => boolean | null | undefined) => {
        registeredHandler = handler;
        return { remove };
      },
    );

    const subscription = subscribeSecondaryBackHandler(true, closeSecondary, {
      addEventListener,
    });
    expect(addEventListener).toHaveBeenCalledWith('hardwareBackPress', expect.any(Function));
    expect(registeredHandler?.()).toBe(true);
    expect(closeSecondary).toHaveBeenCalledTimes(1);

    subscription?.remove();
    expect(remove).toHaveBeenCalledTimes(1);
  });
});
