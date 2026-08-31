import { Text, type TextProps } from 'react-native';

import { ckTypography, type CKTextRole } from './tokens';
import { useCKTheme } from './theme';

export type CKTextProps = Omit<TextProps, 'role'> & {
  role?: CKTextRole;
  muted?: boolean;
};

export function CKText({ role = 'body', muted = false, style, ...props }: CKTextProps) {
  const theme = useCKTheme();
  return (
    <Text
      allowFontScaling
      style={[
        ckTypography[role],
        { color: muted ? theme.onSurfaceVariant : theme.onSurface },
        style,
      ]}
      {...props}
    />
  );
}
