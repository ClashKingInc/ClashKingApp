import { type ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Plus } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n, type MessageKey } from '../../../i18n';
import {
  CKText,
  MobileWebImage,
  SkeletonContent,
  ckColors,
  statColors,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
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
  HomeAccountBar,
  HomeCardFrame,
  HomeMetricGrid,
  HomeMetricPill,
  ProgressRing,
  StatusRow,
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

function HomeWidgetHeader({
  imageUrl,
  title,
  trailing,
  account,
  showClan = true,
}: {
  imageUrl: string;
  title: string;
  trailing?: ReactNode;
  account?: HomeAccountIdentity;
  showClan?: boolean;
}) {
  return (
    <View style={styles.mobileHeader}>
      <View>
        <MobileWebImage imageUrl={imageUrl} style={{ width: 36, height: 36 }} />
      </View>
      <View style={styles.flex}>
        <CKText role="titleSmall" numberOfLines={1}>
          {title}
        </CKText>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
          {account?.imageUrl ? (
            <MobileWebImage imageUrl={account.imageUrl} style={{ width: 20, height: 20 }} />
          ) : null}
          <CKText muted role="labelMedium" numberOfLines={1} style={{ flexShrink: 1 }}>
            {account?.name}
          </CKText>
          {showClan && account?.clanBadgeUrl ? (
            <MobileWebImage imageUrl={account.clanBadgeUrl} style={{ width: 14, height: 14 }} />
          ) : null}
          {showClan && account?.clanName ? (
            <CKText muted role="labelSmall" numberOfLines={1} style={{ flexShrink: 1 }}>
              {account.clanName}
            </CKText>
          ) : null}
        </View>
      </View>
      {trailing}
    </View>
  );
}

export function HomeTodoCard({
  model,
  selectedAccountTag,
  actions,
}: {
  model: HomeTodoCardModel;
  selectedAccountTag?: string | null;
  desktop: boolean;
  actions: HomeDashboardActions;
}) {
  const { t } = useI18n();
  const pages = model.accounts;
  const safeSelected = homeSelectedAccountIndex(
    pages.map((page) => page.account?.tag ?? ''),
    selectedAccountTag,
  );

  const current = pages[safeSelected]!;
  return (
    <HomeCardFrame
      onPress={actions.openTodo}
      actionLabel={t('todoTitle')}
      footer={
        pages.length > 1 ? (
          <HomeAccountBar
            entries={pages.flatMap((page) => (page.account ? [page.account] : []))}
            selectedIndex={safeSelected}
            onSelect={(index) => {
              const tag = pages[index]?.account?.tag;
              if (tag) actions.selectAccount?.(tag);
            }}
          />
        ) : null
      }
      header={
        <HomeWidgetHeader
          imageUrl={ImageAssets.todoTarget}
          title={t('todoTitle')}
          account={current.account ?? undefined}
          trailing={
            <ProgressRing
              progress={current.total === 0 ? 1 : current.done / current.total}
              size={46}
              labelFontSize={13}
            />
          }
        />
      }
    >
      <TodoBody summary={current} />
    </HomeCardFrame>
  );
}

function rankedMetrics(account: HomeRankedAccount): HomeMetricModel[] {
  return [
    {
      id: 'attacks',
      kind: 'rankedAttacks',
      done: account.attacksDone,
      total: account.maxBattles,
      ...(!account.statsAvailable ? { displayValue: '—' } : {}),
    },
    {
      id: 'defenses',
      kind: 'rankedDefenses',
      done: account.defensesDone,
      total: account.maxBattles,
      ...(!account.statsAvailable ? { displayValue: '—' } : {}),
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
  const { t } = useI18n();
  if (account) {
    return (
      <View style={styles.body}>
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
  actions,
}: {
  model: HomeRankedCardModel;
  selectedAccountTag?: string | null;
  desktop: boolean;
  actions: HomeDashboardActions;
}) {
  const { t } = useI18n();
  if (model.state === 'loading')
    return (
      <HomePendingCard
        kind="ranked"
        identities={model.identities}
        count={model.configuredCount}
        actions={actions}
      />
    );
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
  const pages = model.accounts;
  const safeSelected = homeSelectedAccountIndex(
    pages.map((page) => page.tag),
    selectedAccountTag,
  );
  const current = pages[safeSelected];
  return (
    <HomeCardFrame
      footer={
        pages.length > 1 ? (
          <HomeAccountBar
            entries={pages}
            selectedIndex={safeSelected}
            onSelect={(index) => {
              const tag = pages[index]?.tag;
              if (tag) actions.selectAccount?.(tag);
            }}
          />
        ) : null
      }
    >
      {[current!].map((account) => (
        <Pressable
          key={account.tag}
          accessibilityRole="button"
          accessibilityLabel={`${account.name}, ${t('rankedLeagueTitle')}`}
          onPress={() => actions.openRanked(account.tag)}
          style={{ gap: 12, paddingVertical: 4 }}
        >
          <CardHeader
            imageUrl={account.tierIconUrl || ImageAssets.shieldWithArrow}
            cornerImageUrl={account.imageUrl}
            title={account.name}
            subtitle={
              account.mode === 'legend'
                ? account.rank
                  ? `${t('cwlRankTitle')} #${account.rank}`
                  : undefined
                : account.rank !== null
                  ? `${t('cwlRankTitle')} #${account.rank} / ${account.groupSize}`
                  : `${account.tierName} · ${t('rankedLeagueNoGroup')}`
            }
            subtitleColor={
              account.rankZone === 'promotion'
                ? statColors.win
                : account.rankZone === 'demotion'
                  ? statColors.loss
                  : undefined
            }
            size={40}
            cornerSize={20}
            compact
            trailing={<RankedPlacement account={account} />}
          />
          <RankedBody account={account} />
        </Pressable>
      ))}
    </HomeCardFrame>
  );
}

function RankedPlacement({ account }: { account: HomeRankedAccount }) {
  const { locale } = useI18n();
  return (
    <View style={{ alignItems: 'flex-end', gap: 3 }}>
      <View style={styles.trophy}>
        <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.trophyImage} />
        <CKText role="titleMedium" style={styles.heavy}>
          {account.trophies.toLocaleString(toIntlLocale(locale))}
        </CKText>
      </View>
    </View>
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
  const days = Math.floor(minutes / 1440);
  return t('warWidgetLastUpdated', {
    time: days === 1 ? t('timeDayAgo', { day: 1 }) : t('timeDaysAgo', { days }),
  });
}

export function HomeUpgradeCard({
  model,
  selectedAccountTag,
  actions,
}: {
  model: HomeUpgradeCardModel;
  selectedAccountTag?: string | null;
  desktop: boolean;
  actions: HomeDashboardActions;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  if (model.state === 'loading')
    return (
      <HomePendingCard
        kind="upgrade"
        identities={model.identities}
        count={model.configuredCount}
        actions={actions}
      />
    );
  const entries = model.state === 'ready' ? [...model.accounts, ...model.missingAccounts] : [];
  const pages = entries;
  const safeSelected = homeSelectedAccountIndex(
    pages.map((entry) => entry.tag),
    selectedAccountTag,
  );
  const current = pages[safeSelected];
  const renderBody = (entry: HomeUpgradeAccount | HomeAccountIdentity | undefined) => {
    // Missing snapshots must keep the same two-row grid as loaded accounts.
    // Unknown is not zero: retain the real icons but never invent progress.
    if (!entry || !('capturedAt' in entry))
      return (
        <View style={styles.body}>
          <StatusRow chevron>
            <CKText muted role="labelLarge" numberOfLines={1}>
              {t('dashboardUpgradeTrackerNoData')}
            </CKText>
          </StatusRow>
          <Metrics
            metrics={[
              { id: 'builders', kind: 'builders', done: 0, total: null, displayValue: '—' },
              { id: 'lab', kind: 'laboratory', done: 0, total: null, displayValue: '—' },
              { id: 'pets', kind: 'pets', done: 0, total: null, displayValue: '—' },
              { id: 'walls', kind: 'walls', done: 0, total: null, displayValue: '—' },
            ]}
          />
        </View>
      );
    return (
      <View style={styles.body}>
        <StatusRow chevron>
          <CKText
            muted={!entry.needsUpdate}
            role="labelLarge"
            numberOfLines={1}
            style={entry.needsUpdate ? { color: ckColors.warGold } : undefined}
          >
            {entry.needsUpdate ? t('widgetDataStale') : snapshotAge(entry.capturedAt, t, locale)}
          </CKText>
        </StatusRow>
        <Metrics metrics={upgradeMetrics(entry)} />
      </View>
    );
  };
  const completion = (entry: HomeUpgradeAccount | HomeAccountIdentity | undefined) =>
    entry && 'completion' in entry ? entry.completion : 0;
  const importAction = actions.openUpgradeImport ? (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={t('upgradeTrackerImportTitle')}
      onPress={(event) => {
        event.stopPropagation();
        actions.openUpgradeImport?.(current?.tag ?? selectedAccountTag ?? '');
      }}
      style={{
        width: 44,
        height: 44,
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: 22,
        backgroundColor: colorWithAlpha(ckColors.builderBlue, 0.12),
      }}
    >
      <Plus size={21} color={theme.onSurface} />
    </Pressable>
  ) : null;
  return (
    <HomeCardFrame
      onPress={() => actions.openUpgradeTracker(current?.tag ?? selectedAccountTag ?? '')}
      actionLabel={t('drawerUpgradeTracker')}
      footer={
        pages.length > 1 ? (
          <HomeAccountBar
            entries={pages}
            selectedIndex={safeSelected}
            onSelect={(index) => {
              const tag = pages[index]?.tag;
              if (tag) actions.selectAccount?.(tag);
            }}
          />
        ) : null
      }
      header={
        <HomeWidgetHeader
          imageUrl={ImageAssets.builderWave}
          title={t('drawerUpgradeTracker')}
          account={current}
          showClan={false}
          trailing={
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
              {importAction}
              <ProgressRing
                progress={completion(current)}
                size={42}
                labelFontSize={12}
                label={current && 'capturedAt' in current ? undefined : '—'}
              />
            </View>
          }
        />
      }
    >
      {renderBody(current)}
    </HomeCardFrame>
  );
}

/** Presentation-only models let the same cards reserve their actual geometry.
 * These never enter a store and the scope blocks all navigation/actions. */
export function HomePendingCard({
  kind,
  identities,
  count = 1,
  actions,
}: {
  kind: 'todo' | 'ranked' | 'upgrade';
  identities?: readonly HomeAccountIdentity[];
  count?: number;
  actions: HomeDashboardActions;
}) {
  const { t } = useI18n();
  const entries = identities?.length
    ? identities
    : Array.from({ length: Math.max(1, count) }, (_, index) => ({
        tag: `pending-${index}`,
        name: t('generalLoading'),
        subtitle: '',
        imageUrl: '',
      }));
  const card =
    kind === 'ranked' ? (
      <HomeRankedCard
        desktop={false}
        actions={actions}
        model={{
          state: 'ready',
          configuredCount: count,
          accounts: entries.map((entry) => ({
            ...entry,
            mode: 'ranked',
            statsAvailable: false,
            tierColor: '',
            tierIconUrl: '',
            groupSize: 50,
            trophies: 1000,
            rank: 10,
            attacksDone: 0,
            defensesDone: 0,
            maxBattles: 24,
          })),
        }}
      />
    ) : kind === 'upgrade' ? (
      <HomeUpgradeCard
        desktop={false}
        actions={actions}
        model={{
          state: 'ready',
          configuredCount: count,
          accounts: entries.map((entry) => ({
            ...entry,
            completion: 0,
            capturedAt: new Date(0),
            needsUpdate: false,
            hasActionableQueueWork: false,
            builderProjectedSeconds: 3600,
            labProjectedSeconds: 3600,
            petProjectedSeconds: 3600,
            activeBuilders: 0,
            totalBuilders: 6,
            labActive: false,
            hasLab: true,
            petsActive: false,
            hasPets: true,
            wallsAtMax: 0,
            wallsTotal: 300,
          })),
          missingAccounts: [],
          combined: {
            completion: 0,
            status: '',
            builderProjectedSeconds: 0,
            labProjectedSeconds: 0,
            petProjectedSeconds: 0,
            activeBuilders: 0,
            totalBuilders: 6,
            activeLabs: 0,
            totalLabs: 1,
            activePets: 0,
            totalPets: 1,
          },
        }}
      />
    ) : (
      <HomeTodoCard
        desktop={false}
        actions={actions}
        model={{
          accounts: entries.map((account) => ({
            account,
            status: t('generalLoading'),
            done: 0,
            total: 2,
            metrics: [
              { id: 'games', kind: 'clanGames', done: 0, total: 4000 },
              { id: 'pass', kind: 'seasonPass', done: 0, total: 2000 },
            ],
          })),
        }}
      />
    );
  return <SkeletonContent>{card}</SkeletonContent>;
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  heavy: { fontWeight: '900' },
  body: { gap: 10 },
  mobileHeaderBlock: { gap: 6 },
  mobileHeader: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  mobileHeaderTrailing: { alignItems: 'center', justifyContent: 'center' },
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
