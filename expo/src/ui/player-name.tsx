import type { ComponentProps } from 'react';
import { Platform } from 'react-native';
import { CKText } from './text';

/** Player names can contain scripts and decorative glyphs outside the brand
 * font. Let the system choose fallback fonts and their natural line metrics. */
export function PlayerName({ style, ...props }: ComponentProps<typeof CKText>) {
  return (
    <CKText
      adjustsFontSizeToFit
      minimumFontScale={0.7}
      {...props}
      style={[
        style,
        {
          fontFamily: Platform.OS === 'ios' ? 'System' : 'sans-serif',
          lineHeight: undefined,
          includeFontPadding: true,
          paddingVertical: 4,
          flexShrink: 1,
        },
      ]}
    />
  );
}
