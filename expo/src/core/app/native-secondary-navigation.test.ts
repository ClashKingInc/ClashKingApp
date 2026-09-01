import {
  nativeSecondaryContent,
  nativeSecondaryRouteTransition,
  notifyNativeSecondaryRemoved,
  publishNativeSecondaryLayer,
  removeNativeSecondaryLayer,
  removeNativeSecondaryLayers,
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

test('removes every app-owned native layer during root cleanup', () => {
  publishNativeSecondaryLayer('detail:settings', { content: 'Settings', onRemove: jest.fn() });
  publishNativeSecondaryLayer('detail:player', { content: 'Player', onRemove: jest.fn() });

  removeNativeSecondaryLayers(['detail:settings', 'detail:player', 'detail:settings']);

  expect(nativeSecondaryContent('detail:settings')).toBeNull();
  expect(nativeSecondaryContent('detail:player')).toBeNull();
});

test('pushes appended native routes and replaces mismatches at the same depth', () => {
  expect(nativeSecondaryRouteTransition([], ['detail:settings'])).toEqual({
    type: 'push',
    key: 'detail:settings',
    routeKeys: ['detail:settings'],
    staleKeys: [],
  });
  expect(nativeSecondaryRouteTransition(['detail:settings'], ['detail:upgrade-tracker'])).toEqual({
    type: 'replace',
    key: 'detail:upgrade-tracker',
    routeKeys: ['detail:upgrade-tracker'],
    staleKeys: ['detail:settings'],
  });
  expect(
    nativeSecondaryRouteTransition(
      ['detail:settings', 'detail:player'],
      ['detail:settings', 'detail:clan'],
    ),
  ).toEqual({
    type: 'replace',
    key: 'detail:clan',
    routeKeys: ['detail:settings', 'detail:clan'],
    staleKeys: ['detail:player'],
  });
});
