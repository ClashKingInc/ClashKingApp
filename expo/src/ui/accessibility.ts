import { useEffect, useState } from 'react';
import { AccessibilityInfo, Platform } from 'react-native';

import { ckBreakpoints } from './tokens';
import type { CKPlatform } from './policies';

type AccessibilityInfoExtended = typeof AccessibilityInfo & {
  isHighTextContrastEnabled?: () => Promise<boolean>;
};

const extendedAccessibilityInfo = AccessibilityInfo as AccessibilityInfoExtended;

export function currentPlatform(): CKPlatform {
  if (Platform.OS === 'ios' || Platform.OS === 'android' || Platform.OS === 'web') {
    return Platform.OS;
  }
  return 'other';
}

export function isDesktopWeb(width: number): boolean {
  return currentPlatform() === 'web' && width >= ckBreakpoints.desktop;
}

export type CKAccessibilityPreferences = {
  reduceMotion: boolean;
  reduceTransparency: boolean;
  highContrast: boolean;
};

const initialPreferences: CKAccessibilityPreferences = {
  reduceMotion: false,
  reduceTransparency: false,
  highContrast: false,
};

export function useCKAccessibility(): CKAccessibilityPreferences {
  const [preferences, setPreferences] = useState(initialPreferences);

  useEffect(() => {
    let active = true;
    void Promise.all([
      AccessibilityInfo.isReduceMotionEnabled(),
      AccessibilityInfo.isReduceTransparencyEnabled(),
      extendedAccessibilityInfo.isHighTextContrastEnabled?.() ?? Promise.resolve(false),
    ]).then(([reduceMotion, reduceTransparency, highContrast]) => {
      if (active) setPreferences({ reduceMotion, reduceTransparency, highContrast });
    });

    const motion = AccessibilityInfo.addEventListener('reduceMotionChanged', (reduceMotion) => {
      setPreferences((value) => ({ ...value, reduceMotion }));
    });
    const transparency = AccessibilityInfo.addEventListener(
      'reduceTransparencyChanged',
      (reduceTransparency) => {
        setPreferences((value) => ({ ...value, reduceTransparency }));
      },
    );

    return () => {
      active = false;
      motion.remove();
      transparency.remove();
    };
  }, []);

  return preferences;
}
