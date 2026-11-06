import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import { MobileWebImage, SelectionPicker } from '../../../ui';
import { StatsLegendCohort } from '../models';

export function LeagueStatsPicker() {
  const { t } = useI18n();
  return (
    <SelectionPicker
      accessibilityLabel={t('gameLeague')}
      fillWidth
      title={t('gameLeague')}
      options={[{
        key: StatsLegendCohort.legend,
        label: t('statsLegendLeagueOne'),
        icon: <MobileWebImage imageUrl={ImageAssets.legendLeagueOne} style={{ width: 28, height: 28 }} contentFit="contain" />,
      }]}
      selectedKey={StatsLegendCohort.legend}
      onSelect={() => {}}
    />
  );
}
