import { StyleSheet, View } from 'react-native';
import { ImageAssets } from '../../core/assets/image-assets';
import { isRecord, type JsonRecord } from '../../core/game-data/game-data-state';
import { toIntlLocale, useI18n } from '../../i18n';
import { CKText, MobileWebImage, colorWithAlpha, useCKTheme } from '../../ui';
import { wikiHasResearchUpgrades } from './wiki-stat-visibility';

/** One cost presentation for all upgradeable Wiki pages. Costs describe the
 * selected level, just like the table; never infer free from missing data. */
export function WikiUpgradeCost({
  meta,
  level,
}: {
  meta: JsonRecord;
  level: JsonRecord | null | undefined;
}) {
  const theme = useCKTheme();
  const { t, locale } = useI18n();
  if (!level || !wikiHasResearchUpgrades(meta)) return null;
  const format = new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 0 });
  const raw = level.build_cost ?? level.upgrade_cost;
  const maximum = Array.isArray(meta.levels)
    ? Math.max(0, ...meta.levels.filter(isRecord).map((row) => Number(row.level) || 0))
    : 0;
  const positive = (value: unknown) =>
    typeof value === 'number' && Number.isFinite(value) && value > 0;
  const hasCost = isRecord(raw) ? Object.values(raw).some(positive) : positive(raw);
  const hasTime = positive(level.build_time) || positive(level.upgrade_time);
  // Final-level sentinels use zero/missing cost and time. They are not a free
  // upgrade and must not occupy a full-width card. Real final-level costs stay.
  if (maximum > 0 && Number(level.level) >= maximum && !hasCost && !hasTime) return null;
  const normalize = (name: string) =>
    name
      .trim()
      .toLowerCase()
      .replace(/[\s-]+/g, '_');
  const costs: [string, unknown][] = isRecord(raw)
    ? [
        ...(['shiny_ore', 'glowy_ore', 'starry_ore'] as const).map((ore): [string, unknown] => [
          ore,
          raw[ore],
        ]),
        ...Object.entries(raw).filter(
          ([key]) => !['shiny_ore', 'glowy_ore', 'starry_ore'].includes(key),
        ),
      ]
    : [[normalize(String(meta.upgrade_resource ?? meta.build_resource ?? '')), raw]];
  return (
    <View
      style={[
        styles.card,
        { backgroundColor: theme.card, borderColor: colorWithAlpha(theme.outlineVariant, 0.25) },
      ]}
    >
      <CKText muted style={styles.label}>
        {t('gameItemUpgradeCost')}
      </CKText>
      <View style={styles.resources}>
        {costs.map(([resource, amount]) => (
          <View key={resource} style={styles.resource}>
            {resource ? (
              <MobileWebImage
                imageUrl={`${ImageAssets.baseUrl}/resources/${resource}.webp`}
                contentFit="contain"
                style={styles.icon}
              />
            ) : null}
            <CKText style={styles.amount}>
              {typeof amount === 'number' && Number.isFinite(amount) ? format.format(amount) : '—'}
            </CKText>
          </View>
        ))}
      </View>
    </View>
  );
}
const styles = StyleSheet.create({
  card: {
    width: '100%',
    padding: 14,
    borderRadius: 10,
    borderWidth: StyleSheet.hairlineWidth,
    gap: 10,
  },
  label: { fontSize: 12, lineHeight: 17 },
  resources: { flexDirection: 'row', flexWrap: 'wrap', columnGap: 24, rowGap: 10 },
  resource: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  icon: { width: 25, height: 28 },
  amount: { fontSize: 19, lineHeight: 26, fontVariant: ['tabular-nums'] },
});
