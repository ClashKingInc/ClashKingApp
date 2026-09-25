import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';

import { toIntlLocale, useI18n } from '../i18n';
import { MobileWebImage } from './mobile-web-image';
import { PillSurface } from './surfaces';
import { CKText } from './text';

export function ProfileStatChip({
  label,
  value,
  icon,
  iconElement,
}: {
  label: string;
  value: number | string;
  icon?: string;
  iconElement?: ReactNode;
}) {
  const { locale } = useI18n();
  return (
    <PillSurface style={styles.quickStat} accessible accessibilityLabel={`${label}: ${value}`}>
      {icon ? <MobileWebImage imageUrl={icon} style={styles.statIcon} /> : iconElement}
      <View style={styles.value}>
        <CKText role="labelLarge">
          {typeof value === 'number'
            ? new Intl.NumberFormat(toIntlLocale(locale)).format(value)
            : value}
        </CKText>
      </View>
    </PillSurface>
  );
}

const styles = StyleSheet.create({
  quickStat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 6,
    maxWidth: '100%',
  },
  value: { flexShrink: 1, minWidth: 0 },
  statIcon: { width: 19, height: 19, resizeMode: 'contain' },
});
