import { Animated, type TextProps } from 'react-native';

import { ckTypography, type CKTextRole } from './tokens';
import { useCKTheme } from './theme';
import { useSkeletonAppearance } from './skeleton-content';

export type CKTextProps = Omit<TextProps, 'role'> & {
  role?: CKTextRole;
  muted?: boolean;
  /** Keep known labels visible inside a loading card when explicitly false. */
  skeleton?: boolean;
};

export function CKText({ role = 'body', muted = false, skeleton, style, ...props }: CKTextProps) {
  const theme = useCKTheme();
  const appearance = useSkeletonAppearance();
  const loading = appearance.loading && skeleton !== false;
  return (
    <Animated.Text
      allowFontScaling
      style={[
        ckTypography[role],
        { color: muted ? theme.onSurfaceVariant : theme.onSurface },
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
