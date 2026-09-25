import {
  applyNativeSecondaryRouteTransition,
  nativeSecondaryContent,
  nativeSecondaryRouteTransition,
  notifyNativeSecondaryRemoved,
  publishNativeSecondaryLayer,
  removeNativeSecondaryLayer,
  removeNativeSecondaryLayers,
  subscribeNativeSecondaryLayer,
} from './native-secondary-navigation';

test('dismisses the outer detail route when a settings link selects a primary tab', () => {
  const key = 'utility:settings::0';
  publishNativeSecondaryLayer(key, { content: 'Notifications', onRemove: jest.fn() });
  const navigation = { dismissTo: jest.fn(), push: jest.fn(), replace: jest.fn() };
  const transition = nativeSecondaryRouteTransition([key], []);
  expect(transition).toEqual({ type: 'dismiss', routeKeys: [], staleKeys: [key] });
  applyNativeSecondaryRouteTransition(transition, navigation);
  expect(navigation.dismissTo).toHaveBeenCalledWith('/');
  expect(navigation.push).not.toHaveBeenCalled();
  expect(navigation.replace).not.toHaveBeenCalled();
  // The outgoing screen must not turn black before the native route is removed.
  expect(nativeSecondaryContent(key)).toBe('Notifications');
  notifyNativeSecondaryRemoved(key);
  expect(nativeSecondaryContent(key)).toBeNull();
  expect(nativeSecondaryRouteTransition(transition.routeKeys, []).type).toBe('none');
});

test('dismissing several secondary routes targets the shell once, not the inner stack', () => {
  const navigation = { dismissTo: jest.fn(), push: jest.fn(), replace: jest.fn() };
  const transition = nativeSecondaryRouteTransition(['utility:settings', 'pushed:0:player'], []);
  applyNativeSecondaryRouteTransition(transition, navigation);
  expect(navigation.dismissTo).toHaveBeenCalledTimes(1);
  expect(navigation.dismissTo).toHaveBeenCalledWith('/');
  expect(transition.routeKeys).toEqual([]);
});

test('a completed native back needs no second dismissal', () => {
  const navigation = { dismissTo: jest.fn(), push: jest.fn(), replace: jest.fn() };
  applyNativeSecondaryRouteTransition(nativeSecondaryRouteTransition([], []), navigation);
  expect(navigation.dismissTo).not.toHaveBeenCalled();
});

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
