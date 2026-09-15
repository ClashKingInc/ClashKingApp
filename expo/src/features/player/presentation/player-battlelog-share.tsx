import { StyleSheet, View } from 'react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText, HorizontalImageShareModal, MobileWebImage, colorWithAlpha } from '../../../ui';
import type { PlayerBattlelogEntry, PlayerBattlelogMode } from '../models';

export interface BattlelogLootDay {
  readonly day: string;
  readonly gold: number;
  readonly elixir: number;
  readonly darkElixir: number;
  readonly total: number;
  readonly intensity: 0 | 0.25 | 0.5 | 0.75 | 1;
}

export interface BattlelogShareSummary {
  readonly attackCount: number;
  readonly totalLoot: number;
  readonly lootTimeline: readonly BattlelogLootDay[];
}

export function battlelogShareSummary(
  items: readonly PlayerBattlelogEntry[],
  now = new Date(),
): BattlelogShareSummary {
  const lootTimeline = battlelogLootTimeline(items, now);
  return {
    attackCount: items.filter((item) => isAttackInLootWindow(item, now)).length,
    totalLoot: lootTimeline.reduce((sum, item) => sum + item.total, 0),
    lootTimeline,
  };
}

export function battlelogLootTimeline(attacks: readonly PlayerBattlelogEntry[], now = new Date()) {
  const end = new Date(now);
  end.setUTCHours(0, 0, 0, 0);
  const totals = new Map<string, Omit<BattlelogLootDay, 'day' | 'intensity'>>();
  for (const item of attacks.filter((entry) => isAttackInLootWindow(entry, now))) {
    const day = item.timestamp!.toISOString().slice(0, 10);
    const current = totals.get(day) ?? { gold: 0, elixir: 0, darkElixir: 0, total: 0 };
    totals.set(day, {
      gold: current.gold + item.gold,
      elixir: current.elixir + item.elixir,
      darkElixir: current.darkElixir + item.darkElixir,
      total: current.total + item.totalLoot,
    });
  }
  const values = Array.from({ length: 30 }, (_, index) => {
    const date = new Date(end.getTime() - (29 - index) * 86_400_000);
    const day = date.toISOString().slice(0, 10);
    return { day, ...(totals.get(day) ?? { gold: 0, elixir: 0, darkElixir: 0, total: 0 }) };
  });
  const maximum = Math.max(1, ...values.map((item) => item.total));
  return values.map((item): BattlelogLootDay => {
    const ratio = item.total / maximum;
    const intensity =
      ratio === 0 ? 0 : ratio <= 0.25 ? 0.25 : ratio <= 0.5 ? 0.5 : ratio <= 0.75 ? 0.75 : 1;
    return { ...item, intensity };
  });
}

function isAttackInLootWindow(item: PlayerBattlelogEntry, now: Date) {
  if (!item.attack || !item.timestamp) return false;
  const end = new Date(now);
  end.setUTCHours(24, 0, 0, 0);
  const start = new Date(end.getTime() - 30 * 86_400_000);
  return item.timestamp >= start && item.timestamp < end;
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
            label={`${t('capitalRaidLoot')} · ${t('filtersLast30Days')}`}
            value={formatPlayerResourceAmount(summary.totalLoot, locale)}
          />
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
          <LootTimelineGrid timeline={summary.lootTimeline} />
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

function LootTimelineGrid({ timeline }: { readonly timeline: readonly BattlelogLootDay[] }) {
  const columns = Array.from({ length: Math.ceil(timeline.length / 7) }, (_, index) =>
    timeline.slice(index * 7, index * 7 + 7),
  );
  return (
    <View style={styles.timelineGrid}>
      {columns.map((column, columnIndex) => (
        <View key={columnIndex} style={styles.timelineColumn}>
          {column.map((day) => (
            <View
              accessible
              accessibilityLabel={`${day.day}: ${day.total}`}
              key={day.day}
              style={[
                styles.day,
                { backgroundColor: colorWithAlpha('#14A37F', 0.1 + day.intensity * 0.9) },
              ]}
            />
          ))}
        </View>
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
  timelineGrid: { flexDirection: 'row', gap: 6, justifyContent: 'center' },
  timelineColumn: { gap: 6 },
  day: { width: 42, height: 42, borderRadius: 5 },
});
