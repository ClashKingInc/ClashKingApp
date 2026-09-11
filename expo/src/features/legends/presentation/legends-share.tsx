import { StyleSheet, View } from 'react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import {
  CKText,
  HorizontalImageShareModal,
  MobileWebImage,
  colorWithAlpha,
  horizontalImageFilename,
} from '../../../ui';
import type { PlayerLegendLeagueData } from '../../player/models';
import { parseArmyCounts, PlayerBattlelogArmyCatalog } from '../../player/models/player-battlelog';

export interface LegendsShareSummary {
  readonly currentRank: number | null;
  readonly historicalRank: number | null;
  readonly favoriteArmy: string | null;
  readonly favoriteArmyUses: number;
  readonly battleChanges: readonly { readonly key: string; readonly change: number }[];
  readonly graph: readonly { readonly label: string; readonly trophies: number }[];
}

export function legendsShareSummary(data: PlayerLegendLeagueData): LegendsShareSummary {
  const armyUses = new Map<string, number>();
  for (const battle of data.currentDay?.attacks ?? []) {
    if (battle.shareCode) armyUses.set(battle.shareCode, (armyUses.get(battle.shareCode) ?? 0) + 1);
  }
  const favorite = [...armyUses.entries()].sort(
    ([left, leftUses], [right, rightUses]) => rightUses - leftUses || left.localeCompare(right),
  )[0];
  const dailyChanges = [...data.recentDays]
    .sort((left, right) => left.day.localeCompare(right.day))
    .map((day) => ({ key: day.day, change: day.trophyChange }));
  const selectedClosingTrophies = data.historicalRank?.trophies ?? data.trophies;
  let running =
    selectedClosingTrophies - dailyChanges.reduce((sum, battle) => sum + battle.change, 0);
  return {
    currentRank: data.currentRank?.globalRank ?? null,
    historicalRank: data.historicalRank?.globalRank ?? null,
    favoriteArmy: favorite?.[0] ?? null,
    favoriteArmyUses: favorite?.[1] ?? 0,
    battleChanges: dailyChanges,
    graph: dailyChanges.map((day) => {
      running += day.change;
      return { label: day.key.slice(5), trophies: running };
    }),
  };
}

export function LegendsShareModal({
  data,
  visible,
  onClose,
}: {
  readonly data: PlayerLegendLeagueData;
  readonly visible: boolean;
  readonly onClose: () => void;
}) {
  const { t } = useI18n();
  const summary = legendsShareSummary(data);
  const maximum = Math.max(1, ...summary.graph.map((point) => point.trophies));
  const favoriteItems = summary.favoriteArmy
    ? Object.entries(parseArmyCounts(summary.favoriteArmy)).slice(0, 7)
    : [];
  return (
    <HorizontalImageShareModal
      artworkUrls={[
        ImageAssets.legendBlazon,
        ...favoriteItems.map(([code]) => PlayerBattlelogArmyCatalog.resolve(code).imageUrl),
      ]}
      fileName={legendsImageFileName(data.playerName)}
      message={`${data.playerName} in Legend League on ClashKing`}
      onClose={onClose}
      title={t('generalExport')}
      visible={visible}
    >
      <View style={styles.graphic}>
        <View style={styles.heading}>
          <View>
            <CKText role="screenTitle" style={styles.white}>
              {data.playerName}
            </CKText>
            <CKText role="titleMedium" style={styles.soft}>
              {t('legendsTitle')}
            </CKText>
          </View>
          <MobileWebImage imageUrl={ImageAssets.legendBlazon} style={styles.logo} />
        </View>
        <View style={styles.metrics}>
          <Metric label={t('rankedLeagueTrophies')} value={data.trophies.toLocaleString()} />
          <Metric label={t('legendsBestTrophies')} value={data.bestTrophies.toLocaleString()} />
          <Metric
            label={t('legendsGlobalRankTitle')}
            value={summary.currentRank ? `#${summary.currentRank}` : '—'}
          />
          <Metric
            label={data.selectedDay}
            value={summary.historicalRank ? `#${summary.historicalRank}` : '—'}
          />
        </View>
        <View style={styles.lower}>
          <View style={styles.panel}>
            <CKText role="titleMedium" style={styles.white}>
              {data.currentDay?.day ?? t('generalNoDataAvailable')}
            </CKText>
            <View style={styles.changeGrid}>
              {summary.battleChanges.map((battle) => (
                <View
                  key={battle.key}
                  style={[
                    styles.changeCell,
                    {
                      backgroundColor: colorWithAlpha(
                        battle.change >= 0 ? '#2DD4BF' : '#FB7185',
                        0.72,
                      ),
                    },
                  ]}
                >
                  <CKText role="labelSmall" style={styles.white}>
                    {battle.change >= 0 ? '+' : ''}
                    {battle.change}
                  </CKText>
                </View>
              ))}
            </View>
            <View style={styles.armyRow}>
              <CKText role="labelSmall" style={styles.soft}>
                {t('playerBattlelogPopularTroops')} · ×{summary.favoriteArmyUses}
              </CKText>
              {favoriteItems.map(([code, count]) => {
                const item = PlayerBattlelogArmyCatalog.resolve(code);
                return (
                  <View key={code} style={styles.armyItem}>
                    <MobileWebImage imageUrl={item.imageUrl} style={styles.armyImage} />
                    <CKText role="labelSmall" style={styles.white}>
                      ×{count}
                    </CKText>
                  </View>
                );
              })}
            </View>
          </View>
          <View style={styles.panel}>
            <CKText role="titleMedium" style={styles.white}>
              {t('generalHistory')}
            </CKText>
            <View style={styles.graph}>
              {summary.graph.map((point, index) => (
                <View key={`${point.label}-${index}`} style={styles.graphColumn}>
                  <CKText role="labelSmall" style={styles.soft}>
                    {point.trophies}
                  </CKText>
                  <View style={styles.barTrack}>
                    <View
                      style={[
                        styles.bar,
                        { height: `${Math.max(8, (point.trophies / maximum) * 100)}%` },
                      ]}
                    />
                  </View>
                  <CKText role="labelSmall" style={styles.soft}>
                    {point.label}
                  </CKText>
                </View>
              ))}
            </View>
          </View>
        </View>
      </View>
    </HorizontalImageShareModal>
  );
}

export function legendsImageFileName(playerName: string, now = new Date()) {
  return horizontalImageFilename('legends', playerName, '', now);
}

function Metric({ label, value }: { readonly label: string; readonly value: string }) {
  return (
    <View style={styles.metric}>
      <CKText role="titleLarge" style={styles.white}>
        {value}
      </CKText>
      <CKText role="labelSmall" style={styles.soft} numberOfLines={1}>
        {label}
      </CKText>
    </View>
  );
}

const styles = StyleSheet.create({
  graphic: { flex: 1, padding: 28, gap: 18, backgroundColor: '#0B1220' },
  heading: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  white: { color: '#FFF' },
  soft: { color: '#B8C4D8' },
  logo: { width: 68, height: 68 },
  metrics: { flexDirection: 'row', gap: 10 },
  metric: { flex: 1, padding: 12, borderRadius: 12, backgroundColor: '#162033' },
  lower: { flex: 1, flexDirection: 'row', gap: 14 },
  panel: { flex: 1, padding: 14, borderRadius: 14, backgroundColor: '#121C2E', gap: 10 },
  changeGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  changeCell: {
    width: 42,
    height: 34,
    borderRadius: 7,
    alignItems: 'center',
    justifyContent: 'center',
  },
  armyRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 7, marginTop: 'auto' },
  armyItem: { flexDirection: 'row', alignItems: 'center', gap: 2 },
  armyImage: { width: 30, height: 30, borderRadius: 6 },
  graph: { flex: 1, flexDirection: 'row', alignItems: 'flex-end', gap: 7 },
  graphColumn: { flex: 1, height: '100%', alignItems: 'center', gap: 4 },
  barTrack: {
    flex: 1,
    width: '70%',
    justifyContent: 'flex-end',
    backgroundColor: '#1E293B',
    borderRadius: 6,
    overflow: 'hidden',
  },
  bar: { width: '100%', backgroundColor: '#A78BFA' },
});
