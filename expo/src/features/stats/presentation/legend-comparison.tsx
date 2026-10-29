import { View, StyleSheet } from 'react-native';
import { CKText, MobileWebImage } from '../../../ui';

/** A single comparison, rather than independent metric cards competing for attention. */
export function LegendComparison({
  title,
  sides,
}: {
  title: string;
  sides: readonly {
    key: string;
    label: string;
    value: string;
    color: string;
    image: string;
    detail?: string;
  }[];
}) {
  return (
    <View style={styles.root}>
      <CKText role="titleMedium">{title}</CKText>
      <View style={styles.sides}>
        {sides.map((side) => (
          <View
            key={side.key}
            style={styles.side}
            accessible
            accessibilityLabel={`${side.label}, ${side.value}${side.detail ? `, ${side.detail}` : ''}`}
          >
            <View style={styles.label}>
              <MobileWebImage imageUrl={side.image} contentFit="contain" style={styles.icon} />
              <CKText role="bodySmall" muted>
                {side.label}
              </CKText>
            </View>
            <CKText
              role="heroMetric"
              numberOfLines={1}
              adjustsFontSizeToFit
              style={[styles.value, { color: side.color }]}
            >
              {side.value}
            </CKText>
            {side.detail ? (
              <CKText role="bodySmall" muted style={styles.detail}>
                {side.detail}
              </CKText>
            ) : null}
          </View>
        ))}
      </View>
    </View>
  );
}
const styles = StyleSheet.create({
  root: { gap: 18 },
  sides: { flexDirection: 'row', gap: 24 },
  side: { flex: 1, minWidth: 0, gap: 5 },
  label: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  icon: { width: 20, height: 20 },
  value: { fontSize: 38, lineHeight: 46, fontWeight: '700', fontVariant: ['tabular-nums'] },
  detail: { lineHeight: 18 },
});
