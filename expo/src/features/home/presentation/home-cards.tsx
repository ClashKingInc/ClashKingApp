import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import {
  ScrollView,
  StyleSheet,
  View,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
} from 'react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n, type MessageKey } from '../../../i18n';
import { CKText, MobileWebImage, PillSurface } from '../../../ui';
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
  DesktopComparison,
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

export function clampHomePageIndex(selected: number, pageCount: number): number {
  return Math.max(0, Math.min(selected, Math.max(0, pageCount - 1)));
}

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

function MobilePager({
  selected,
  onSelect,
  children,
}: {
  selected: number;
  onSelect: (index: number) => void;
  children: readonly ReactNode[];
}) {
  const ref = useRef<ScrollView>(null);
  const { isRtl } = useI18n();
  const [width, setWidth] = useState(0);
  useEffect(() => {
    if (width > 0) ref.current?.scrollTo({ x: selected * width, animated: true });
  }, [selected, width]);
  const finish = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    if (width > 0) onSelect(Math.round(event.nativeEvent.contentOffset.x / width));
  };
  return (
    <View onLayout={(event) => setWidth(event.nativeEvent.layout.width)}>
      <ScrollView
        ref={ref}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        onMomentumScrollEnd={finish}
        style={isRtl ? styles.rtlScroll : undefined}
      >
        {children.map((child, index) => (
          <View key={index} style={[{ width: width || 1 }, isRtl && styles.rtlItem]}>
            {child}
          </View>
        ))}
      </ScrollView>
    </View>
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
  );
}

export function HomeTodoCard({
  model,
  desktop,
  actions,
}: {
  model: HomeTodoCardModel;
  desktop: boolean;
  actions: HomeDashboardActions;
}) {
  const { t } = useI18n();
  const hasSummary = model.accounts.length > 1 && model.combined !== undefined;
  const pages = useMemo(
    () => (hasSummary ? [model.combined!, ...model.accounts] : [...model.accounts]),
    [hasSummary, model],
  );
  const [selected, setSelected] = useState(0);
  const safeSelected = clampHomePageIndex(selected, pages.length);
  if (desktop) {
    return (
      <DesktopComparison
        items={pages.map((page, index) => page.account?.tag ?? `summary-${index}`)}
        summaryFirst={hasSummary}
        renderItem={(index) => {
          const page = pages[index]!;
          return (
            <HomeCardFrame onPress={actions.openTodo}>
              <CardHeader
                imageUrl={page.account?.imageUrl ?? ImageAssets.iconBuilderPotion}
                title={page.account?.name ?? t('todoAllAccounts')}
                subtitle={
                  page.account?.subtitle ??
                  t('todoAccountsNumber', { number: model.accounts.length })
                }
                size={54}
                trailing={
                  <ProgressRing
                    progress={page.total === 0 ? 1 : page.done / page.total}
                    size={54}
                  />
                }
              />
              <TodoBody summary={page} />
            </HomeCardFrame>
          );
        }}
      />
    );
  }
  const rail: HomeRailEntry[] = model.accounts.map((summary) => ({
    ...summary.account!,
    pending: summary.done < summary.total,
  }));
  const current = pages[safeSelected]!;
  return (
    <HomeCardFrame onPress={actions.openTodo}>
      <MobileRailHeader
        imageUrl={ImageAssets.iconBuilderPotion}
        title={t('todoTitle')}
        rail={
          <HomeAccountRail
            entries={rail}
            selectedIndex={safeSelected}
            onSelect={setSelected}
            allLabel={hasSummary ? t('todoAllAccounts') : undefined}
          />
        }
        trailing={
          <ProgressRing
            progress={current.total === 0 ? 1 : current.done / current.total}
            size={46}
          />
        }
      />
      <MobilePager selected={safeSelected} onSelect={setSelected}>
        {pages.map((page) => (
          <TodoBody key={page.account?.tag ?? 'all'} summary={page} />
        ))}
      </MobilePager>
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
  desktop,
  actions,
}: {
  model: HomeRankedCardModel;
  desktop: boolean;
  actions: HomeDashboardActions;
}) {
  const { t } = useI18n();
  const [selected, setSelected] = useState(0);
  if (model.state === 'loading') return <HomeCardSkeleton rows={1} />;
  if (model.state === 'empty' || model.accounts.length === 0)
    return (
      <HomeCardFrame>
        <CardHeader
          imageUrl={ImageAssets.shieldWithArrow}
          title={t('rankedLeagueTitle')}
          subtitle={t('dashboardRankedNoData')}
        />
      </HomeCardFrame>
    );
  const hasSummary = model.accounts.length > 1;
  const pages: (HomeRankedAccount | undefined)[] = hasSummary
    ? [undefined, ...model.accounts]
    : [...model.accounts];
  const safeSelected = clampHomePageIndex(selected, pages.length);
  if (desktop)
    return (
      <DesktopComparison
        items={pages.map((page, index) => page?.tag ?? `summary-${index}`)}
        summaryFirst={hasSummary}
        renderItem={(index) => {
          const account = pages[index];
          return (
            <HomeCardFrame onPress={account ? () => actions.openRanked(account.tag) : undefined}>
              <CardHeader
                imageUrl={account?.tierIconUrl || ImageAssets.shieldWithArrow}
                title={account?.name ?? t('todoAllAccounts')}
                subtitle={
                  account?.subtitle ?? t('todoAccountsNumber', { number: model.accounts.length })
                }
                size={54}
              />
              <RankedBody account={account} combined={account ? undefined : model.accounts} />
            </HomeCardFrame>
          );
        }}
      />
    );
  const rail = model.accounts.map((account) => ({
    ...account,
    pending: account.maxBattles === null ? null : account.attacksDone < account.maxBattles,
  }));
  const current = pages[safeSelected];
  return (
    <HomeCardFrame onPress={current ? () => actions.openRanked(current.tag) : undefined}>
      <MobileRailHeader
        imageUrl={current?.tierIconUrl || ImageAssets.shieldWithArrow}
        title={t('rankedLeagueTitle')}
        rail={
          <HomeAccountRail
            entries={rail}
            selectedIndex={safeSelected}
            onSelect={setSelected}
            allLabel={hasSummary ? t('todoAllAccounts') : undefined}
          />
        }
      />
      <MobilePager selected={safeSelected} onSelect={setSelected}>
        {pages.map((account, index) => (
          <RankedBody
            key={account?.tag ?? `all-${index}`}
            account={account}
            combined={account ? undefined : model.accounts}
          />
        ))}
      </MobilePager>
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
  desktop,
  actions,
}: {
  model: HomeUpgradeCardModel;
  desktop: boolean;
  actions: HomeDashboardActions;
}) {
  const { t, locale } = useI18n();
  const [selected, setSelected] = useState(0);
  if (model.state === 'loading') return <HomeCardSkeleton rows={2} />;
  if (
    model.state === 'empty' ||
    (model.accounts.length === 0 && model.missingAccounts.length === 0)
  )
    return (
      <HomeCardFrame>
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
  const hasSummary = entries.length > 1;
  const pages: (HomeUpgradeAccount | HomeAccountIdentity | undefined)[] = hasSummary
    ? [undefined, ...entries]
    : entries;
  const safeSelected = clampHomePageIndex(selected, pages.length);
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
      <DesktopComparison
        items={pages.map((page, index) => page?.tag ?? `summary-${index}`)}
        summaryFirst={hasSummary}
        renderItem={(index) => {
          const entry = pages[index];
          return (
            <HomeCardFrame
              onPress={entry ? () => actions.openUpgradeTracker(entry.tag) : undefined}
            >
              <CardHeader
                imageUrl={entry?.imageUrl ?? ImageAssets.builderWave}
                title={entry?.name ?? t('todoAllAccounts')}
                subtitle={entry?.subtitle ?? t('todoAccountsNumber', { number: entries.length })}
                size={54}
                trailing={<ProgressRing progress={completion(entry)} size={54} />}
              />
              {renderBody(entry)}
            </HomeCardFrame>
          );
        }}
      />
    );
  const rail = entries.map((entry) => ({
    ...entry,
    pending: 'capturedAt' in entry ? entry.needsUpdate || entry.hasActionableQueueWork : true,
  }));
  const current = pages[safeSelected];
  return (
    <HomeCardFrame onPress={current ? () => actions.openUpgradeTracker(current.tag) : undefined}>
      <MobileRailHeader
        imageUrl={ImageAssets.builderWave}
        title={t('drawerUpgradeTracker')}
        rail={
          <HomeAccountRail
            entries={rail}
            selectedIndex={safeSelected}
            onSelect={setSelected}
            allLabel={hasSummary ? t('todoAllAccounts') : undefined}
          />
        }
        trailing={<ProgressRing progress={completion(current)} size={46} />}
      />
      <MobilePager selected={safeSelected} onSelect={setSelected}>
        {pages.map((entry, index) => (
          <View key={entry?.tag ?? `all-${index}`}>{renderBody(entry)}</View>
        ))}
      </MobilePager>
    </HomeCardFrame>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  heavy: { fontWeight: '900' },
  body: { gap: 10 },
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
  rtlScroll: { transform: [{ scaleX: -1 }] },
  rtlItem: { transform: [{ scaleX: -1 }] },
});
