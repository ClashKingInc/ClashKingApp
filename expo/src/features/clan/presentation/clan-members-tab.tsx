import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { useEffect, useMemo, useState, type ReactNode } from 'react';
import { Platform, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import {
  ArrowDownWideNarrow,
  ArrowUpNarrowWide,
  ChevronRight,
  SlidersHorizontal,
  Star,
  Users,
} from '@/ui/icons';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  ArtworkToggleButton,
  EmptyState,
  MobileWebImage,
  PillSurface,
  ResponsiveGrid,
  SelectionPicker,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { MorphFilterSheet } from '../../../ui/morph-filter-sheet';
import type { ClanMember } from '../models';
import { formatPlayerActivity } from '../../player/presentation/presentation-utils';
import type {
  ClanMemberActivity,
  ClanInfoPresentationActions,
  ClanInfoPresentationModel,
} from './clan-info-contracts';

type MemberSort =
  | 'lastObservedAt'
  | 'joinedAt'
  | 'league'
  | 'townHallLevel'
  | 'role'
  | 'donations'
  | 'donationsReceived'
  | 'builderBaseTrophies'
  | 'expLevel';

export function ClanMembersTab({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { width } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const desktop = (Platform.OS === 'web' && width >= 900) || layout.isExpanded;
  const [sort, setSort] = useState<MemberSort>('league');
  const [showSort, setShowSort] = useState(false);
  const [order, setOrder] = useState<'desc' | 'asc'>('desc');
  const [draft, setDraft] = useState({ sort, order });
  const [showTotals, setShowTotals] = useState(false);
  const [loadingPlayer, setLoadingPlayer] = useState(false);
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 30_000);
    return () => clearInterval(timer);
  }, []);
  const allMembers = model.clan.memberList;
  const activeSort = sort === 'lastObservedAt' && !model.canViewMemberActivity ? 'league' : sort;
  const members = useMemo(() => {
    const result = [...allMembers];
    result.sort((a, b) => {
      if (activeSort === 'lastObservedAt' || activeSort === 'joinedAt') {
        const left = Date.parse(model.memberActivity?.get(a.tag)?.[activeSort] ?? '');
        const right = Date.parse(model.memberActivity?.get(b.tag)?.[activeSort] ?? '');
        // Unknown dates remain last in both directions; reversing the whole
        // array would incorrectly promote missing observations to the top.
        if (!Number.isFinite(left) || !Number.isFinite(right)) {
          return Number.isFinite(left)
            ? -1
            : Number.isFinite(right)
              ? 1
              : a.tag.localeCompare(b.tag);
        }
        return (order === 'desc' ? right - left : left - right) || a.tag.localeCompare(b.tag);
      }
      return (
        compareMembers(a, b, activeSort) * (order === 'desc' ? 1 : -1) || a.tag.localeCompare(b.tag)
      );
    });
    return result;
  }, [allMembers, activeSort, order, model.memberActivity]);
  const averageTownHall = allMembers.length
    ? allMembers.reduce((sum, member) => sum + member.townHallLevel, 0) / allMembers.length
    : 0;
  const sortOptions: readonly {
    value: MemberSort;
    label: string;
    imageUrl?: string;
    icon?: ReactNode;
  }[] = [
    {
      value: 'league',
      label: `${t('gameLeague')} & ${t('gameTrophies')}`,
      icon: <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.metricImage} />,
    },
    {
      value: 'townHallLevel',
      label: t('gameTownHallLevel'),
      icon: (
        <MobileWebImage
          imageUrl={ImageAssets.townHall(Math.max(1, Math.round(averageTownHall)))}
          style={styles.metricImage}
        />
      ),
    },
    {
      value: 'role',
      label: t('generalRole'),
      icon: <MobileWebImage imageUrl={ImageAssets.clanCastle} style={styles.metricImage} />,
    },
    {
      value: 'donations',
      label: t('gameDonations'),
      icon: <MobileWebImage imageUrl={ImageAssets.donationArrow} style={styles.metricImage} />,
    },
    {
      value: 'donationsReceived',
      label: t('gameDonationsReceived'),
      icon: <MobileWebImage imageUrl={ImageAssets.receivedArrow} style={styles.metricImage} />,
    },
    {
      value: 'builderBaseTrophies',
      label: t('gameBuilderBaseTrophies'),
      icon: <MobileWebImage imageUrl={ImageAssets.builderBaseTrophy} style={styles.metricImage} />,
    },
    {
      value: 'expLevel',
      label: t('gameExpLevel'),
      icon: <MobileWebImage imageUrl={ImageAssets.xp} style={styles.metricImage} />,
    },
    {
      value: 'joinedAt',
      label: t('wikiJoined'),
      icon: <MobileWebImage imageUrl={ImageAssets.calendar} style={styles.metricImage} />,
    },
    ...(model.canViewMemberActivity
      ? [
          {
            value: 'lastObservedAt' as const,
            label: t('clanMemberLastActive'),
            icon: <MobileWebImage imageUrl={ImageAssets.calendar} style={styles.metricImage} />,
          },
        ]
      : []),
  ];
  const selectedSort = sortOptions.find((option) => option.value === activeSort)?.label ?? '';
  const openMember = async (member: ClanMember) => {
    if (actions.openPlayerTag) return actions.openPlayerTag(member.tag);
    if (loadingPlayer) return;
    setLoadingPlayer(true);
    try {
      actions.openPlayer(await actions.loadPlayer(member.tag));
    } catch {
      actions.showMessage(t('generalTryAgain'));
    } finally {
      setLoadingPlayer(false);
    }
  };
  const cards = members.map((member, index) => (
    <MemberCard
      key={member.tag}
      member={member}
      index={index + 1}
      sort={activeSort}
      linked={model.activeUserTags.has(member.tag)}
      activity={model.memberActivity?.get(member.tag)}
      now={now}
      onPress={() => void openMember(member)}
    />
  ));
  return (
    <View style={styles.tab}>
      <View style={styles.summaryRow}>
        <ArtworkToggleButton
          testID="clan-members-totals-toggle"
          active={showTotals}
          accessibilityLabel={showTotals ? t('clanMembersHideTotals') : t('clanMembersShowTotals')}
          accessibilityState={{ selected: showTotals }}
          onPress={() => setShowTotals(!showTotals)}
        >
          <View style={styles.splitIcon}>
            <View style={styles.iconHalf}>
              <MobileWebImage imageUrl={ImageAssets.townHall(18)} style={styles.splitImage} />
            </View>
            <View style={styles.iconHalf}>
              <MobileWebImage
                imageUrl={ImageAssets.getLeagueImage('Electro League 33')}
                style={[styles.splitImage, styles.rightImage]}
              />
            </View>
          </View>
        </ArtworkToggleButton>
        <View style={styles.sortControl}>
          <SelectionPicker
            options={sortOptions.map(({ value, label, icon }) => ({ key: value, label, icon }))}
            selectedKey={activeSort}
            onSelect={setSort}
            title={selectedSort}
            externallyManaged
            onOpen={() => {
              setDraft({ sort: activeSort, order });
              setShowSort(true);
            }}
          />
        </View>
      </View>
      {showTotals ? (
        <MemberBreakdown members={allMembers} averageTownHall={averageTownHall} />
      ) : null}
      {members.length === 0 ? (
        <EmptyState
          title={t('accountsNoneFound')}
          icon={<Users color={theme.onSurfaceVariant} />}
        />
      ) : desktop ? (
        <ResponsiveGrid
          minItemWidth={layout.isExpanded ? 300 : 340}
          maxColumns={layout.isExpanded ? layout.columns(300, 3) : 3}
          gap={12}
        >
          {cards}
        </ResponsiveGrid>
      ) : (
        <View style={styles.list}>{cards}</View>
      )}
      {showSort ? (
        <MorphFilterSheet
          title={t('generalFilters')}
          applyLabel={t('generalApply')}
          onClose={() => setShowSort(false)}
          onReset={() => setDraft({ sort: 'league', order: 'desc' })}
          onApply={() => {
            setSort(draft.sort);
            setOrder(draft.order);
          }}
        >
          {(open) => (
            <>
              <Pressable
                accessibilityRole="button"
                style={styles.filterRow}
                onPress={() =>
                  open({
                    title: t('calcSort'),
                    value: draft.sort,
                    options: sortOptions,
                    onChange: (value) =>
                      setDraft((current) => ({ ...current, sort: value as MemberSort })),
                  })
                }
              >
                <View style={{ width: 22, alignItems: 'center', justifyContent: 'center' }}>
                  {sortOptions.find((option) => option.value === draft.sort)?.icon ?? (
                    <SlidersHorizontal size={22} color={theme.onSurface} />
                  )}
                </View>
                <CKText style={{ flex: 1 }}>{t('calcSort')}</CKText>
                <CKText muted style={styles.filterValue}>
                  {sortOptions.find((option) => option.value === draft.sort)?.label}
                </CKText>
                <ChevronRight size={20} color={theme.onSurfaceVariant} />
              </Pressable>
              <Pressable
                accessibilityRole="button"
                style={styles.filterRow}
                onPress={() =>
                  open({
                    title: t('clanMemberSortOrder'),
                    value: draft.order,
                    options: [
                      {
                        value: 'desc',
                        label: t('clanMemberDescending'),
                        icon: <ArrowDownWideNarrow size={22} color={theme.onSurface} />,
                      },
                      {
                        value: 'asc',
                        label: t('clanMemberAscending'),
                        icon: <ArrowUpNarrowWide size={22} color={theme.onSurface} />,
                      },
                    ],
                    onChange: (value) =>
                      setDraft((current) => ({ ...current, order: value as 'asc' | 'desc' })),
                  })
                }
              >
                {draft.order === 'desc' ? (
                  <ArrowDownWideNarrow size={22} color={theme.onSurface} />
                ) : (
                  <ArrowUpNarrowWide size={22} color={theme.onSurface} />
                )}
                <CKText style={{ flex: 1 }}>{t('clanMemberSortOrder')}</CKText>
                <CKText muted style={styles.filterValue}>
                  {t(draft.order === 'desc' ? 'clanMemberDescending' : 'clanMemberAscending')}
                </CKText>
                <ChevronRight size={20} color={theme.onSurfaceVariant} />
              </Pressable>
            </>
          )}
        </MorphFilterSheet>
      ) : null}
    </View>
  );
}

function compareMembers(a: ClanMember, b: ClanMember, sort: MemberSort): number {
  if (sort === 'role') return roleWeight(b.role) - roleWeight(a.role);
  if (sort === 'townHallLevel') return b.townHallLevel - a.townHallLevel;
  if (sort === 'expLevel') return b.expLevel - a.expLevel;
  if (sort === 'builderBaseTrophies') return b.builderBaseTrophies - a.builderBaseTrophies;
  if (sort === 'donations') return b.donations - a.donations;
  if (sort === 'donationsReceived') return b.donationsReceived - a.donationsReceived;
  const league = b.league.id - a.league.id;
  return league || b.trophies - a.trophies;
}

function roleWeight(role: string): number {
  return role === 'leader' ? 4 : role === 'coLeader' ? 3 : role === 'admin' ? 2 : 1;
}

function MemberCard({
  member,
  index,
  sort,
  linked,
  activity,
  now,
  onPress,
}: {
  member: ClanMember;
  index: number;
  sort: MemberSort;
  linked: boolean;
  activity?: ClanMemberActivity;
  now: number;
  onPress: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const role =
    member.role === 'leader'
      ? t('clanRoleLeader')
      : member.role === 'coLeader'
        ? t('clanRoleCoLeader')
        : member.role === 'admin'
          ? t('clanRoleElder')
          : t('clanRoleMember');
  const seen = activity?.lastObservedAt ? Date.parse(activity.lastObservedAt) : NaN;
  const joined = activity?.joinedAt ? Date.parse(activity.joinedAt) : NaN;
  const newWindow = 24 * 60 * 60 * 1000;
  const isNew =
    (sort === 'league' || sort === 'joinedAt') &&
    Number.isFinite(joined) &&
    joined <= now &&
    now - joined < newWindow;
  const dateView = sort === 'joinedAt' || sort === 'lastObservedAt';
  const date = sort === 'joinedAt' ? joined : seen;
  const hasDate = Number.isFinite(date) && date <= now;
  const metric = memberMetric(member, sort, theme.onSurfaceVariant, locale);
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={member.name} onPress={onPress}>
      <Surface
        radius={16}
        style={[
          styles.memberCard,
          { borderColor: linked ? '#22A35AB3' : colorWithAlpha(theme.outlineVariant, 0.32) },
        ]}
      >
        <View style={styles.memberIdentity}>
          <CKText muted role="labelMedium" style={styles.index}>
            {index}
          </CKText>
          <MobileWebImage
            imageUrl={ImageAssets.townHall(member.townHallLevel)}
            style={styles.townHall}
          />
          <View style={styles.memberCopy}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
              <CKText numberOfLines={1} style={[styles.memberName, { flexShrink: 1 }]}>
                {member.name}
              </CKText>
              {isNew ? (
                <View style={styles.newPill}>
                  <CKText role="labelSmall" style={{ color: '#A7ECC4' }}>
                    {t('homeNewMarker')}
                  </CKText>
                </View>
              ) : null}
            </View>
            <CKText muted role="labelMedium">
              {role}
            </CKText>
          </View>
          <PillSurface
            style={[styles.metric, dateView && styles.dateMetric]}
            accessibilityLabel={
              dateView
                ? `${t(sort === 'joinedAt' ? 'wikiJoined' : 'clanMemberLastActive')}: ${hasDate ? formatPlayerActivity(new Date(date), t, new Date(now)) : t('clanMemberNoObservation')}`
                : undefined
            }
          >
            {dateView ? (
              <MobileWebImage imageUrl={ImageAssets.calendar} style={styles.metricImage} />
            ) : (
              metric.leading
            )}
            <CKText
              role="labelLarge"
              style={dateView ? { textAlign: 'right', flexShrink: 1 } : undefined}
            >
              {dateView
                ? hasDate
                  ? formatPlayerActivity(new Date(date), t, new Date(now))
                  : t('clanMemberNoObservation')
                : metric.value}
            </CKText>
          </PillSurface>
        </View>
      </Surface>
    </Pressable>
  );
}

function memberMetric(
  member: ClanMember,
  sort: MemberSort,
  iconColor: string,
  locale: string,
): { leading: ReactNode; value: string } {
  if (sort === 'expLevel')
    return {
      leading: <MobileWebImage imageUrl={ImageAssets.xp} style={styles.metricImage} />,
      value: `${member.expLevel}`,
    };
  if (sort === 'builderBaseTrophies')
    return {
      leading: (
        <MobileWebImage imageUrl={ImageAssets.builderBaseTrophy} style={styles.metricImage} />
      ),
      value: `${member.builderBaseTrophies}`,
    };
  if (sort === 'donations')
    return {
      leading: <MobileWebImage imageUrl={ImageAssets.donationArrow} style={styles.metricImage} />,
      value: member.donations.toLocaleString(toIntlLocale(locale)),
    };
  if (sort === 'donationsReceived')
    return {
      leading: <MobileWebImage imageUrl={ImageAssets.receivedArrow} style={styles.metricImage} />,
      value: member.donationsReceived.toLocaleString(toIntlLocale(locale)),
    };
  if (sort === 'role')
    return { leading: <Star size={18} color={iconColor} />, value: `${member.trophies}` };
  return {
    leading: (
      <MobileWebImage
        imageUrl={ImageAssets.getLeagueImage(member.league.name)}
        style={styles.metricImage}
      />
    ),
    value: `${member.trophies}`,
  };
}

function MemberBreakdown({
  members,
  averageTownHall,
}: {
  members: readonly ClanMember[];
  averageTownHall: number;
}) {
  const { t } = useI18n();
  const townHalls = countBy(members, (member) => member.townHallLevel).sort((a, b) => b[0] - a[0]);
  const leagues = countBy(members, (member) => member.league.id).sort((a, b) => b[0] - a[0]);
  const leagueById = new Map(members.map((member) => [member.league.id, member.league]));
  return (
    <Surface radius={16} style={styles.breakdown}>
      <View style={styles.breakdownRow}>
        {leagues.map(([id, count]) => (
          <Breakdown
            key={id}
            image={ImageAssets.getLeagueImage(leagueById.get(id)?.name ?? 'Unranked')}
            count={count}
          />
        ))}
      </View>
      <View style={styles.breakdownRow}>
        <View style={styles.breakdownAverage}>
          <CKText role="labelLarge">{averageTownHall ? averageTownHall.toFixed(1) : '—'}</CKText>
          <CKText muted role="labelSmall">
            {t('clanMembersAverageTh')}
          </CKText>
        </View>
        {townHalls.map(([level, count]) => (
          <Breakdown key={level} image={ImageAssets.townHall(level)} count={count} />
        ))}
      </View>
    </Surface>
  );
}
function countBy(
  items: readonly ClanMember[],
  key: (member: ClanMember) => number,
): [number, number][] {
  const counts = new Map<number, number>();
  items.forEach((item) => counts.set(key(item), (counts.get(key(item)) ?? 0) + 1));
  return Array.from(counts.entries());
}
function Breakdown({ image, count }: { image: string; count: number }) {
  return (
    <View style={styles.breakdownCount}>
      <MobileWebImage imageUrl={image} style={styles.breakdownImage} />
      <CKText role="labelLarge">{count}</CKText>
    </View>
  );
}

const styles = StyleSheet.create({
  tab: { padding: 16, gap: 8 },
  summaryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
  },
  sortControl: { flexShrink: 1, maxWidth: 260 },
  filterRow: { flexDirection: 'row', alignItems: 'center', minHeight: 62, gap: 10 },
  filterValue: { maxWidth: '48%', textAlign: 'right' },
  memberIdentity: { flexDirection: 'row', alignItems: 'center' },
  dateMetric: { maxWidth: '45%', flexShrink: 1 },
  newPill: {
    borderRadius: 7,
    backgroundColor: '#1B613D',
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  splitIcon: { width: 32, height: 32, flexDirection: 'row' },
  iconHalf: { width: 16, height: 32, overflow: 'hidden' },
  splitImage: { width: 32, height: 32 },
  rightImage: { marginLeft: -16 },
  list: { gap: 6 },
  memberCard: {
    minHeight: 58,
    paddingHorizontal: 12,
    paddingVertical: 11,
    borderWidth: 1,
  },
  index: { width: 19, fontWeight: '800' },
  townHall: { width: 38, height: 38, marginLeft: 7, resizeMode: 'contain' },
  memberCopy: { flex: 1, marginLeft: 9 },
  memberName: { fontWeight: '800' },
  metric: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 6,
  },
  metricImage: { width: 18, height: 18, resizeMode: 'contain' },
  breakdown: { padding: 12, gap: 10 },
  breakdownRow: { flexDirection: 'row', justifyContent: 'center', flexWrap: 'wrap', gap: 12 },
  breakdownCount: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  breakdownAverage: { alignItems: 'center', justifyContent: 'center' },
  breakdownImage: { width: 24, height: 24, resizeMode: 'contain' },
  overlay: {
    flex: 1,
    backgroundColor: '#00000066',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  loading: { width: 280, padding: 24, alignItems: 'center', gap: 12 },
});
