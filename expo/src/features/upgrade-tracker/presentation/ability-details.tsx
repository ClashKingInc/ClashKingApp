import type { ReactNode } from 'react';
import { View } from 'react-native';
import { localizedNameForItem } from '../../../core/game-data/game-data-localization';
import { isRecord, type JsonRecord } from '../../../core/game-data/game-data-state';
import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText } from '../../../ui';

/** Render the exported fields, not a small whitelist: new mechanics must remain visible. */
export function AbilityDetails({
  ability,
  level,
  maximum,
  renderStat,
}: {
  ability: JsonRecord;
  level: number;
  maximum: number;
  renderStat: (row: { key: string; label: string; value: string }) => ReactNode;
}) {
  const { locale } = useI18n();
  const number = new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 3 });
  const levels = Array.isArray(ability.levels) ? ability.levels.filter(isRecord) : [];
  const current = levels.find((row) => row.level === level);
  const next = level < maximum ? levels.find((row) => row.level === level + 1) : undefined;
  const first = levels.reduce((min, row) => Math.min(min, Number(row.level)), Infinity);
  const keys = [...new Set([...Object.keys(current ?? {}), ...Object.keys(next ?? {})])].filter(
    (key) => key !== 'level',
  );
  return (
    <View style={{ gap: 8 }}>
      <CKText role="sectionTitle">
        {localizedNameForItem(ability) || String(ability.name ?? '')}
      </CKText>
      {!current && !next && Number.isFinite(first) && level < first ? (
        <CKText muted>Unlocks at level {first}</CKText>
      ) : null}
      {keys.map((key) => {
        const value = current?.[key],
          following = next?.[key];
        const before = formatAbilityValue(key, value, number);
        const after = formatAbilityValue(key, following, number);
        const changed = next && following != null && before !== after;
        // A summoned unit keeps its identity between levels. Repeat only the
        // level, not its full name, so this comparison fits a mobile stat row.
        const sameUnit =
          key === 'spawned_unit' &&
          isRecord(value) &&
          isRecord(following) &&
          value.name === following.name &&
          value.level != null &&
          following.level != null;
        const delta =
          changed && typeof value === 'number' && typeof following === 'number'
            ? scaledAbilityValue(key, following) - scaledAbilityValue(key, value)
            : null;
        return renderStat({
          key,
          label: abilityFieldLabel(key),
          value: `${before}${changed ? ` → ${sameUnit ? number.format(Number(following.level)) : after}` : ''}${delta != null && delta !== 0 ? ` (${delta > 0 ? '+' : ''}${number.format(delta)}${isPercent(key) ? '%' : ''})` : ''}`,
        });
      })}
    </View>
  );
}

function isPercent(key: string) {
  return key.endsWith('_percent') || key.includes('_percent_');
}
function scaledAbilityValue(key: string, value: number) {
  // abilities.json keeps spatial values in hundredths of a tile, and attack
  // periods in milliseconds. Other durations are already exported in seconds.
  if (key.endsWith('attack_speed')) return value / 1000;
  if (
    key.endsWith('_range') ||
    key.endsWith('_radius') ||
    key.endsWith('movement_speed') ||
    key.endsWith('movement_speed_increase')
  )
    return value / 100;
  return value;
}
export function formatAbilityValue(key: string, value: unknown, number: Intl.NumberFormat): string {
  if (value == null) return '—';
  if (typeof value === 'boolean') return value ? 'Yes' : 'No';
  if (typeof value === 'number') {
    const suffix = isPercent(key)
      ? '%'
      : key.endsWith('attack_speed') ||
          /(?:duration|cooldown|interval|lifetime|stage_\d+_after)$/.test(key)
        ? 's'
        : /(?:_range|_radius)$/.test(key)
          ? ' tiles'
          : /(?:movement_speed|movement_speed_increase)$/.test(key)
            ? ' tiles/s'
            : key.endsWith('cone_angle')
              ? '°'
              : '';
    return `${number.format(scaledAbilityValue(key, value))}${suffix}`;
  }
  if (isRecord(value)) {
    if (value.name)
      return `${localizedNameForItem(value) || String(value.name)}${value.level != null ? ` · Level ${number.format(Number(value.level))}` : value.level_from ? ` · ${String(value.level_from)} level` : ''}`;
    return Object.entries(value)
      .filter(([field]) => field !== '_id')
      .map(
        ([field, entry]) =>
          `${abilityFieldLabel(field)}: ${formatAbilityValue(field, entry, number)}`,
      )
      .join(', ');
  }
  if (Array.isArray(value))
    return value.map((entry) => formatAbilityValue(key, entry, number)).join(', ');
  return String(value);
}
export function abilityFieldLabel(key: string): string {
  const labels: Record<string, string> = {
    damage_increase_percent: 'Damage increase',
    attack_speed_increase_percent: 'Attack speed increase',
    damage_reduction_percent: 'Damage reduction',
    health_increase_percent: 'Health increase',
    damage_percent_target_health: 'Damage (% of target HP)',
    target_damage_multiplier_percent: 'Target damage multiplier',
    damage_loss_per_chain_percent: 'Damage lost per chain',
    spawned_unit: 'Summoned unit',
    units_spawned: 'Units summoned',
  };
  if (labels[key]) return labels[key];
  const label = key
    .replaceAll('_', ' ')
    .replace(/\bdps\b/g, 'DPS')
    .replace(/\bhitpoints\b/g, 'HP');
  return label.charAt(0).toUpperCase() + label.slice(1);
}
