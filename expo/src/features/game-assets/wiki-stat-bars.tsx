import { wikiItemHasStat } from './wiki-stat-visibility';
import { View } from 'react-native';
import { CKText, MobileWebImage, InfoTooltip, colorWithAlpha, useCKTheme } from '../../ui';
import { useI18n } from '../../i18n';
import { ImageAssets } from '../../core/assets/image-assets';
import { isRecord } from '../../core/game-data/game-data-state';
import { UpgradeVillage, type UpgradeTrackerItem } from '../upgrade-tracker/models';

/** Bars compare levels of the same item. One marker shows the next Town Hall
 * gate after the selected level; it must not mark every lab/Hero Hall change. */
export function WikiStatBars({ item, selected }: { item: UpgradeTrackerItem; selected: number }) {
  const theme = useCKTheme(),
    { t } = useI18n();
  if (isRecord(item.meta?.squad)) return null;
  const levels = Array.isArray(item.meta?.levels)
    ? item.meta.levels.filter(isRecord).sort((a, b) => Number(a.level) - Number(b.level))
    : [];
  const current = levels.find((row) => row.level === selected);
  if (!current) return null;
  const currentHall = Math.max(
    0,
    ...levels
      .filter((row) => Number(row.level) <= selected)
      .map((row) => Number(row.required_townhall) || 0),
  );
  const builder = item.village === UpgradeVillage.builderBase;
  const hall = item.name === 'Town Hall' || item.name === 'Builder Hall';
  const nextGate = hall
    ? undefined
    : levels.find(
        (row) => Number(row.level) > selected && Number(row.required_townhall) > currentHall,
      );
  return (
    <View style={{ gap: 14 }}>
      {[
        {
          key: 'hitpoints',
          label: t('gameItemHitpoints'),
          icon: ImageAssets.hitpoints,
          fill: '#70C791',
        },
        { key: 'dps', label: t('gameItemDps'), icon: ImageAssets.sword, fill: '#E97879' },
      ].flatMap(({ key, label, icon, fill }) => {
        if (!wikiItemHasStat(levels, key, item.meta)) return [];
        if (typeof current[key] !== 'number') return [];
        const max = Math.max(...levels.map((row) => Number(row[key]) || 0));
        if (max <= 0) return [];
        const gateFraction =
          nextGate && typeof nextGate[key] === 'number' ? Number(nextGate[key]) / max : null;
        return [
          <View key={key} style={{ gap: 7 }}>
            <View style={{ flexDirection: 'row', gap: 8, alignItems: 'center' }}>
              <MobileWebImage
                imageUrl={icon}
                contentFit="contain"
                style={{ width: 20, height: 20 }}
              />
              <CKText muted style={{ flex: 1 }}>
                {label}
              </CKText>
              <CKText>
                {String(current[key])} / {max}
              </CKText>
            </View>
            <View style={{ height: 26, justifyContent: 'center' }}>
              <View
                style={{ height: 7, borderRadius: 4, backgroundColor: colorWithAlpha(fill, 0.22) }}
              >
                <View
                  style={{
                    width: `${(Number(current[key]) / max) * 100}%`,
                    height: 7,
                    borderRadius: 4,
                    backgroundColor: fill,
                  }}
                />
              </View>
              {gateFraction !== null && nextGate ? (
                <View
                  style={{
                    position: 'absolute',
                    left: `${Math.min(0.98, gateFraction) * 100}%`,
                    marginLeft: -16,
                    top: -3,
                  }}
                >
                  <InfoTooltip
                    label={t(builder ? 'gameBuilderHall' : 'wikiNextTownHall')}
                    message={t(builder ? 'wikiBuilderHallGate' : 'wikiTownHallGate', {
                      townhall: Number(nextGate.required_townhall),
                      level: Number(nextGate.level),
                    })}
                    triggerContent={
                      <View style={{ width: 2, height: 14, backgroundColor: theme.onSurface }} />
                    }
                    triggerStyle={{ width: 32, height: 32 }}
                  />
                </View>
              ) : null}
            </View>
          </View>,
        ];
      })}
    </View>
  );
}
