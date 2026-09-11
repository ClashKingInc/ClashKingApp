import { StyleSheet, View } from 'react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText, HorizontalImageShareModal, MobileWebImage, colorWithAlpha } from '../../../ui';
import type { PlayerBattlelogEntry, PlayerBattlelogMode } from '../models';

export interface BattlelogShareSummary {
  readonly battleCount: number;
  readonly attackCount: number;
  readonly totalLoot: number;
  readonly averageLoot: number;
  readonly tripleRate: number;
  readonly lootTimelines: Readonly<
    Record<'gold' | 'elixir' | 'darkElixir', ReturnType<typeof battlelogLootTimeline>>
  >;
}

export function battlelogShareSummary(
  items: readonly PlayerBattlelogEntry[],
): BattlelogShareSummary {
  const attacks = items.filter((item) => item.attack);
  const totalLoot = attacks.reduce((sum, item) => sum + item.totalLoot, 0);
  return {
    battleCount: items.length,
    attackCount: attacks.length,
    totalLoot,
    averageLoot: attacks.length === 0 ? 0 : totalLoot / attacks.length,
    tripleRate:
      attacks.length === 0
        ? 0
        : (attacks.filter((item) => item.stars === 3).length / attacks.length) * 100,
    lootTimelines: {
      gold: battlelogLootTimeline(attacks, 'gold'),
      elixir: battlelogLootTimeline(attacks, 'elixir'),
      darkElixir: battlelogLootTimeline(attacks, 'darkElixir'),
    },
  };
}

export function battlelogLootTimeline(
  attacks: readonly PlayerBattlelogEntry[],
  resource: 'gold' | 'elixir' | 'darkElixir',
) {
  const dated = attacks.filter((item) => item.timestamp !== null);
  const end = new Date(Math.max(...dated.map((item) => item.timestamp!.getTime()), 0));
  if (end.getTime() === 0) return [];
  end.setUTCHours(0, 0, 0, 0);
  const totals = new Map<string, number>();
  for (const item of dated) {
    const day = item.timestamp!.toISOString().slice(0, 10);
    totals.set(day, (totals.get(day) ?? 0) + item[resource]);
  }
  const values = Array.from({ length: 28 }, (_, index) => {
    const date = new Date(end.getTime() - (27 - index) * 86_400_000);
    const day = date.toISOString().slice(0, 10);
    return { day, value: totals.get(day) ?? 0 };
  });
  const maximum = Math.max(1, ...values.map((item) => item.value));
  return values.map((item) => ({ ...item, intensity: item.value / maximum }));
}

export function PlayerBattlelogShareModal({
  items,
  mode,
  playerName,
  visible,
  onClose,
}: {
  readonly items: readonly PlayerBattlelogEntry[];
  readonly mode: PlayerBattlelogMode;
  readonly playerName: string;
  readonly visible: boolean;
  readonly onClose: () => void;
}) {
  const { t, locale } = useI18n();
  const summary = battlelogShareSummary(items);
  return (
    <HorizontalImageShareModal
      artworkUrls={[ImageAssets.darkModeLogo]}
      fileName={battlelogImageFileName(playerName, mode)}
      message={`${playerName} ${mode} battlelog on ClashKing`}
      onClose={onClose}
      title={t('generalExport')}
      visible={visible}
    >
      <View style={styles.graphic}>
        <View style={styles.heading}>
          <View>
            <CKText role="screenTitle" style={styles.white}>
              {playerName}
            </CKText>
            <CKText role="titleMedium" style={styles.soft}>
              {mode.toUpperCase()} BATTLELOG
            </CKText>
          </View>
          <MobileWebImage imageUrl={ImageAssets.darkModeLogo} style={styles.logo} />
        </View>
        <View style={styles.metrics}>
          <ShareMetric
            label={t('playerBattlelogBattleCount', { count: summary.battleCount })}
            value={`${summary.battleCount}`}
          />
          <ShareMetric
            label={t('generalTotal')}
            value={formatPlayerResourceAmount(summary.totalLoot, locale)}
          />
          <ShareMetric
            label={t('generalAverage')}
            value={formatPlayerResourceAmount(summary.averageLoot, locale)}
          />
          <ShareMetric label={t('warStarsThree')} value={`${summary.tripleRate.toFixed(1)}%`} />
        </View>
        <View style={styles.timelineHeader}>
          <CKText role="titleMedium" style={styles.white}>
            {t('playerBattlelogFarmingOverview')}
          </CKText>
          <CKText role="labelSmall" style={styles.soft}>
            {summary.attackCount} {t('warAttacksTitle')}
          </CKText>
        </View>
        <View style={styles.timelines}>
          {summary.lootTimelines.gold.length === 0 ? (
            <CKText style={styles.soft}>{t('generalNoDataAvailable')}</CKText>
          ) : (
            <>
              <LootTimelineRow
                color="#F8C94A"
                label={t('resourceGold')}
                timeline={summary.lootTimelines.gold}
              />
              <LootTimelineRow
                color="#D77BFF"
                label={t('resourceElixir')}
                timeline={summary.lootTimelines.elixir}
              />
              <LootTimelineRow
                color="#7E4BC6"
                label={t('resourceDarkElixir')}
                timeline={summary.lootTimelines.darkElixir}
              />
            </>
          )}
        </View>
      </View>
    </HorizontalImageShareModal>
  );
}

function formatPlayerResourceAmount(value: number, locale: string) {
  return new Intl.NumberFormat(toIntlLocale(locale), {
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(Math.round(value));
}

export function battlelogImageFileName(
  playerName: string,
  mode: PlayerBattlelogMode,
  now = new Date(),
) {
  const safeName = playerName
    .replace(/[^\w\s-]/gu, '')
    .trim()
    .replace(/\s+/gu, '_');
  const pad = (value: number) => String(value).padStart(2, '0');
  const timestamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
  return `battlelog_${mode}${safeName ? `_${safeName}` : ''}_${timestamp}.png`;
}

function ShareMetric({ label, value }: { readonly label: string; readonly value: string }) {
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

function LootTimelineRow({
  color,
  label,
  timeline,
}: {
  readonly color: string;
  readonly label: string;
  readonly timeline: ReturnType<typeof battlelogLootTimeline>;
}) {
  return (
    <View style={styles.timelineRow}>
      <CKText role="labelSmall" style={[styles.soft, styles.timelineLabel]} numberOfLines={1}>
        {label}
      </CKText>
      {timeline.map((day) => (
        <View
          accessible
          accessibilityLabel={`${label}, ${day.day}: ${day.value}`}
          key={day.day}
          style={[
            styles.day,
            { backgroundColor: colorWithAlpha(color, 0.12 + day.intensity * 0.88) },
          ]}
        />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  graphic: { flex: 1, padding: 28, gap: 20, backgroundColor: '#0B1220' },
  heading: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  white: { color: '#FFF' },
  soft: { color: '#B8C4D8' },
  logo: { width: 64, height: 64 },
  metrics: { flexDirection: 'row', gap: 12 },
  metric: { flex: 1, padding: 14, borderRadius: 14, backgroundColor: '#162033' },
  timelineHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  timelines: { flex: 1, gap: 8, justifyContent: 'center' },
  timelineRow: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  timelineLabel: { width: 78 },
  day: { flex: 1, height: 40, borderRadius: 5 },
});
