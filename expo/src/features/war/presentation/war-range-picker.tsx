import { useI18n } from '../../../i18n';
import { SelectionPicker } from '../../../ui';
import { WAR_HISTORY_RANGES, type WarHistoryRange } from '../models/war-history-range';

export function WarRangePicker({
  value,
  onChange,
  includeLifetime = false,
}: {
  includeLifetime?: boolean;
  value: WarHistoryRange;
  onChange: (range: WarHistoryRange) => void;
}) {
  const { t } = useI18n();
  const choices = includeLifetime
    ? [...WAR_HISTORY_RANGES, 'lifetime' as const]
    : WAR_HISTORY_RANGES;
  return (
    <SelectionPicker
      accessibilityLabel={t('filtersDateRange')}
      title={t('filtersDateRange')}
      selectedKey={value}
      onSelect={(key) => {
        if (choices.includes(key as WarHistoryRange)) onChange(key as WarHistoryRange);
      }}
      options={choices.map((key) => ({
        key,
        label:
          key === 'lifetime'
            ? t('playerWarLifetime')
            : t(key.startsWith('days:') ? 'warStatsLastXDays' : 'warFiltersLastXwars', {
                number: Number(key.split(':')[1]),
              }),
      }))}
    />
  );
}
