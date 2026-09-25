import { type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n, type MessageKey } from '../../../i18n';
import { CKText, MobileWebImage, PillSurface } from '../../../ui';
import { homeSelectedAccountIndex } from './contracts';
import type {
  HomeAccountIdentity,
  HomeDashboardActions,
  HomeMetricKind,
  HomeMetricModel,
  HomeRankedAccount,
  HomeRankedCardModel,
  HomeTodoCardModel,
  HomeTodoSummary,
  HomeUpgradeAccount,
  HomeUpgradeCardModel,
} from './contracts';
import {
  CardHeader,
  CaughtUp,
  HomeAccountRail,
  HomeCardFrame,
  HomeCardSkeleton,
  HomeMetricGrid,
  HomeMetricPill,
  ProgressRing,
  StatusRow,
  type HomeRailEntry,
} from './home-components';

const metricKeys: Record<HomeMetricKind, MessageKey> = {
  legendAttacks: 'todoLegendAttacks',
  warAttacks: 'todoWarAttacks',
  cwlAttacks: 'todoCwlAttacks',
  raidAttacks: 'todoRaidAttacks',
  clanGames: 'gameClanGames',
  seasonPass: 'gameSeasonPassShort',
  rankedAttacks: 'rankedLeagueAttacks',
  rankedDefenses: 'rankedLeagueDefenses',
  builders: 'dashboardUpgradeTrackerBuilders',
  laboratory: 'dashboardUpgradeTrackerLab',
  pets: 'dashboardUpgradeTrackerPets',
  walls: 'dashboardUpgradeTrackerWalls',
};

function Metrics({ metrics }: { metrics: readonly HomeMetricModel[] }) {
  const { t } = useI18n();
  if (metrics.length === 0) return <CaughtUp label={t('todoAllCaughtUpForNow')} />;
  return (
    <HomeMetricGrid>
      {metrics.map((metric) => (
        <HomeMetricPill key={metric.id} metric={metric} label={t(metricKeys[metric.kind])} />
      ))}
    </HomeMetricGrid>
  );
}

function TodoBody({ summary, chevron = true }: { summary: HomeTodoSummary; chevron?: boolean }) {
  return (
    <View style={styles.body}>
      <StatusRow chevron={chevron}>
        <CKText muted role="labelLarge" numberOfLines={1}>
          {summary.status}
        </CKText>
      </StatusRow>
      <Metrics metrics={summary.metrics} />
    </View>
  );
}

function MobileRailHeader({
  imageUrl,
  title,
  rail,
  trailing,
}: {
  imageUrl: string;
  title: string;
  rail: ReactNode;
  trailing?: ReactNode;
}) {
  return (
    <View style={styles.mobileHeaderBlock}>
      <View style={styles.mobileHeader}>
        <MobileWebImage imageUrl={imageUrl} style={styles.mobileHeaderImage} />
        <View style={styles.flex}>
          <CKText role="titleSmall" style={styles.heavy} numberOfLines={1}>
            {title}
          </CKText>
          <View style={styles.railGap} />
          {rail}
        </View>
        {trailing}
      </View>
    </View>
  );
}

export function HomeTodoCard({
  model,
  selectedAccountTag,
  desktop,
  actions,
  onLongPress,
  dragTestID,
}: {
  model: HomeTodoCardModel;
  selectedAccountTag?: string | null;
  desktop: boolean;
  actions: HomeDashboardActions;
  onLongPress?: () => void;
  dragTestID?: string;
}) {
  const { t } = useI18n();
  const pages = model.accounts;
  const safeSelected = homeSelectedAccountIndex(
    pages.map((page) => page.account?.tag ?? ''),
    selectedAccountTag,
  );
  const rail: HomeRailEntry[] = model.accounts.map((summary) => ({
    ...summary.account!,
    pending: summary.done < summary.total,
  }));
  const current = pages[safeSelected]!;
  const select = (index: number) => {
    const tag = pages[index]?.account?.tag;
    if (tag) actions.selectAccount?.(tag);
  };
  if (desktop) {
    return (
      <HomeCardFrame dragTestID={dragTestID} onLongPress={onLongPress} onPress={actions.openTodo}>
        <CardHeader
          imageUrl={current.account?.imageUrl ?? ImageAssets.iconBuilderPotion}
          title={current.account?.name ?? ''}
          subtitle={current.account?.subtitle ?? ''}
          size={54}
          trailing={
            <ProgressRing
              progress={current.total === 0 ? 1 : current.done / current.total}
              size={54}
              labelFontSize={15}
            />
          }
        />
        <HomeAccountRail entries={rail} selectedIndex={safeSelected} onSelect={select} />
        <TodoBody summary={current} />
      </HomeCardFrame>
    );
  }
  return (
    <HomeCardFrame dragTestID={dragTestID} onLongPress={onLongPress} onPress={actions.openTodo}>
      <MobileRailHeader
        imageUrl={ImageAssets.iconBuilderPotion}
        title={t('todoTitle')}
        rail={<HomeAccountRail entries={rail} selectedIndex={safeSelected} onSelect={select} />}
        trailing={
          <ProgressRing
            progress={current.total === 0 ? 1 : current.done / current.total}
            size={46}
            labelFontSize={13}
          />
        }
      />
      <TodoBody summary={current} />
    </HomeCardFrame>
  );
}

function rankedMetrics(account: HomeRankedAccount): HomeMetricModel[] {
  return [
    { id: 'attacks', kind: 'rankedAttacks', done: account.attacksDone, total: account.maxBattles },
    {
      id: 'defenses',
      kind: 'rankedDefenses',
      done: account.defensesDone,
      total: account.maxBattles,
    },
  ];
}

function RankedBody({
  account,
  combined,
}: {
  account?: HomeRankedAccount;
  combined?: readonly HomeRankedAccount[];
}) {
  const { t, locale } = useI18n();
  const intlLocale = toIntlLocale(locale);
  if (account) {
    return (
      <View style={styles.body}>
        <StatusRow chevron>
          <CKText muted role="labelLarge" numberOfLines={1}>
            {account.rank === null
              ? t('rankedLeagueNoGroup')
              : `${t('rankedLeagueGroupRank')} #${account.rank.toLocaleString(intlLocale)}`}
          </CKText>
          <PillSurface style={styles.trophy}>
            <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.trophyImage} />
            <CKText role="labelLarge" style={styles.heavy}>
              {account.trophies.toLocaleString(intlLocale)}
            </CKText>
          </PillSurface>
        </StatusRow>
        <Metrics metrics={rankedMetrics(account)} />
      </View>
    );
  }
  const accounts = combined ?? [];
  const incomplete = accounts.filter(
    (entry) => entry.maxBattles !== null && entry.attacksDone < entry.maxBattles,
  );
  const names = incomplete
    .slice(0, 3)
    .map((entry) => entry.name.trim())
    .filter(Boolean);
  const subject = names.length
    ? `${names.join(', ')}${incomplete.length > 3 ? `, +${incomplete.length - 3}` : ''}`
    : t('todoAccountsNumber', { number: incomplete.length });
  const known = accounts.every((entry) => entry.maxBattles !== null);
  const total = known ? accounts.reduce((sum, entry) => sum + entry.maxBattles!, 0) : null;
  return (
    <View style={styles.body}>
      <StatusRow>
        <CKText muted role="labelLarge" numberOfLines={1}>
          {incomplete.length === 0
            ? t('dashboardRankedCombinedAcrossAccounts')
            : t('dashboardRankedAccountsHaveAttacksLeft', { subject, count: incomplete.length })}
        </CKText>
      </StatusRow>
      <Metrics
        metrics={[
          {
            id: 'attacks',
            kind: 'rankedAttacks',
            done: accounts.reduce((sum, entry) => sum + entry.attacksDone, 0),
            total,
          },
          {
            id: 'defenses',
            kind: 'rankedDefenses',
            done: accounts.reduce((sum, entry) => sum + entry.defensesDone, 0),
            total,
          },
        ]}
      />
    </View>
  );
}

export function HomeRankedCard({
  model,
  selectedAccountTag,
  desktop,
  actions,
  onLongPress,
  dragTestID,
}: {
  model: HomeRankedCardModel;
  selectedAccountTag?: string | null;
  desktop: boolean;
  actions: HomeDashboardActions;
  onLongPress?: () => void;
  dragTestID?: string;
}) {
  const { t } = useI18n();
  if (model.state === 'loading') return <HomeCardSkeleton rows={1} />;
  if (model.state === 'empty' || model.accounts.length === 0)
    return (
      <HomeCardFrame dragTestID={dragTestID} onLongPress={onLongPress}>
        <CardHeader
          imageUrl={ImageAssets.shieldWithArrow}
          title={t('rankedLeagueTitle')}
          subtitle={t('dashboardRankedNoData')}
        />
      </HomeCardFrame>
    );
  const pages = model.accounts;
  const safeSelected = homeSelectedAccountIndex(
    pages.map((page) => page.tag),
    selectedAccountTag,
  );
  const rail = model.accounts.map((account) => ({
    ...account,
    pending: account.maxBattles === null ? null : account.attacksDone < account.maxBattles,
  }));
  const current = pages[safeSelected];
  const select = (index: number) => {
    const tag = pages[index]?.tag;
    if (tag) actions.selectAccount?.(tag);
  };
  if (desktop)
    return (
      <HomeCardFrame
        dragTestID={dragTestID}
        onLongPress={onLongPress}
        onPress={current ? () => actions.openRanked(current.tag) : undefined}
      >
        <CardHeader
          imageUrl={current?.tierIconUrl || ImageAssets.shieldWithArrow}
          title={current?.name ?? ''}
          subtitle={current?.subtitle ?? ''}
          size={54}
        />
        <HomeAccountRail entries={rail} selectedIndex={safeSelected} onSelect={select} />
        <RankedBody account={current} />
      </HomeCardFrame>
    );
  return (
    <HomeCardFrame
      dragTestID={dragTestID}
      onLongPress={onLongPress}
      onPress={current ? () => actions.openRanked(current.tag) : undefined}
    >
      <MobileRailHeader
        imageUrl={current?.tierIconUrl || ImageAssets.shieldWithArrow}
        title={t('rankedLeagueTitle')}
        rail={<HomeAccountRail entries={rail} selectedIndex={safeSelected} onSelect={select} />}
      />
      <RankedBody account={current} />
    </HomeCardFrame>
  );
}

export function formatHomeDuration(seconds: number): string {
  if (seconds <= 0) return 'Done';
  if (seconds >= 86400) return `${Math.floor(seconds / 86400)}d`;
  if (seconds >= 3600) return `${Math.floor(seconds / 3600)}h`;
  return `${Math.max(1, Math.min(59, Math.floor(seconds / 60)))}m`;
}

function upgradeMetrics(account: HomeUpgradeAccount): HomeMetricModel[] {
  return [
    {
      id: 'builders',
      kind: 'builders',
      done: account.activeBuilders,
      total: account.totalBuilders,
      meta: formatHomeDuration(account.builderProjectedSeconds),
    },
    {
      id: 'lab',
      kind: 'laboratory',
      done: account.labActive ? 1 : 0,
      total: account.hasLab ? 1 : 0,
      ...(!account.hasLab ? { displayValue: '-' } : {}),
      meta: formatHomeDuration(account.labProjectedSeconds),
    },
    ...(account.hasPets
      ? [
          {
            id: 'pets',
            kind: 'pets' as const,
            done: account.petsActive ? 1 : 0,
            total: 1,
            meta: formatHomeDuration(account.petProjectedSeconds),
          },
        ]
      : []),
    { id: 'walls', kind: 'walls', done: account.wallsAtMax, total: account.wallsTotal },
  ];
}

function snapshotAge(capturedAt: Date, t: ReturnType<typeof useI18n>['t'], locale: string): string {
  const minutes = Math.max(0, Math.floor((Date.now() - capturedAt.getTime()) / 60000));
  if (minutes < 1) return t('upgradeTrackerUpdatedJustNow');
  if (minutes < 60) return t('upgradeTrackerUpdatedMinutesAgo', { count: minutes });
  if (minutes < 1440)
    return t('upgradeTrackerUpdatedHoursAgo', { count: Math.floor(minutes / 60) });
  return t('upgradeTrackerUpdatedOn', {
    date: capturedAt.toLocaleString(toIntlLocale(locale)),
  });
}

export function HomeUpgradeCard({
  model,
  selectedAccountTag,
  desktop,
  actions,
  onLongPress,
  dragTestID,
}: {
  model: HomeUpgradeCardModel;
  selectedAccountTag?: string | null;
  desktop: boolean;
  actions: HomeDashboardActions;
  onLongPress?: () => void;
  dragTestID?: string;
}) {
  const { t, locale } = useI18n();
  if (model.state === 'loading') return <HomeCardSkeleton rows={2} />;
  if (
    model.state === 'empty' ||
    (model.accounts.length === 0 && model.missingAccounts.length === 0)
  )
    return (
      <HomeCardFrame dragTestID={dragTestID} onLongPress={onLongPress}>
        <CardHeader
          imageUrl={ImageAssets.builderWave}
          title={t('drawerUpgradeTracker')}
          subtitle={
            model.configuredCount > 0
              ? t('todoAccountsNumber', { number: model.configuredCount })
              : t('upgradeTrackerSubtitle')
          }
          trailing={<ProgressRing progress={0} size={46} />}
        />
        <StatusRow>
          <CKText muted role="labelLarge" numberOfLines={1}>
            {t('dashboardUpgradeTrackerNoData')}
          </CKText>
        </StatusRow>
        <Metrics
          metrics={[
            { id: 'builders', kind: 'builders', done: 0, total: null, displayValue: '-' },
            { id: 'lab', kind: 'laboratory', done: 0, total: null, displayValue: '-' },
            { id: 'pets', kind: 'pets', done: 0, total: null, displayValue: '-' },
          ]}
        />
      </HomeCardFrame>
    );
  const entries = [...model.accounts, ...model.missingAccounts];
  const pages = entries;
  const safeSelected = homeSelectedAccountIndex(
    pages.map((entry) => entry.tag),
    selectedAccountTag,
  );
  const rail = entries.map((entry) => ({
    ...entry,
    pending: 'capturedAt' in entry ? entry.needsUpdate || entry.hasActionableQueueWork : true,
  }));
  const current = pages[safeSelected];
  const select = (index: number) => {
    const tag = pages[index]?.tag;
    if (tag) actions.selectAccount?.(tag);
  };
  const renderBody = (entry: HomeUpgradeAccount | HomeAccountIdentity | undefined) => {
    if (!entry)
      return (
        <View style={styles.body}>
          <StatusRow>
            <CKText muted role="labelLarge" numberOfLines={1}>
              {model.combined.status}
            </CKText>
          </StatusRow>
          <Metrics
            metrics={[
              {
                id: 'builders',
                kind: 'builders',
                done: model.combined.activeBuilders,
                total: model.combined.totalBuilders,
                meta: formatHomeDuration(model.combined.builderProjectedSeconds),
              },
              {
                id: 'lab',
                kind: 'laboratory',
                done: model.combined.activeLabs,
                total: model.combined.totalLabs,
                ...(model.combined.totalLabs <= 0 ? { displayValue: '-' } : {}),
                meta: formatHomeDuration(model.combined.labProjectedSeconds),
              },
              ...(model.combined.totalPets > 0
                ? [
                    {
                      id: 'pets',
                      kind: 'pets' as const,
                      done: model.combined.activePets,
                      total: model.combined.totalPets,
                      meta: formatHomeDuration(model.combined.petProjectedSeconds),
                    },
                  ]
                : []),
            ]}
          />
        </View>
      );
    if (!('capturedAt' in entry))
      return (
        <StatusRow chevron>
          <CKText muted role="labelLarge">
            {t('dashboardUpgradeTrackerNoData')}
          </CKText>
        </StatusRow>
      );
    return (
      <View style={styles.body}>
        <StatusRow chevron>
          <CKText muted role="labelLarge" numberOfLines={1}>
            {snapshotAge(entry.capturedAt, t, locale)}
          </CKText>
        </StatusRow>
        <Metrics metrics={upgradeMetrics(entry)} />
      </View>
    );
  };
  const completion = (entry: HomeUpgradeAccount | HomeAccountIdentity | undefined) =>
    !entry ? model.combined.completion : 'completion' in entry ? entry.completion : 0;
  if (desktop)
    return (
      <HomeCardFrame
        dragTestID={dragTestID}
        onLongPress={onLongPress}
        onPress={current ? () => actions.openUpgradeTracker(current.tag) : undefined}
      >
        <CardHeader
          imageUrl={current?.imageUrl ?? ImageAssets.builderWave}
          title={current?.name ?? ''}
          subtitle={current?.subtitle ?? ''}
          size={54}
          trailing={<ProgressRing progress={completion(current)} size={54} labelFontSize={15} />}
        />
        <HomeAccountRail entries={rail} selectedIndex={safeSelected} onSelect={select} />
        {renderBody(current)}
      </HomeCardFrame>
    );
  return (
    <HomeCardFrame
      dragTestID={dragTestID}
      onLongPress={onLongPress}
      onPress={current ? () => actions.openUpgradeTracker(current.tag) : undefined}
    >
      <MobileRailHeader
        imageUrl={ImageAssets.builderWave}
        title={t('drawerUpgradeTracker')}
        rail={<HomeAccountRail entries={rail} selectedIndex={safeSelected} onSelect={select} />}
        trailing={<ProgressRing progress={completion(current)} size={46} labelFontSize={13} />}
      />
      {renderBody(current)}
    </HomeCardFrame>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  heavy: { fontWeight: '900' },
  body: { gap: 10 },
  mobileHeaderBlock: { gap: 6 },
  mobileHeader: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  mobileHeaderImage: { width: 46, height: 46, resizeMode: 'contain' },
  railGap: { height: 4 },
  trophy: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 7,
  },
  trophyImage: { width: 18, height: 18, resizeMode: 'contain' },
});
