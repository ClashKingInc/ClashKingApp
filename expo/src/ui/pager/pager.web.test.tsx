import fs from 'node:fs';
import path from 'node:path';
import { createRef } from 'react';
import { Text, View } from 'react-native';
import { fireEvent, render } from '@testing-library/react-native';

import type { PagerViewHandle } from './types';

const { PagerView, pageIndexForOffset, pageOffsetForIndex } =
  jest.requireActual<typeof import('./pager')>('./pager.tsx');

test('web pager snaps touch/trackpad offsets to logical pages in both directions', () => {
  expect(pageIndexForOffset(320, 4, 320, false)).toBe(1);
  expect(pageOffsetForIndex(1, 4, 320, false)).toBe(320);
  expect(pageIndexForOffset(640, 4, 320, true)).toBe(1);
  expect(pageOffsetForIndex(1, 4, 320, true)).toBe(640);
});

test('web pager emits PageView-compatible selection and exposes imperative navigation', async () => {
  const onPageSelected = jest.fn();
  const pager = createRef<PagerViewHandle>();
  const screen = await render(
    <PagerView ref={pager} initialPage={0} onPageSelected={onPageSelected} testID="pager">
      <View>
        <Text>one</Text>
      </View>
      <View>
        <Text>two</Text>
      </View>
      <View>
        <Text>three</Text>
      </View>
    </PagerView>,
  );
  await fireEvent(screen.getByTestId('pager'), 'layout', {
    nativeEvent: { layout: { width: 300, height: 500, x: 0, y: 0 } },
  });
  await fireEvent(screen.getByTestId('pager-scroll'), 'momentumScrollEnd', {
    nativeEvent: { contentOffset: { x: 300, y: 0 } },
  });
  expect(onPageSelected).toHaveBeenCalledWith({ nativeEvent: { position: 1 } });
  expect(pager.current?.setPage).toEqual(expect.any(Function));
  expect(pager.current?.setPageWithoutAnimation).toEqual(expect.any(Function));
});

test('all shipping pager consumers import the platform abstraction', () => {
  const root = path.resolve(__dirname, '../..');
  for (const relative of [
    'shell/retained-pager.tsx',
    'features/upgrade-tracker/presentation/upgrade-tracker-screen.tsx',
  ]) {
    const source = fs.readFileSync(path.join(root, relative), 'utf8');
    expect(source).not.toContain("from 'react-native-pager-view'");
    expect(source).toMatch(/ui\/pager/);
  }
});
