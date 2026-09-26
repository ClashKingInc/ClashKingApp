import { render, cleanup } from '@testing-library/react-native';
import { Animated } from 'react-native';
import { StartupBrand } from './startup-brand';

afterEach(async () => {
  await cleanup();
  jest.restoreAllMocks();
});
const props = { foreground: '#fff', background: '#0B0B0C', label: 'ClashKing', width: 300 };

test('reduced motion displays the final brand without launching an animation', async () => {
  const timing = jest.spyOn(Animated, 'timing');
  const screen = await render(<StartupBrand {...props} reduceMotion />);
  expect(screen.getByLabelText('ClashKing')).toBeTruthy();
  expect(timing).not.toHaveBeenCalled();
});

test('readiness can unmount startup immediately without waiting for the animation', async () => {
  const start = jest.fn();
  const stop = jest.fn();
  jest.spyOn(Animated, 'timing').mockReturnValue({ start, stop, reset: jest.fn() });
  const screen = await render(<StartupBrand {...props} reduceMotion={false} />);
  expect(start).toHaveBeenCalledTimes(1);
  await screen.unmount();
  expect(stop).toHaveBeenCalledTimes(1);
});
