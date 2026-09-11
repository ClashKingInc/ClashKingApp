import { useCallback, useEffect, useState } from 'react';
import {
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { ArrowLeft, Shield, Swords, Trophy, Upload } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  ErrorState,
  HeaderIconButton,
  LoadingIndicator,
  MobileWebImage,
  ResponsiveGrid,
  Snackbar,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { useAppRuntime } from '../../../core/app/runtime-context';
import type { Player, PlayerLegendBattle, PlayerLegendLeagueData } from '../../player/models';
import { exportLegends } from './legends-export';

export function LegendsRoot({
  player,
  onBack,
}: {
  readonly player: Player;
  readonly onBack: () => void;
}) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const [data, setData] = useState<PlayerLegendLeagueData | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string>();
  const [exporting, setExporting] = useState(false);
  const load = useCallback(
    async (force: boolean) => {
      if (force) setRefreshing(true);
      else setLoading(true);
      setError(null);
      try {
        setData(await runtime.players.loadLegendLeagueData(player.tag, force));
      } catch (caught) {
        setError(caught instanceof Error ? caught.message : String(caught));
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [player.tag, runtime.players],
  );
  useEffect(() => {
    let current = true;
    void runtime.players
      .loadLegendLeagueData(player.tag, false)
      .then((value) => {
        if (current) setData(value);
      })
      .catch((caught) => {
        if (current) setError(caught instanceof Error ? caught.message : String(caught));
      })
      .finally(() => {
        if (current) setLoading(false);
      });
    return () => {
      current = false;
    };
  }, [player.tag, runtime.players]);

  return (
    <View style={styles.fill}>
      <LegendsScreen
        data={data}
        error={error}
        exporting={exporting}
        loading={loading}
        refreshing={refreshing}
        onBack={onBack}
        onRefresh={() => load(true)}
        onExport={() => {
          if (!data || exporting) return;
          setExporting(true);
          void exportLegends(data)
            .then(() => setMessage(t('exportSuccess')))
            .catch((caught) => setMessage(String(caught)))
            .finally(() => setExporting(false));
        }}
      />
      <Snackbar message={message} onDismiss={() => setMessage(undefined)} />
    </View>
  );
}

export function LegendsScreen({
  data,
  error,
  exporting,
  loading,
  refreshing,
  onBack,
  onRefresh,
  onExport,
}: {
  readonly data: PlayerLegendLeagueData | null;
  readonly error: string | null;
  readonly exporting: boolean;
  readonly loading: boolean;
  readonly refreshing: boolean;
  readonly onBack: () => void;
  readonly onRefresh: () => Promise<void>;
  readonly onExport: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const horizontal = Math.max(16, (width - 1120) / 2);
  const current = data?.currentDay;
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      <ScrollView
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={() => void onRefresh()} />
        }
        contentContainerStyle={{ paddingBottom: insets.bottom + 28 }}
      >
        <View style={styles.hero}>
          <MobileWebImage
            imageUrl={ImageAssets.legendPageBackground}
            contentFit="cover"
            style={StyleSheet.absoluteFill}
          />
          <View style={[StyleSheet.absoluteFill, styles.heroScrim]} />
          <View
            style={[
              styles.heroContent,
              { paddingTop: insets.top + 4, paddingHorizontal: horizontal },
            ]}
          >
            <View style={styles.heroActions}>
              <HeaderIconButton
                label={materialBackLabel(locale)}
                onPress={onBack}
                icon={<ArrowLeft color="#FFF" />}
              />
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={t('generalExport')}
                disabled={!data || exporting}
                onPress={onExport}
                style={[styles.exportButton, { backgroundColor: colorWithAlpha('#000', 0.36) }]}
              >
                {exporting ? <LoadingIndicator /> : <Upload color="#FFF" size={20} />}
                <CKText role="labelLarge" style={styles.white}>
                  {t('generalExport')}
                </CKText>
              </Pressable>
            </View>
            <CKText role="screenTitle" style={styles.white}>
              {t('legendsTitle')}
            </CKText>
            <CKText role="titleMedium" style={styles.whiteSoft}>
              {data?.playerName ?? ''}
            </CKText>
            {data ? (
              <View style={styles.heroMetrics}>
                <HeroMetric
                  label={t('rankedLeagueTrophies')}
                  value={data.trophies}
                  icon={<Trophy color="#FFF" size={20} />}
                />
                <HeroMetric
                  label={t('legendsBestTrophies')}
                  value={data.bestTrophies}
                  icon={<Trophy color="#FFF" size={20} />}
                />
              </View>
            ) : null}
          </View>
        </View>
        <View style={[styles.content, { paddingHorizontal: horizontal }]}>
          {loading && !data ? (
            <LoadingIndicator />
          ) : error && !data ? (
            <ErrorState
              title={error}
              actionLabel={t('sideRefresh')}
              onAction={() => void onRefresh()}
            />
          ) : data ? (
            <>
              {current ? (
                <CurrentLegendDay data={current} locale={locale} />
              ) : (
                <EmptyState title={t('legendsNotInLeague')} body={t('legendsNoDataToday')} />
              )}
              <CKText role="sectionTitle" style={styles.sectionTitle}>
                {t('generalHistory')}
              </CKText>
              {data.history.length ? (
                <ResponsiveGrid minItemWidth={280} maxColumns={3}>
                  {data.history.map((season) => (
                    <Surface key={season.season} radius={ckRadius.tile} style={styles.seasonCard}>
                      <View style={styles.row}>
                        <CKText role="titleMedium" style={styles.grow}>
                          {formatSeason(season.season, locale)}
                        </CKText>
                        <CKText muted role="labelLarge">
                          #{season.rank || '-'}
                        </CKText>
                      </View>
                      <MetricRow
                        icon={<Trophy color={theme.primary} size={18} />}
                        label={t('legendsEosTrophies')}
                        value={season.trophies}
                      />
                      <MetricRow
                        icon={<Swords color={theme.onSurfaceVariant} size={18} />}
                        label={t('rankedLeagueAttacks')}
                        value={season.attackWins}
                      />
                      <MetricRow
                        icon={<Shield color={theme.onSurfaceVariant} size={18} />}
                        label={t('rankedLeagueDefenses')}
                        value={season.defenseWins}
                      />
                    </Surface>
                  ))}
                </ResponsiveGrid>
              ) : (
                <EmptyState title={t('generalNoDataAvailable')} />
              )}
            </>
          ) : null}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function CurrentLegendDay({
  data,
  locale,
}: {
  data: NonNullable<PlayerLegendLeagueData['currentDay']>;
  locale: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const format = new Intl.NumberFormat(toIntlLocale(locale));
  return (
    <View style={styles.sectionGap}>
      <View style={styles.row}>
        <CKText role="sectionTitle" style={styles.grow}>
          {new Intl.DateTimeFormat(toIntlLocale(locale), {
            dateStyle: 'long',
            timeZone: 'UTC',
          }).format(data.startsAt)}
        </CKText>
        <CKText
          role="titleMedium"
          style={{ color: data.trophyChange >= 0 ? '#14A37F' : theme.error }}
        >
          {data.trophyChange >= 0 ? '+' : ''}
          {format.format(data.trophyChange)}
        </CKText>
      </View>
      <ResponsiveGrid minItemWidth={170} maxColumns={2}>
        <Surface radius={ckRadius.tile} style={styles.daySummary}>
          <Swords color={theme.primary} />
          <CKText role="titleLarge">{data.attacks.length}</CKText>
          <CKText muted>
            {t('rankedLeagueAttacks')} · {data.attackTrophies >= 0 ? '+' : ''}
            {data.attackTrophies}
          </CKText>
        </Surface>
        <Surface radius={ckRadius.tile} style={styles.daySummary}>
          <Shield color={theme.primary} />
          <CKText role="titleLarge">{data.defenses.length}</CKText>
          <CKText muted>
            {t('rankedLeagueDefenses')} · {data.defenseTrophies}
          </CKText>
        </Surface>
      </ResponsiveGrid>
      {[
        ...data.attacks.map((battle) => ({ battle, attack: true })),
        ...data.defenses.map((battle) => ({ battle, attack: false })),
      ].map(({ battle, attack }, index) => (
        <LegendBattleRow
          key={`${attack ? 'a' : 'd'}-${battle.battleTime?.getTime() ?? index}`}
          battle={battle}
          attack={attack}
          locale={locale}
        />
      ))}
    </View>
  );
}

function LegendBattleRow({
  battle,
  attack,
  locale,
}: {
  battle: PlayerLegendBattle;
  attack: boolean;
  locale: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface radius={ckRadius.tile} style={styles.battleRow}>
      {attack ? (
        <Swords color={theme.primary} size={20} />
      ) : (
        <Shield color={theme.primary} size={20} />
      )}
      <View style={styles.grow}>
        <CKText role="rowTitle">
          {battle.automatic
            ? t('generalUnknown')
            : battle.opponentName || battle.opponentTag || t('generalUnknown')}
        </CKText>
        {battle.battleTime ? (
          <CKText muted role="labelSmall">
            {new Intl.DateTimeFormat(toIntlLocale(locale), { timeStyle: 'short' }).format(
              battle.battleTime,
            )}
          </CKText>
        ) : null}
      </View>
      {!battle.automatic ? (
        <CKText role="labelLarge">
          {battle.stars}★ · {battle.destructionPercentage}%
        </CKText>
      ) : null}
      <CKText role="titleMedium" style={{ color: battle.trophies >= 0 ? '#14A37F' : theme.error }}>
        {battle.trophies >= 0 ? '+' : ''}
        {battle.trophies}
      </CKText>
    </Surface>
  );
}

function HeroMetric({
  label,
  value,
  icon,
}: {
  label: string;
  value: number;
  icon: React.ReactNode;
}) {
  return (
    <View style={styles.heroMetric}>
      {icon}
      <View>
        <CKText role="labelSmall" style={styles.whiteSoft}>
          {label}
        </CKText>
        <CKText role="titleMedium" style={styles.white}>
          {value.toLocaleString()}
        </CKText>
      </View>
    </View>
  );
}

function MetricRow({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: number;
}) {
  return (
    <View style={styles.metricRow}>
      {icon}
      <CKText muted style={styles.grow}>
        {label}
      </CKText>
      <CKText role="labelLarge">{value.toLocaleString()}</CKText>
    </View>
  );
}

function formatSeason(season: string, locale: string) {
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'long',
    year: 'numeric',
    timeZone: 'UTC',
  }).format(new Date(`${season}-01T00:00:00Z`));
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  grow: { flex: 1 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  white: { color: '#FFF' },
  whiteSoft: { color: '#FFFFFFCC' },
  hero: { minHeight: 260, overflow: 'hidden' },
  heroScrim: { backgroundColor: '#00000088' },
  heroContent: { flex: 1, justifyContent: 'flex-end', paddingBottom: 24, gap: 4 },
  heroActions: {
    position: 'absolute',
    top: 0,
    left: 12,
    right: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  exportButton: {
    minHeight: 42,
    paddingHorizontal: 12,
    borderRadius: ckRadius.control,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  heroMetrics: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginTop: 10 },
  heroMetric: {
    minWidth: 150,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    padding: 10,
    borderRadius: ckRadius.tile,
    backgroundColor: '#00000055',
  },
  content: { width: '100%', maxWidth: 1120, alignSelf: 'center', paddingTop: 16, gap: 12 },
  sectionGap: { gap: 10 },
  sectionTitle: { marginTop: 8 },
  daySummary: { minHeight: 92, padding: 14, gap: 4 },
  battleRow: {
    minHeight: 64,
    paddingHorizontal: 12,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  seasonCard: { padding: 14, gap: 8 },
  metricRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
});
