import { Animated, StyleSheet, type TextProps } from 'react-native';

import { ckTypography, type CKTextRole } from './tokens';
import { useCKTheme } from './theme';
import { useSkeletonAppearance } from './skeleton-content';
import { useTabletTypography } from './typography-context';

const tabletType = {
  titleLarge: { fontSize: 30, lineHeight: 36 },
  titleMedium: { fontSize: 25, lineHeight: 31 },
  titleSmall: { fontSize: 23, lineHeight: 29 },
  bodyLarge: { fontSize: 20, lineHeight: 27 },
  bodyMedium: { fontSize: 18, lineHeight: 25 },
  bodySmall: { fontSize: 15, lineHeight: 21 },
  labelLarge: { fontSize: 16, lineHeight: 22 },
  labelMedium: { fontSize: 13, lineHeight: 18 },
  labelSmall: { fontSize: 11, lineHeight: 16 },
  heroMetric: { fontSize: 43, lineHeight: 47 },
  screenTitle: { fontSize: 30, lineHeight: 36 },
  sectionTitle: { fontSize: 25, lineHeight: 31 },
  rowTitle: { fontSize: 18, lineHeight: 24 },
  body: { fontSize: 18, lineHeight: 25 },
  metadata: { fontSize: 15, lineHeight: 21 },
  compactLabel: { fontSize: 11, lineHeight: 15 },
} satisfies Record<CKTextRole, { fontSize: number; lineHeight: number }>;

export type CKTextProps = Omit<TextProps, 'role'> & {
  role?: CKTextRole;
  muted?: boolean;
  /** Keep known labels visible inside a loading card when explicitly false. */
  skeleton?: boolean;
};

export function CKText({ role = 'body', muted = false, skeleton, style, ...props }: CKTextProps) {
  const theme = useCKTheme();
  const tablet = useTabletTypography();
  const explicitSize = StyleSheet.flatten(style)?.fontSize !== undefined;
  const appearance = useSkeletonAppearance();
  const loading = appearance.loading && skeleton !== false;
  return (
    <Animated.Text
      // A fresh native text node prevents a skeleton's animated opacity or
      // transparent color from persisting after real content becomes ready.
      key={loading ? 'skeleton' : 'content'}
      allowFontScaling
      style={[
        ckTypography[role],
        // Explicit page typography remains authoritative. This lifts only the
        // shared defaults; the app's phone/Android type scale stays untouched.
        tablet && !explicitSize && tabletType[role],
        // Clear native animated placeholder opacity when loading finishes;
        // caller styles still override this default for intentional dimming.
        { color: muted ? theme.onSurfaceVariant : theme.onSurface, opacity: 1 },
        style,
        loading && {
          color: 'transparent',
          backgroundColor: theme.surfaceContainerHighest,
          borderRadius: 4,
          textShadowColor: 'transparent',
          opacity: appearance.opacity,
        },
      ]}
      {...props}
    />
  );
}
