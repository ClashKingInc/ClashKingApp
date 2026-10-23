import { modalOrientations } from "../../../ui/modal-orientations";
import { useMemo, useState, type ReactNode } from 'react';
import { Modal, Platform, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { ArrowDown, ArrowUp, BarChart3, Star, Users } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  MobileWebImage,
  PillSurface,
  ResponsiveGrid,
  SelectionPicker,
  SelectionPickerModal,
  Skeleton,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { ClanMember } from '../models';
import type { ClanInfoPresentationActions, ClanInfoPresentationModel } from './clan-info-contracts';

type MemberSort =
  | 'league'
  | 'townHallLevel'
  | 'role'
  | 'donations'
  | 'donationsReceived'
  | 'donationsRatio'
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
  const desktop = Platform.OS === 'web' && width >= 900;
  const [sort, setSort] = useState<MemberSort>('league');
  const [showSort, setShowSort] = useState(false);
  const [showTotals, setShowTotals] = useState(false);
  const [loadingPlayer, setLoadingPlayer] = useState(false);
  const allMembers = model.clan.memberList;
  const members = useMemo(() => {
    const result = [...allMembers];
    result.sort((a, b) => compareMembers(a, b, sort));
    return result;
  }, [allMembers, sort]);
  const sortOptions: readonly { value: MemberSort; label: string }[] = [
    { value: 'league', label: `${t('gameLeague')} & ${t('gameTrophies')}` },
    { value: 'townHallLevel', label: t('gameTownHallLevel') },
    { value: 'role', label: t('generalRole') },
    { value: 'donations', label: t('gameDonations') },
    { value: 'donationsReceived', label: t('gameDonationsReceived') },
    { value: 'donationsRatio', label: t('gameDonationsRatio') },
    { value: 'builderBaseTrophies', label: t('gameBuilderBaseTrophies') },
    { value: 'expLevel', label: t('gameExpLevel') },
  ];
  const selectedSort = sortOptions.find((option) => option.value === sort)?.label ?? '';
  const averageTownHall = allMembers.length
    ? allMembers.reduce((sum, member) => sum + member.townHallLevel, 0) / allMembers.length
    : 0;
  const openMember = async (member: ClanMember) => {
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
      sort={sort}
      linked={model.activeUserTags.has(member.tag)}
      onPress={() => void openMember(member)}
    />
  ));
  return (
    <View style={styles.tab}>
      <View style={styles.summaryRow}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={showTotals ? t('clanMembersHideTotals') : t('clanMembersShowTotals')}
          accessibilityState={{ selected: showTotals }}
          onPress={() => setShowTotals(!showTotals)}
          style={[
            styles.statsToggle,
            {
              borderColor: colorWithAlpha(showTotals ? theme.primary : theme.outlineVariant, 0.42),
            },
          ]}
        >
          <BarChart3 size={23} color={showTotals ? theme.primary : theme.onSurfaceVariant} />
        </Pressable>
        <View style={styles.sortControl}>
          <SelectionPicker
            options={sortOptions.map(({ value, label }) => ({ key: value, label }))}
            selectedKey={sort}
            onSelect={setSort}
            title={selectedSort}
            externallyManaged
            onOpen={() => setShowSort(true)}
          />
        </View>
      </View>
      {showTotals ? <MemberBreakdown members={allMembers} averageTownHall={averageTownHall} /> : null}
      {members.length === 0 ? (
        <EmptyState
          title={t('accountsNoneFound')}
          icon={<Users color={theme.onSurfaceVariant} />}
        />
      ) : desktop ? (
        <ResponsiveGrid minItemWidth={340} maxColumns={3} gap={10}>
          {cards}
        </ResponsiveGrid>
      ) : (
        <View style={styles.list}>{cards}</View>
      )}
      <SelectionPickerModal
        visible={showSort}
        title={selectedSort}
        options={sortOptions.map((option) => ({
          key: option.value,
          label: option.label,
          icon: (
            <MobileWebImage
              imageUrl={
                option.value === 'townHallLevel'
                  ? ImageAssets.townHall(Math.max(1, Math.round(averageTownHall)))
                  : option.value === 'expLevel'
                    ? ImageAssets.xp
                    : option.value === 'builderBaseTrophies'
                      ? ImageAssets.builderBaseTrophy
                      : option.value === 'role'
                        ? ImageAssets.clanCastle
                        : option.value === 'league'
                          ? ImageAssets.trophies
                          : ImageAssets.clanCastle
              }
              style={styles.metricImage}
            />
          ),
        }))}
        selectedKey={sort}
        onSelect={(value) => {
          setSort(value);
          setShowSort(false);
        }}
        onClose={() => setShowSort(false)}
      />
      <Modal supportedOrientations={modalOrientations}
        transparent
        visible={loadingPlayer}
        animationType="fade"
        onRequestClose={() => undefined}
      >
        <View style={styles.overlay}>
          <Surface radius={ckRadius.tile} style={styles.loading}>
            <Skeleton width={48} height={48} radius={24} />
            <Skeleton width={180} />
            <Skeleton width={120} height={12} />
          </Surface>
        </View>
      </Modal>
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
  if (sort === 'donationsRatio') return donationRatio(b) - donationRatio(a);
  const league = b.league.id - a.league.id;
  return league || b.trophies - a.trophies;
}

function roleWeight(role: string): number {
  return role === 'leader' ? 4 : role === 'coLeader' ? 3 : role === 'admin' ? 2 : 1;
}
function donationRatio(member: ClanMember): number {
  return member.donations / (member.donationsReceived || 1);
}

function MemberCard({
  member,
  index,
  sort,
  linked,
  onPress,
}: {
  member: ClanMember;
  index: number;
  sort: MemberSort;
  linked: boolean;
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
        <CKText muted role="labelMedium" style={styles.index}>
          {index}
        </CKText>
        <MobileWebImage
          imageUrl={ImageAssets.townHall(member.townHallLevel)}
          style={styles.townHall}
        />
        <View style={styles.memberCopy}>
          <CKText numberOfLines={1} style={styles.memberName}>
            {member.name}
          </CKText>
          <CKText muted role="labelMedium">
            {role}
          </CKText>
        </View>
        <PillSurface style={styles.metric}>
          {metric.leading}
          <CKText role="labelLarge">{metric.value}</CKText>
        </PillSurface>
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
      leading: <ArrowUp size={18} color="#22A35A" />,
      value: member.donations.toLocaleString(toIntlLocale(locale)),
    };
  if (sort === 'donationsReceived')
    return {
      leading: <ArrowDown size={18} color="#E35D4F" />,
      value: member.donationsReceived.toLocaleString(toIntlLocale(locale)),
    };
  if (sort === 'donationsRatio') {
    const ratio = donationRatio(member);
    return {
      leading: <ArrowUp size={18} color={iconColor} />,
      value:
        ratio > 100 ? `${Math.trunc(ratio)}` : ratio > 10 ? ratio.toFixed(1) : ratio.toFixed(2),
    };
  }
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

function MemberBreakdown({ members, averageTownHall }: {
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
          <CKText muted role="labelSmall">{t('clanMembersAverageTh')}</CKText>
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
  summaryRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 8 },
  sortControl: { flexShrink: 1, maxWidth: 260 },
  statsToggle: {
    width: 44,
    height: 44,
    flexShrink: 0,
    borderWidth: 1,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  list: { gap: 6 },
  memberCard: {
    minHeight: 58,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 7,
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
