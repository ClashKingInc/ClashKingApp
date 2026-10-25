import { useEffect, useRef, useState, type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { ArrowRight, Calendar, History } from 'lucide-react-native';
import { AnalyticsLineChart } from '../../stats/presentation/analytics-chart';
import { ChartInteractionBoundary } from '../../stats/presentation/chart-interaction-boundary';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  DestinationPicker,
  EmptyState,
  SkeletonContent,
  MobileWebImage,
  ResponsiveGrid,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import {
  ClanLeaderboardType,
  type ClanLeaderboardHistory,
  type ClanLeaderboardHistoryEntry,
  type ClanLeaderboardHistorySummary,
  type ClanLeaderboardSeasonSummary,
  type ClanLeaderboardTypeValue,
  type ClanLegendHistoryEntry,
  type ClanLegendHistorySummary,
  type ClanProfileChange,
  type ClanProfileHistory,
  type ClanRecord,
  type ClanRecords,
} from '../models';
import type { ClanInfoPresentationActions, ClanInfoPresentationModel } from './clan-info-contracts';
import { ClanTabEmpty, FilterPill } from './clan-tab-components';

type LeaderboardData = {
  summary: ClanLeaderboardHistorySummary;
  selected: readonly ClanLeaderboardSeasonSummary[];
  history: ClanLeaderboardHistory;
};

async function fetchLeaderboardData(
  actions: ClanInfoPresentationActions,
  clanTag: string,
  type: ClanLeaderboardTypeValue,
  requestedIndex: number,
): Promise<{ index: number; data: LeaderboardData }> {
  const summary = await actions.loadLeaderboardSummary(clanTag, type);
  if (!summary.seasons.length) {
    return {
      index: 0,
      data: { summary, selected: [], history: { items: [] } as ClanLeaderboardHistory },
    };
  }
  const index =
    type === ClanLeaderboardType.clanCapital
      ? Math.floor(Math.min(requestedIndex, summary.seasons.length - 1) / 6) * 6
      : Math.min(requestedIndex, summary.seasons.length - 1);
  const selected =
    type === ClanLeaderboardType.clanCapital
      ? summary.seasons.slice(index, index + 6)
      : summary.seasons.slice(index, index + 1);
  const histories = await Promise.all(
    selected.map((season) =>
      actions.loadLeaderboardHistory(clanTag, type, season.after, season.before),
    ),
  );
  const items = histories
    .flatMap((history) => history.items)
    .sort((a, b) => a.date.getTime() - b.date.getTime());
  return {
    index,
    data: { summary, selected, history: { items } as ClanLeaderboardHistory },
  };
}

export function ClanLeaderboardHistoryTab({
  model,
  actions,
  availableTypes = Object.values(ClanLeaderboardType),
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
  availableTypes?: readonly ClanLeaderboardTypeValue[];
}) {
  const { t, locale } = useI18n();
  const [type, setType] = useState<ClanLeaderboardTypeValue>(
    availableTypes[0] ?? ClanLeaderboardType.homeVillage,
  );
  const [seasonIndex, setSeasonIndex] = useState(0);
  const [data, setData] = useState<LeaderboardData>();
  const [error, setError] = useState(false);
  const requestId = useRef(0);
  const load = async (nextType = type, nextIndex = seasonIndex) => {
    const id = ++requestId.current;
    setError(false);
    setData(undefined);
    try {
      const value = await fetchLeaderboardData(actions, model.clan.tag, nextType, nextIndex);
      if (id !== requestId.current) return;
      setSeasonIndex(value.index);
      setData(value.data);
    } catch {
      if (id === requestId.current) setError(true);
    }
  };
  useEffect(() => {
    const id = ++requestId.current;
    void fetchLeaderboardData(actions, model.clan.tag, type, 0)
      .then((value) => {
        if (id !== requestId.current) return;
        setSeasonIndex(value.index);
        setData(value.data);
        setError(false);
      })
      .catch(() => {
        if (id === requestId.current) setError(true);
      });
    return () => {
      requestId.current += 1;
    };
  }, [actions, model.clan.tag, type]);
  const pointsLabel =
    type === ClanLeaderboardType.homeVillage
      ? t('clanPointsTitle')
      : type === ClanLeaderboardType.builderBase
        ? t('clanBuilderBasePoints')
        : t('clanCapitalPoints');
  const seasonChoices = (data?.summary.seasons ?? []).flatMap((item, index) =>
    type !== ClanLeaderboardType.clanCapital || index % 6 === 0
      ? [
          {
            key: `${index}`,
            label:
              type === ClanLeaderboardType.clanCapital
                ? capitalBucketLabel(data!.summary.seasons, index, locale)
                : `${seasonLabel(item.season, locale)} · ${t('statsIndexDays', {
                    index: item.daysInTop200,
                  })}`,
          },
        ]
      : [],
  );
  return (
    <View style={styles.tab}>
      <View style={styles.pills}>
        {availableTypes.includes(ClanLeaderboardType.homeVillage) ? (
          <FilterPill
            label={t('gameBaseHome')}
            selected={type === ClanLeaderboardType.homeVillage}
            onPress={() => {
              setSeasonIndex(0);
              setType(ClanLeaderboardType.homeVillage);
            }}
          />
        ) : null}
        {availableTypes.includes(ClanLeaderboardType.builderBase) ? (
          <FilterPill
            label={t('gameBaseBuilder')}
            selected={type === ClanLeaderboardType.builderBase}
            onPress={() => {
              setSeasonIndex(0);
              setType(ClanLeaderboardType.builderBase);
            }}
          />
        ) : null}
        {availableTypes.includes(ClanLeaderboardType.clanCapital) ? (
          <FilterPill
            label={t('gameClanCapital')}
            selected={type === ClanLeaderboardType.clanCapital}
            onPress={() => {
              setSeasonIndex(0);
              setType(ClanLeaderboardType.clanCapital);
            }}
          />
        ) : null}
      </View>
      {error ? (
        <ClanTabEmpty
          title={t('generalError')}
          body={t('generalTryAgain')}
          onRetry={() => void load()}
        />
      ) : !data ? (
        <SkeletonContent loading>
          <View style={styles.seasonPickerRow}>
            <SeasonPicker
              accessibilityLabel={t('clanRankingsSelectSeason')}
              selectedKey="loading"
              choices={[{ key: 'loading', label: 'Season' }]}
              onSelect={() => undefined}
            />
          </View>
          <View style={styles.historyCharts}>
            <HistoryChart
              items={[]}
              metric="rank"
              type={type}
              label={t('cwlRankTitle')}
              locale={locale}
            />
            <HistoryChart
              items={[]}
              metric="points"
              type={type}
              label={pointsLabel}
              locale={locale}
            />
          </View>
        </SkeletonContent>
      ) : !data.summary.seasons.length ? (
        <ClanTabEmpty title={t('generalNoDataAvailable')} />
      ) : (
        <>
          <View style={styles.seasonPickerRow}>
            <SeasonPicker
              accessibilityLabel={t('clanRankingsSelectSeason')}
              selectedKey={`${seasonIndex}`}
              choices={seasonChoices}
              onSelect={(key) => void load(type, Number(key))}
            />
          </View>
          {data.history.items.length ? (
            <ChartInteractionBoundary key={`${type}:${seasonIndex}`}>
              <View style={styles.historyCharts}>
                <HistoryChart
                  items={data.history.items}
                  metric="rank"
                  type={type}
                  label={t('cwlRankTitle')}
                  locale={locale}
                />
                <HistoryChart
                  items={data.history.items}
                  metric="points"
                  type={type}
                  label={pointsLabel}
                  locale={locale}
                />
              </View>
            </ChartInteractionBoundary>
          ) : (
            <EmptyState title={t('generalNoDataAvailable')} />
          )}
        </>
      )}
    </View>
  );
}

function HistoryChart({
  items,
  metric,
  type,
  label,
  locale,
}: {
  items: readonly ClanLeaderboardHistoryEntry[];
  metric: 'rank' | 'points';
  type: ClanLeaderboardTypeValue;
  label: string;
  locale: string;
}) {
  const { t } = useI18n();
  const groups = new Map<string, ClanLeaderboardHistoryEntry[]>();
  for (const item of items) {
    const key = item.location?.name ?? '';
    groups.set(key, [...(groups.get(key) ?? []), item]);
  }
  return (
    <Surface style={styles.chart}>
      <AnalyticsLineChart
        title={label}
        inverted={metric === 'rank'}
        showPoints
        connectGaps={false}
        axisMinimum={metric === 'rank' ? 1 : 0}
        formatAxisValue={(value) =>
          metric === 'rank'
            ? `#${Math.round(value)}`
            : Math.round(value).toLocaleString(toIntlLocale(locale), {
                notation: 'compact',
                maximumFractionDigits: 1,
              })
        }
        formatPointDetail={(key, day) => {
          const entry = groups
            .get(key.slice(metric.length + 1))
            ?.findLast((item) => item.date.toISOString().slice(0, 10) === day);
          return entry
            ? `${t('clanMembers')}: ${entry.members.toLocaleString(toIntlLocale(locale))}`
            : undefined;
        }}
        formatValue={(value) =>
          `${metric === 'rank' ? '#' : ''}${Math.round(value).toLocaleString(toIntlLocale(locale))}`
        }
        series={[...groups].map(([location, entries], index) => ({
          key: `${metric}:${location}`,
          label: location || label,
          ...(index === 0 ? { color: leaderboardChartAccent(type) } : {}),
          points: entries.map((entry) => ({
            day: entry.date.toISOString().slice(0, 10),
            value: metric === 'rank' ? entry.rank : entry.points,
          })),
        }))}
      />
    </Surface>
  );
}

export function leaderboardEntryKey(
  entry: ClanLeaderboardHistoryEntry,
  index: number,
  type: ClanLeaderboardTypeValue,
) {
  return `${type}:${entry.date.toISOString()}:${entry.rank}:${entry.points}:${entry.members}:${index}`;
}

export function ClanLegendHistoryTab({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { t, locale } = useI18n();
  const [summary, setSummary] = useState<ClanLegendHistorySummary>();
  const [items, setItems] = useState<readonly ClanLegendHistoryEntry[]>();
  const [season, setSeason] = useState<string>();
  const [error, setError] = useState(false);
  const load = async (selected?: string) => {
    setError(false);
    setItems(undefined);
    try {
      const nextSummary = summary ?? (await actions.loadLegendSummary(model.clan.tag));
      setSummary(nextSummary);
      const chosen = selected ?? nextSummary.seasons[0]?.season ?? '__top__';
      setSeason(chosen);
      if (chosen === '__top__') setItems(nextSummary.topFinishes);
      else {
        const target =
          nextSummary.seasons.find((entry) => entry.season === chosen) ?? nextSummary.seasons[0];
        setItems(
          target
            ? (await actions.loadLegendHistory(model.clan.tag, target.after, target.before)).items
            : nextSummary.topFinishes,
        );
      }
    } catch {
      setError(true);
    }
  };
  useEffect(() => {
    let active = true;
    void actions
      .loadLegendSummary(model.clan.tag)
      .then(async (nextSummary) => {
        const chosen = nextSummary.seasons[0]?.season ?? '__top__';
        const target = nextSummary.seasons[0];
        const nextItems = target
          ? (await actions.loadLegendHistory(model.clan.tag, target.after, target.before)).items
          : nextSummary.topFinishes;
        if (active) {
          setSummary(nextSummary);
          setSeason(chosen);
          setItems(nextItems);
          setError(false);
        }
      })
      .catch(() => {
        if (active) setError(true);
      });
    return () => {
      active = false;
    };
  }, [actions, model.clan.tag]);
  if (error)
    return (
      <ClanTabEmpty
        title={t('generalError')}
        body={t('generalTryAgain')}
        onRetry={() => void load(season)}
      />
    );
  if (!summary || !items)
    return (
      <SkeletonContent loading style={styles.tab}>
        <View style={styles.seasonPickerRow}>
          <SeasonPicker
            accessibilityLabel={t('clanRankingsSelectSeason')}
            selectedKey="loading"
            choices={[{ key: 'loading', label: 'Season' }]}
            onSelect={() => undefined}
          />
        </View>
        <ResponsiveGrid minItemWidth={430} maxColumns={2} gap={12}>
          {[0, 1, 2].map((index) => (
            <LegendRow
              key={index}
              entry={{
                season: '2026-01',
                tag: '',
                name: 'Player name',
                expLevel: 100,
                trophies: 5000,
                attackWins: 100,
                defenseWins: 10,
                rank: 100,
              }}
              showSeason={false}
            />
          ))}
        </ResponsiveGrid>
      </SkeletonContent>
    );
  if (!summary.seasons.length && !items.length)
    return <ClanTabEmpty title={t('generalNoDataAvailable')} />;
  const choices = [
    {
      key: '__top__',
      label: t('generalAllTime'),
      imageUrl: ImageAssets.legendLeagueOne,
    },
    ...summary.seasons.map((entry) => ({
      key: entry.season,
      label: `${seasonLabel(entry.season, locale)} · ${t('searchTabPlayers')}: ${entry.playerCount}`,
      imageUrl: legendBadgeForSeason(entry.season),
    })),
  ];
  return (
    <View style={styles.tab}>
      <View style={styles.seasonPickerRow}>
        <SeasonPicker
          accessibilityLabel={t('clanRankingsSelectSeason')}
          selectedKey={season ?? choices[0]!.key}
          choices={choices}
          onSelect={(key) => void load(key)}
        />
      </View>
      <ResponsiveGrid minItemWidth={430} maxColumns={2} gap={12}>
        {items.map((entry, index) => (
          <LegendRow
            key={`${entry.season}:${entry.tag}:${entry.rank}:${index}`}
            entry={entry}
            showSeason={season === '__top__'}
          />
        ))}
      </ResponsiveGrid>
    </View>
  );
}
function LegendRow({ entry, showSeason }: { entry: ClanLegendHistoryEntry; showSeason: boolean }) {
  const { t, locale } = useI18n();
  const intlLocale = toIntlLocale(locale);
  const theme = useCKTheme();
  return (
    <Surface style={styles.row}>
      <View style={styles.legendHead}>
        <MobileWebImage imageUrl={legendBadgeForSeason(entry.season)} style={styles.legendBadge} />
        <View style={styles.grow}>
          <CKText style={styles.bold}>{entry.name}</CKText>
          <CKText muted role="metadata">
            {entry.tag}
            {showSeason ? ` · ${seasonLabel(entry.season, locale)}` : ''}
          </CKText>
        </View>
        <View style={styles.rankMetric}>
          <History size={16} color={theme.onSurfaceVariant} />
          <CKText role="labelLarge">#{entry.rank.toLocaleString(intlLocale)}</CKText>
        </View>
      </View>
      <View style={styles.metrics}>
        <Metric
          image={ImageAssets.trophies}
          label={t('gameTrophies')}
          value={entry.trophies.toLocaleString(intlLocale)}
        />
        <Metric
          image={ImageAssets.attacks}
          label={t('warAttacksTitle')}
          value={entry.attackWins.toLocaleString(intlLocale)}
        />
        <Metric
          image={ImageAssets.shield}
          label={t('warDefensesTitle')}
          value={entry.defenseWins.toLocaleString(intlLocale)}
        />
      </View>
    </Surface>
  );
}

export function ClanRecordsHistoryTab({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { t } = useI18n();
  const [records, setRecords] = useState<ClanRecords>();
  const [history, setHistory] = useState<ClanProfileHistory>();
  const [filter, setFilter] = useState<'all' | 'description' | 'clanLevel'>('all');
  const [error, setError] = useState(false);
  const load = async () => {
    setError(false);
    try {
      const [nextRecords, nextHistory] = await Promise.all([
        actions.loadRecords(model.clan.tag),
        actions.loadProfileHistory(model.clan.tag),
      ]);
      setRecords(nextRecords);
      setHistory(nextHistory);
    } catch {
      setError(true);
    }
  };
  useEffect(() => {
    let active = true;
    void Promise.all([
      actions.loadRecords(model.clan.tag),
      actions.loadProfileHistory(model.clan.tag),
    ])
      .then(([nextRecords, nextHistory]) => {
        if (active) {
          setRecords(nextRecords);
          setHistory(nextHistory);
          setError(false);
        }
      })
      .catch(() => {
        if (active) setError(true);
      });
    return () => {
      active = false;
    };
  }, [actions, model.clan.tag]);
  if (error)
    return (
      <ClanTabEmpty
        title={t('generalError')}
        body={t('generalTryAgain')}
        onRetry={() => void load()}
      />
    );
  if (!records || !history)
    return (
      <SkeletonContent loading style={styles.tab}>
        <ResponsiveGrid minItemWidth={360} maxColumns={2} gap={12}>
          <RecordPanel
            label={t('clanPointsTitle')}
            record={{ value: 10000, time: new Date(0) }}
            image={ImageAssets.bestTrophies}
          />
          <RecordPanel
            label={t('rankingsWinStreak')}
            record={{ value: 100, time: new Date(0) }}
            image={ImageAssets.war}
          />
        </ResponsiveGrid>
        {[0, 1, 2].map((index) => (
          <ProfileChangeRow
            key={index}
            change={{ time: new Date(0), type: 'clanLevel', previous: 10, current: 11 }}
            badge={model.clan.badgeUrls.smallest}
          />
        ))}
      </SkeletonContent>
    );
  if (records.isEmpty && !history.items.length)
    return <ClanTabEmpty title={t('generalNoDataAvailable')} />;
  const changes = history.items.filter((change) => filter === 'all' || change.type === filter);
  return (
    <View style={styles.tab}>
      <ResponsiveGrid minItemWidth={360} maxColumns={2} gap={12}>
        {records.clanPoints ? (
          <RecordPanel
            label={t('clanPointsTitle')}
            record={records.clanPoints}
            image={ImageAssets.bestTrophies}
          />
        ) : null}
        {records.warWinStreak ? (
          <RecordPanel
            label={t('rankingsWinStreak')}
            record={records.warWinStreak}
            image={ImageAssets.war}
          />
        ) : null}
      </ResponsiveGrid>
      {history.items.length ? (
        <>
          <View style={styles.pills}>
            <FilterPill
              label={t('generalAll')}
              selected={filter === 'all'}
              onPress={() => setFilter('all')}
            />
            <FilterPill
              label={t('clanProfileDescriptionChanged')}
              selected={filter === 'description'}
              onPress={() => setFilter('description')}
            />
            <FilterPill
              label={t('clanProfileLevelChanged')}
              selected={filter === 'clanLevel'}
              onPress={() => setFilter('clanLevel')}
            />
          </View>
          {changes.length ? (
            <ResponsiveGrid minItemWidth={430} maxColumns={2} gap={12}>
              {changes.map((change, index) => (
                <ProfileChangeRow
                  key={profileChangeKey(change, index)}
                  change={change}
                  badge={model.clan.badgeUrls.smallest}
                />
              ))}
            </ResponsiveGrid>
          ) : (
            <EmptyState title={t('generalNoDataAvailable')} />
          )}
        </>
      ) : null}
    </View>
  );
}

export function profileChangeKey(change: ClanProfileChange, index: number): string {
  return `${change.time.toISOString()}:${change.type}:${JSON.stringify(change.previous)}:${JSON.stringify(change.current)}:${index}`;
}
function RecordPanel({
  label,
  record,
  image,
}: {
  label: string;
  record: ClanRecord;
  image: string;
}) {
  const { locale } = useI18n();
  const intlLocale = toIntlLocale(locale);
  return (
    <Surface style={styles.recordPanel}>
      <MobileWebImage imageUrl={image} style={styles.recordImage} />
      <View>
        <CKText muted role="metadata">
          {label}
        </CKText>
        <CKText role="screenTitle">{record.value.toLocaleString(intlLocale)}</CKText>
        <CKText muted role="metadata">
          {new Intl.DateTimeFormat(intlLocale, {
            dateStyle: 'medium',
            timeStyle: 'short',
          }).format(record.time)}
        </CKText>
      </View>
    </Surface>
  );
}
function ProfileChangeRow({ change, badge }: { change: ClanProfileChange; badge: string }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const previous = change.previous?.toString() ?? t('generalNotSet'),
    current = change.current?.toString() ?? t('generalNotSet');
  const diff = descriptionTextDiff(previous, current);
  return (
    <Surface style={styles.profileRow}>
      {change.type === 'clanLevel' ? (
        <MobileWebImage imageUrl={badge} style={styles.profileArt} />
      ) : (
        <History size={36} color={theme.onSurfaceVariant} />
      )}
      <View style={styles.grow}>
        <CKText style={styles.bold}>
          {change.type === 'clanLevel'
            ? t('clanProfileLevelChanged')
            : change.type === 'description'
              ? t('clanProfileDescriptionChanged')
              : t('clanProfileHistoryTab')}
        </CKText>
        <CKText muted role="metadata">
          {new Intl.DateTimeFormat(toIntlLocale(locale), {
            dateStyle: 'medium',
            timeStyle: 'short',
          }).format(change.time)}
        </CKText>
        {change.type === 'clanLevel' ? (
          <View style={styles.levelChange}>
            <CKText role="screenTitle">{previous}</CKText>
            <ArrowRight size={20} color={theme.onSurfaceVariant} />
            <CKText role="screenTitle" style={{ color: '#E8A524' }}>
              {current}
            </CKText>
          </View>
        ) : (
          <View style={styles.descriptionDiff}>
            <CKText testID="description-diff-removed" accessibilityLabel={`Removed: ${previous}`}>
              {diff.prefix}
              <CKText style={styles.descriptionRemoved}>{diff.removed || ' '}</CKText>
              {diff.suffix}
            </CKText>
            <View
              testID="description-diff-divider"
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
              style={[
                styles.descriptionDivider,
                { backgroundColor: colorWithAlpha(theme.outlineVariant, 0.42) },
              ]}
            />
            <CKText testID="description-diff-added" accessibilityLabel={`Added: ${current}`}>
              {diff.prefix}
              <CKText style={styles.descriptionAdded}>{diff.added || ' '}</CKText>
              {diff.suffix}
            </CKText>
          </View>
        )}
      </View>
    </Surface>
  );
}

export type DescriptionTextDiff = {
  readonly prefix: string;
  readonly removed: string;
  readonly added: string;
  readonly suffix: string;
};

export function descriptionTextDiff(previous: string, current: string): DescriptionTextDiff {
  const shortest = Math.min(previous.length, current.length);
  let prefixLength = 0;
  while (
    prefixLength < shortest &&
    previous.charCodeAt(prefixLength) === current.charCodeAt(prefixLength)
  )
    prefixLength += 1;

  let suffixLength = 0;
  while (
    suffixLength < shortest - prefixLength &&
    previous.charCodeAt(previous.length - suffixLength - 1) ===
      current.charCodeAt(current.length - suffixLength - 1)
  )
    suffixLength += 1;

  const previousEnd = previous.length - suffixLength;
  const currentEnd = current.length - suffixLength;
  return {
    prefix: previous.slice(0, prefixLength),
    removed: previous.slice(prefixLength, previousEnd),
    added: current.slice(prefixLength, currentEnd),
    suffix: previous.slice(previousEnd),
  };
}
type SeasonChoice = {
  key: string;
  label: string;
  imageUrl?: string;
};

function SeasonPicker({
  accessibilityLabel,
  selectedKey,
  choices,
  onSelect,
}: {
  accessibilityLabel: string;
  selectedKey: string;
  choices: readonly SeasonChoice[];
  onSelect: (key: string) => void;
}) {
  const theme = useCKTheme();
  const selected = choices.find((choice) => choice.key === selectedKey) ?? choices[0];
  if (!selected) return null;
  return (
    <DestinationPicker
      accessibilityLabel={accessibilityLabel}
      onSelect={onSelect}
      options={choices.map((choice) => ({
        key: choice.key,
        label: choice.label,
        icon: choice.imageUrl ? (
          <MobileWebImage imageUrl={choice.imageUrl} style={styles.seasonImage} />
        ) : (
          <Calendar size={18} color={theme.onSurfaceVariant} />
        ),
      }))}
      selectedKey={selected.key}
    />
  );
}
function Metric({
  image,
  icon,
  label,
  value,
}: {
  image?: string;
  icon?: ReactNode;
  label: string;
  value: string;
}) {
  return (
    <View style={styles.metric}>
      {image ? <MobileWebImage imageUrl={image} style={styles.metricImage} /> : icon}
      <View>
        <CKText muted role="labelSmall">
          {label}
        </CKText>
        <CKText role="labelLarge">{value}</CKText>
      </View>
    </View>
  );
}
function seasonLabel(season: string, locale: string) {
  const normalized = season.startsWith('v2-') ? season.slice(3) : season;
  const date = new Date(
    `${normalized.length === 7 ? normalized : normalized.slice(0, 7)}-01T00:00:00`,
  );
  return Number.isNaN(date.getTime())
    ? season
    : new Intl.DateTimeFormat(toIntlLocale(locale), { month: 'long', year: 'numeric' }).format(
        date,
      );
}

export function capitalBucketLabel(
  seasons: readonly ClanLeaderboardSeasonSummary[],
  startIndex: number,
  locale: string,
) {
  const bucket = seasons.slice(Math.max(0, startIndex), Math.max(0, startIndex) + 6);
  if (!bucket.length) return '';
  const start = bucket.reduce(
    (earliest, item) => (item.after < earliest ? item.after : earliest),
    bucket[0]!.after,
  );
  const end = bucket.reduce(
    (latest, item) => (item.before > latest ? item.before : latest),
    bucket[0]!.before,
  );
  const format = new Intl.DateTimeFormat(toIntlLocale(locale), {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
  return `${format.format(start)} – ${format.format(end)}`;
}

function leaderboardChartAccent(type: ClanLeaderboardTypeValue) {
  if (type === ClanLeaderboardType.builderBase) return '#2A9FD6';
  if (type === ClanLeaderboardType.clanCapital) return '#E56B2F';
  return '#4E7DF2';
}

function legendBadgeForSeason(season: string) {
  return /^\d{4}-\d{2}$/.test(season) ? ImageAssets.legendBlazon : ImageAssets.legendLeagueOne;
}

const styles = StyleSheet.create({
  tab: { padding: 16, gap: 12 },
  historyCharts: { gap: 12 },
  center: { minHeight: 180, alignItems: 'center', justifyContent: 'center' },
  pills: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  grow: { flex: 1 },
  summaryGroup: { flexDirection: 'row', gap: 8 },
  seasonPickerRow: { width: '100%', maxWidth: 440, alignSelf: 'flex-end' },
  chart: { paddingHorizontal: 10, paddingTop: 12, paddingBottom: 2 },
  chartLegend: { flexDirection: 'row', alignItems: 'center', gap: 7, paddingHorizontal: 4 },
  chartLegendDot: { width: 9, height: 9, borderRadius: 5 },
  list: { gap: 12 },
  row: { padding: 16, gap: 12 },
  rowHead: { flexDirection: 'row', justifyContent: 'space-between' },
  metrics: { flexDirection: 'row', gap: 12 },
  metric: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: 8 },
  metricImage: { width: 24, height: 24, resizeMode: 'contain' },
  bold: { fontWeight: '800' },
  legendHead: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  legendBadge: { width: 42, height: 42 },
  rankMetric: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  recordPanel: { padding: 16, flexDirection: 'row', alignItems: 'center', gap: 16 },
  recordImage: { width: 52, height: 52, resizeMode: 'contain' },
  profileRow: { padding: 12, flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  profileArt: { width: 48, height: 48, resizeMode: 'contain' },
  levelChange: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 12 },
  descriptionDiff: { marginTop: 10, gap: 7 },
  descriptionDivider: { height: StyleSheet.hairlineWidth, width: '100%' },
  descriptionRemoved: { color: '#E35D4F', textDecorationLine: 'line-through' },
  descriptionAdded: { color: '#14A37F', fontWeight: '700' },
  seasonImage: { width: 22, height: 22, resizeMode: 'contain' },
});
