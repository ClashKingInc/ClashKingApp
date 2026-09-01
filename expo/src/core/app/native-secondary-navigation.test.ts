import {
  nativeSecondaryContent,
  notifyNativeSecondaryRemoved,
  publishNativeSecondaryLayer,
  removeNativeSecondaryLayer,
  subscribeNativeSecondaryLayer,
} from './native-secondary-navigation';

test('publishes native route content and removes the matching app-owned layer on pop', () => {
  const onRemove = jest.fn();
  const listener = jest.fn();
  const unsubscribe = subscribeNativeSecondaryLayer('detail:one', listener);

  publishNativeSecondaryLayer('detail:one', { content: 'First', onRemove });
  expect(nativeSecondaryContent('detail:one')).toBe('First');
  expect(listener).toHaveBeenCalledTimes(1);

  notifyNativeSecondaryRemoved('detail:one');
  expect(onRemove).toHaveBeenCalledTimes(1);
  expect(nativeSecondaryContent('detail:one')).toBeNull();
  expect(listener).toHaveBeenCalledTimes(2);

  unsubscribe();
  removeNativeSecondaryLayer('detail:one');
});
