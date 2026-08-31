import { renderHook, waitFor } from '@testing-library/react-native';
import { AccessibilityInfo } from 'react-native';

import { useCKAccessibility } from './accessibility';

describe('useCKAccessibility', () => {
  test('defaults reduce transparency off when the platform does not implement it', async () => {
    const originalDescriptor = Object.getOwnPropertyDescriptor(
      AccessibilityInfo,
      'isReduceTransparencyEnabled',
    );
    Object.defineProperty(AccessibilityInfo, 'isReduceTransparencyEnabled', {
      configurable: true,
      value: undefined,
    });
    const addEventListener = jest.spyOn(AccessibilityInfo, 'addEventListener').mockReturnValue({
      remove: jest.fn(),
    } as unknown as ReturnType<typeof AccessibilityInfo.addEventListener>);
    jest.spyOn(AccessibilityInfo, 'isReduceMotionEnabled').mockResolvedValue(false);

    try {
      const { result } = await renderHook(() => useCKAccessibility());

      await waitFor(() => expect(result.current.reduceMotion).toBe(false));
      expect(result.current.reduceTransparency).toBe(false);
      expect(addEventListener).not.toHaveBeenCalledWith(
        'reduceTransparencyChanged',
        expect.any(Function),
      );
    } finally {
      addEventListener.mockRestore();
      jest.restoreAllMocks();
      if (originalDescriptor) {
        Object.defineProperty(AccessibilityInfo, 'isReduceTransparencyEnabled', originalDescriptor);
      } else {
        Reflect.deleteProperty(AccessibilityInfo, 'isReduceTransparencyEnabled');
      }
    }
  });
});
