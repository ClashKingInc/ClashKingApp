import { act, render, renderHook } from '@testing-library/react-native';

import { PullRefreshHint, usePullRefreshHint } from './pull-refresh-hint';

jest.mock('./theme', () => ({
  useCKTheme: () => ({ background: '#000', onSurfaceVariant: '#aaa' }),
}));

describe('pull refresh hint', () => {
  it('only exposes the gap during an initial active pull, never during rebound', async () => {
    const { result } = await renderHook(() => usePullRefreshHint());
    expect(result.current.distance).toBe(0);
    await act(() => result.current.onScrollOffsetChange(-40));
    expect(result.current.distance).toBe(0);
    await act(() => result.current.onScrollBeginDrag());
    await act(() => result.current.onScrollOffsetChange(100));
    expect(result.current.distance).toBe(0);
    await act(() => result.current.onScrollOffsetChange(-10));
    expect(result.current.distance).toBe(0);
    await act(() => result.current.onScrollOffsetChange(-40));
    expect(result.current.distance).toBe(40);
    await act(() => result.current.onScrollOffsetChange(-70));
    expect(result.current.distance).toBe(0);
    await act(() => result.current.onScrollOffsetChange(-40));
    await act(() => result.current.onScrollEndDrag());
    expect(result.current.distance).toBe(0);
    await act(() => result.current.onScrollOffsetChange(-40));
    expect(result.current.distance).toBe(0);
  });

  it('keeps the label inside the overscroll gap and hides it during refresh', async () => {
    const screen = await render(
      <PullRefreshHint distance={40} refreshing={false} label="Last refresh" />,
    );
    expect(screen.getByText('Last refresh')).toBeTruthy();
    expect(screen.getByTestId('pull-refresh-hint').props.style).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ position: 'absolute', top: 0, overflow: 'hidden' }),
        expect.objectContaining({ height: 40 }),
      ]),
    );
    await screen.rerender(<PullRefreshHint distance={40} refreshing label="Last refresh" />);
    expect(screen.queryByText('Last refresh')).toBeNull();
    await screen.rerender(<PullRefreshHint distance={0} refreshing={false} label="Last refresh" />);
    expect(screen.queryByText('Last refresh')).toBeNull();
  });
});
