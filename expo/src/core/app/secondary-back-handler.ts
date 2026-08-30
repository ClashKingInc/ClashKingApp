import { BackHandler } from 'react-native';

type BackHandlerSubscription = ReturnType<typeof BackHandler.addEventListener>;

type BackHandlerLike = {
  addEventListener(
    eventName: 'hardwareBackPress',
    handler: () => boolean | null | undefined,
  ): BackHandlerSubscription;
};

export function subscribeSecondaryBackHandler(
  active: boolean,
  closeSecondary: () => void,
  backHandler: BackHandlerLike = BackHandler,
): BackHandlerSubscription | undefined {
  if (!active) return undefined;

  return backHandler.addEventListener('hardwareBackPress', () => {
    closeSecondary();
    return true;
  });
}
