import type { ScrollViewInstance } from 'react-native';
import { memo, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { Animated, Linking, Platform, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { ChevronDown, ChevronUp, Clock3, ListFilter } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import {
  CKText,
  ClashHandoffDialog,
  EmptyState,
  MobileWebImage,
  Surface,
  SkeletonContent,
  colorWithAlpha,
  useCKTheme,
  ProfileTabs,
  SelectionPicker,
} from '../../../ui';
import { useCKAccessibility } from '../../../ui/accessibility';
import { PagerView, type PagerViewHandle } from '../../../ui/pager';
import { usePrimarySwipeGuard } from '../../../ui/primary-swipe-guard';
import { ckColors } from '../../../ui/tokens';
import { clanGameUrl } from '../../clan/presentation/clan-root-state';
import type { WarAttack, WarInfo, WarMember } from '../models';
import { buildWarReplay, type WarReplayEvent } from '../models/war-replay';
import type { WarPresentationActions } from './contracts';
import { formatPercent } from './presentation-utils';
import { AttackDetailsModal } from './war-components';
import { WarBattleHeader } from './war-battle-header';
import { WarScouting } from './war-scouting';
import { WarAttackCard, WarResultStars } from './war-attack-card';
import { WarHistoryPanel } from './war-history-panel';
import { loadingWar } from './war-loading-model';

const WAR_PAGES = ['players', 'recent', 'details'] as const;
type WarPage = (typeof WAR_PAGES)[number];

type Props = {
  loading?: boolean;
  war: WarInfo;
  linkedPlayerTags?: readonly string[];
  cwlRoundNumber?: number | null;
  actions: WarPresentationActions;
  onBack: () => void;
  onOpenCwl?: () => void;
};
export function WarDetailScreen(props: Props) {
  // Another war must not inherit a selected player or clan perspective.
  return (
    <WarDetailContent
      key={[props.war.tag, props.war.startTime?.toISOString(), props.war.clan?.tag].join(':')}
      {...props}
    />
  );
}
function WarDetailContent({
  loading = false,
  war: actualWar,
  linkedPlayerTags = [],
  cwlRoundNumber,
  actions,
  onBack,
  onOpenCwl,
}: Props) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const [mode, setMode] = useState<WarPage>('players');
  const [settledPage, setSettledPage] = useState<WarPage>('players');
  const [bodyReady, setBodyReady] = useState(false);
  useEffect(() => {
    if (loading) return;
    let timer: ReturnType<typeof setTimeout> | undefined;
    // The native route push runs after commit. Keep its first render small so
    // a 50-player roster and replay cannot postpone the navigation itself.
    const frame = requestAnimationFrame(() => {
      timer = setTimeout(() => setBodyReady(true), 0);
    });
    return () => {
      cancelAnimationFrame(frame);
      if (timer !== undefined) clearTimeout(timer);
    };
  }, [loading]);
  const bodyLoading = loading || !bodyReady;
  const war = useMemo(
    () =>
      loading || bodyReady
        ? actualWar
        : loadingWar(actualWar.clan?.tag ?? '', actualWar.clan?.name),
    [actualWar, bodyReady, loading],
  );
  const { reduceMotion } = useCKAccessibility();
  const pager = useRef<PagerViewHandle>(null);
  const scroll = useRef<ScrollViewInstance>(null);
  const scrollY = useRef(0),
    headerHeight = useRef(0),
    tabStart = useRef(0);
  const [tabPosition] = useState(() => new Animated.Value(0));
  const [pageHeights, setPageHeights] = useState<Partial<Record<WarPage, number>>>({});
  const blockPrimarySwipe = usePrimarySwipeGuard();
  useEffect(() => () => blockPrimarySwipe(false), [blockPrimarySwipe]);
  useEffect(() => {
    const frame = requestAnimationFrame(() =>
      scroll.current?.scrollTo({ y: tabStart.current, animated: false }),
    );
    return () => cancelAnimationFrame(frame);
  }, [mode]);
  const selectPage = (page: WarPage) => {
    tabStart.current = Math.max(0, Math.min(scrollY.current, headerHeight.current));
    setMode(page);
  };
  const [side, setSide] = useState<'clan' | 'opponent'>('clan');
  const [expanded, setExpanded] = useState<string>();
  const [selected, setSelected] = useState<WarAttack | null>(null);
  const [playerFilter, setPlayerFilter] = useState<'all' | 'remaining' | 'one'>('all');
  const [eventFilter, setEventFilter] = useState<'all' | 'attacks' | 'defenses'>('all');
  const [handoffUrl, setHandoffUrl] = useState<string>();
  const history = useMemo(() => buildWarReplay(war), [war]);
  // History is read-only: changing tabs or filters never rewinds the live score.
  const events = history.events;
  const members = [...(war[side]?.members ?? [])].sort((a, b) => a.mapPosition - b.mapPosition);
  // A short archive is not evidence of missed attacks. Only infer unused
  // attacks when the full roster's recorded hits agree with the clan total.
  const attacksKnown =
    members.length === war.teamSize &&
    members.reduce((total, member) => total + (member.attacks?.length ?? 0), 0) ===
      war[side]?.attacks;
  const filteredMembers = members.filter((member) => {
    if (playerFilter === 'all' || !attacksKnown) return true;
    const remaining = Math.max(0, war.effectiveAttacksPerMember - (member.attacks?.length ?? 0));
    return playerFilter === 'one' ? remaining === 1 : remaining > 0;
  });
  const filteredEvents = [...events]
    .reverse()
    .filter(
      (event) =>
        eventFilter === 'all' ||
        (eventFilter === 'attacks' ? event.side === 'clan' : event.side !== 'clan'),
    );
  const linked = useMemo(() => new Set(linkedPlayerTags), [linkedPlayerTags]);
  const openClan = (tag: string) => {
    if (Platform.OS !== 'web' && ['preparation', 'inWar', 'warInWar'].includes(actualWar.state))
      setHandoffUrl(clanGameUrl(tag, locale));
    else actions.openClan(tag);
  };
  const renderPage = (page: WarPage) => (
    <SkeletonContent
      loading={bodyLoading}
      style={styles.content}
      onLayout={(event) => {
        const height = Math.ceil(event.nativeEvent.layout.height);
        if (height > 0)
          setPageHeights((old) => (old[page] === height ? old : { ...old, [page]: height }));
      }}
    >
      {history.events.length < (war.clan?.attacks ?? 0) + (war.opponent?.attacks ?? 0) ? (
        <CKText role="metadata" muted>
          {t('homeActivityRecorded')}
        </CKText>
      ) : null}
      {page === 'players' ? (
        <>
          <View
            testID="war-player-controls"
            style={{
              flexDirection: 'row',
              flexWrap: 'wrap',
              gap: 8,
              alignItems: 'center',
              minHeight: 44,
              flexShrink: 0,
            }}
          >
            <View style={{ flex: 1, minWidth: 150 }}>
              <SelectionPicker
                fillWidth
                wrapLabel
                title={t('warPlayersTitle')}
                selectedKey={side}
                onSelect={(value) => {
                  setSide(value);
                  setExpanded(undefined);
                }}
                options={(['clan', 'opponent'] as const).map((key) => ({
                  key,
                  label: war[key]?.name ?? '—',
                  icon: (
                    <MobileWebImage
                      imageUrl={war[key]?.badgeUrls.smallest ?? ImageAssets.clanCastle}
                      style={styles.smallBadge}
                    />
                  ),
                }))}
              />
            </View>
            {attacksKnown ? (
              <View style={{ minWidth: 125, maxWidth: 190 }}>
                <SelectionPicker
                  fillWidth
                  title={t('generalFilters')}
                  selectedKey={playerFilter}
                  onSelect={setPlayerFilter}
                  options={[
                    { key: 'all', label: t('generalAll') },
                    {
                      key: 'remaining',
                      label: t(
                        war.state === 'warEnded' ? 'warAttacksMissedShort' : 'generalRemaining',
                      ),
                    },
                    {
                      key: 'one',
                      label:
                        war.state === 'warEnded'
                          ? t('warStatusMissedInfo', { number: 1 })
                          : t('warAnalysisRemainingAttempts', { attacks: 1 }),
                    },
                  ]}
                />
              </View>
            ) : null}
          </View>
          {filteredMembers.length ? (
            filteredMembers.map((member) => (
              <PlayerWarCard
                key={member.tag}
                member={member}
                war={war}
                events={events}
                attacksKnown={attacksKnown}
                linked={linked.has(member.tag)}
                expanded={expanded === member.tag}
                onToggle={() =>
                  setExpanded((value) => (value === member.tag ? undefined : member.tag))
                }
                onAttack={setSelected}
                onOpenPlayer={actions.openPlayer}
              />
            ))
          ) : (
            <EmptyState title={t('generalNoDataAvailable')} />
          )}
        </>
      ) : page === 'recent' ? (
        <>
          <View style={{ alignItems: 'flex-end' }}>
            <SelectionPicker
              title={t('generalFilters')}
              selectedKey={eventFilter}
              onSelect={setEventFilter}
              options={[
                { key: 'all', label: t('generalAll') },
                { key: 'attacks', label: t('warAttacksTitle') },
                { key: 'defenses', label: t('warDefensesTitle') },
              ]}
            />
          </View>
          {filteredEvents.length ? (
            filteredEvents.map((event) => (
              <WarEventCard
                key={[event.side, event.attack.order, event.attack.attackerTag].join(':')}
                event={event}
                attacking={event.side === 'clan'}
              />
            ))
          ) : (
            <EmptyState title={t('generalNoDataAvailable')} />
          )}
        </>
      ) : (
        <>
          <WarHistoryPanel history={history} teamSize={war.teamSize ?? 0} />
          <WarComposition war={war} onOpenClan={openClan} />
        </>
      )}
      {page === 'details' ? (
        <WarScouting war={war} actions={actions} enabled={!bodyLoading && mode === 'details'} />
      ) : null}
    </SkeletonContent>
  );
  return (
    <SafeAreaView
      testID="war-detail"
      edges={['left', 'right']}
      style={{ flex: 1, backgroundColor: theme.background }}
    >
      <ScrollView
        ref={scroll}
        onScroll={(event) => {
          scrollY.current = event.nativeEvent.contentOffset.y;
        }}
        scrollEventThrottle={100}
        stickyHeaderIndices={[1]}
        contentInsetAdjustmentBehavior="never"
        automaticallyAdjustContentInsets={false}
        contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}
      >
        <View
          onLayout={(event) => {
            headerHeight.current = event.nativeEvent.layout.height;
          }}
        >
          <WarBattleHeader
            loading={loading}
            war={actualWar}
            cwlRoundNumber={cwlRoundNumber}
            onBack={onBack}
            onOpenClan={openClan}
            onOpenCwl={onOpenCwl}
          />
        </View>
        <View style={{ backgroundColor: theme.background }}>
          <ProfileTabs
            variant="underline"
            selectedKey={mode}
            animatedPosition={tabPosition}
            indicatorRtl={isRtl}
            onSelect={(value) => {
              selectPage(value as WarPage);
              const index = WAR_PAGES.indexOf(value as WarPage);
              if (reduceMotion) {
                setSettledPage(value as WarPage);
                pager.current?.setPageWithoutAnimation(index);
                tabPosition.setValue(index);
              } else pager.current?.setPage(index);
            }}
            tabs={[
              {
                key: 'players',
                label: t('warPlayersTitle'),
                icon: <MobileWebImage imageUrl={ImageAssets.sword} style={styles.icon} />,
              },
              {
                key: 'recent',
                label: t('searchRecent'),
                icon: <Clock3 size={20} color={theme.onSurface} />,
              },
              {
                key: 'details',
                label: t('generalDetails'),
                icon: <ListFilter size={20} color={theme.onSurface} />,
              },
            ]}
          />
        </View>
        <View
          onTouchStart={() => blockPrimarySwipe(true)}
          onTouchEnd={() => blockPrimarySwipe(false)}
          onTouchCancel={() => blockPrimarySwipe(false)}
        >
          <PagerView
            ref={pager}
            initialPage={0}
            layoutDirection={isRtl ? 'rtl' : 'ltr'}
            testID="war-detail-pager"
            style={{ height: Math.max(pageHeights[mode] ?? 600, pageHeights[settledPage] ?? 600) }}
            onPageScroll={(event) =>
              tabPosition.setValue(event.nativeEvent.position + event.nativeEvent.offset)
            }
            onPageSelected={(event) => {
              const page = WAR_PAGES[event.nativeEvent.position]!;
              selectPage(page);
              setSettledPage(page);
            }}
          >
            {WAR_PAGES.map((page) => (
              <View
                key={page}
                testID={'war-page-' + page}
                collapsable={false}
                style={{ flex: 1 }}
                aria-hidden={page !== mode}
                accessibilityElementsHidden={page !== mode}
                importantForAccessibility={page !== mode ? 'no-hide-descendants' : 'auto'}
              >
                {renderPage(page)}
              </View>
            ))}
          </PagerView>
        </View>
      </ScrollView>
      <AttackDetailsModal
        visible={selected !== null}
        attack={selected}
        war={war}
        onClose={() => setSelected(null)}
        onOpenPlayer={actions.openPlayer}
      />
      <ClashHandoffDialog
        visible={handoffUrl !== undefined}
        onCancel={() => setHandoffUrl(undefined)}
        onConfirm={() => {
          const url = handoffUrl;
          setHandoffUrl(undefined);
          if (url) void Linking.openURL(url);
        }}
      />
    </SafeAreaView>
  );
}

const PlayerWarCard = memo(function PlayerWarCard({
  member,
  war,
  events,
  linked,
  attacksKnown,
  expanded,
  onToggle,
  onAttack,
  onOpenPlayer,
}: {
  member: WarMember;
  war: WarInfo;
  events: readonly WarReplayEvent[];
  linked: boolean;
  attacksKnown: boolean;
  expanded: boolean;
  onToggle: () => void;
  onAttack: (attack: WarAttack) => void;
  onOpenPlayer: (tag: string) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const outgoing = member.attacks ?? [];
  const incoming = events
    .filter((event) => event.attack.defenderTag === member.tag)
    .map((event) => event.attack);
  const fallback = !incoming.length && member.bestOpponentAttack;
  const defenses = fallback ? [fallback] : incoming;
  const remaining = Math.max(0, war.effectiveAttacksPerMember - outgoing.length);
  return (
    <Surface
      testID={'war-player-' + member.tag}
      style={[
        styles.playerCard,
        linked && { backgroundColor: colorWithAlpha(ckColors.donationGreen, 0.09) },
      ]}
    >
      <View style={styles.playerHeading}>
        <Pressable
          onPress={() => onOpenPlayer(member.tag)}
          accessibilityRole="button"
          accessibilityLabel={member.name}
          style={styles.playerIcon}
        >
          <MobileWebImage
            imageUrl={ImageAssets.townHall(member.townhallLevel)}
            style={styles.townHall}
          />
          <CKText role="labelSmall" muted>
            #{member.mapPosition}
          </CKText>
        </Pressable>
        <Pressable
          onPress={onToggle}
          accessibilityRole="button"
          accessibilityState={{ expanded }}
          style={[styles.nameRow, styles.grow, { minHeight: 60 }]}
        >
          <View style={styles.grow}>
            <CKText role="rowTitle">{member.name}</CKText>
            <View style={[styles.nameRow, { marginTop: 5 }]}>
              <MobileWebImage imageUrl={ImageAssets.sword} style={styles.smallIcon} />
              <CKText role="metadata" muted>
                {outgoing.length}/{war.effectiveAttacksPerMember}
              </CKText>
              {attacksKnown && remaining > 0 && war.state === 'warEnded' ? (
                <CKText role="metadata" style={{ color: ckColors.lossRed }}>
                  {t('warStatusMissedInfo', { number: remaining })}
                </CKText>
              ) : null}
            </View>
          </View>
          <View style={styles.attackSummary}>
            {outgoing.map((hit) => (
              <View key={hit.order} style={styles.summaryHit}>
                <WarResultStars stars={hit.stars} />
                <CKText role="labelSmall" style={{ fontSize: 12, lineHeight: 16 }} muted>
                  {formatPercent(hit.destructionPercentage, 0)}
                </CKText>
              </View>
            ))}
          </View>
          {expanded ? (
            <ChevronUp size={18} color={theme.onSurfaceVariant} />
          ) : (
            <ChevronDown size={18} color={theme.onSurfaceVariant} />
          )}
        </Pressable>
      </View>
      {expanded ? (
        <Reveal>
          <View style={styles.playerLogs}>
            <CKText skeleton={false} role="rowTitle">
              {t('warAttacksTitle')}
            </CKText>
            {outgoing.map((hit) => (
              <AttackRow
                key={hit.order}
                attack={hit}
                target={war.getMemberByTag(hit.defenderTag)}
                onPress={() => onAttack(hit)}
              />
            ))}
            {!attacksKnown ? (
              <CKText role="metadata" muted>
                {t('homeActivityRecorded')}
              </CKText>
            ) : remaining ? (
              <CKText
                role="metadata"
                style={{
                  color: war.state === 'warEnded' ? ckColors.lossRed : theme.onSurfaceVariant,
                }}
              >
                {war.state === 'warEnded'
                  ? t('warStatusMissedInfo', { number: remaining })
                  : t('warAnalysisRemainingAttempts', { attacks: remaining })}
              </CKText>
            ) : null}
            <CKText role="rowTitle" style={{ marginTop: 10 }}>
              {fallback
                ? t('warDefensesBestOutOf', { number: member.opponentAttacks })
                : t('warDefensesTitle')}
            </CKText>
            {defenses.length ? (
              defenses.map((hit) => (
                <AttackRow
                  key={hit.order}
                  attack={hit}
                  target={war.getMemberByTag(hit.attackerTag)}
                  onPress={() => onAttack(hit)}
                />
              ))
            ) : (
              <CKText role="metadata" muted>
                {t('warDefensesNone')}
              </CKText>
            )}
            {!fallback && incoming.length < member.opponentAttacks ? (
              <CKText role="metadata" muted>
                {t('homeActivityRecorded')}
              </CKText>
            ) : null}
          </View>
        </Reveal>
      ) : null}
    </Surface>
  );
});
function AttackRow({
  attack,
  target,
  onPress,
}: {
  attack: WarAttack;
  target: WarMember | null;
  onPress: () => void;
}) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.attackRow}>
      <MobileWebImage
        imageUrl={
          target?.townhallLevel
            ? ImageAssets.townHall(target.townhallLevel)
            : ImageAssets.defaultImage
        }
        style={styles.tinyTownHall}
      />
      <CKText role="metadata" style={styles.grow}>
        {target ? '#' + target.mapPosition + ' ' + target.name : '—'}
      </CKText>
      <View style={styles.resultColumn}>
        <WarResultStars stars={attack.stars} compact />
        <CKText role="metadata" muted>
          {formatPercent(attack.destructionPercentage)}
        </CKText>
      </View>
    </Pressable>
  );
}
function Reveal({ children }: { children: ReactNode }) {
  const { reduceMotion } = useCKAccessibility();
  const [opacity] = useState(() => new Animated.Value(reduceMotion ? 1 : 0));
  useEffect(() => {
    const animation = Animated.timing(opacity, {
      toValue: 1,
      duration: reduceMotion ? 0 : 160,
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [opacity, reduceMotion]);
  return <Animated.View style={{ opacity }}>{children}</Animated.View>;
}
function WarComposition({ war, onOpenClan }: { war: WarInfo; onOpenClan: (tag: string) => void }) {
  const { t } = useI18n();
  const levels = [
    ...new Set(
      [...(war.clan?.members ?? []), ...(war.opponent?.members ?? [])].map(
        (member) => member.townhallLevel,
      ),
    ),
  ].sort((a, b) => b - a);
  return (
    <Surface style={{ padding: 16, gap: 12, borderWidth: 0 }}>
      <View style={styles.nameRow}>
        {(['clan', 'opponent'] as const).map((key) => (
          <Pressable
            key={key}
            accessibilityRole="button"
            onPress={() => war[key] && onOpenClan(war[key]!.tag)}
            style={{ flex: 1, alignItems: 'center', minHeight: 44, justifyContent: 'center' }}
          >
            <CKText
              role="metadata"
              style={{
                textAlign: 'center',
                color: key === 'clan' ? ckColors.donationGreen : ckColors.primaryRed,
              }}
            >
              {war[key]?.name}
            </CKText>
          </Pressable>
        ))}
      </View>
      {levels.length ? (
        levels.map((level) => {
          const left =
            war.clan?.members.filter((member) => member.townhallLevel === level).length ?? 0;
          const right =
            war.opponent?.members.filter((member) => member.townhallLevel === level).length ?? 0;
          return (
            <View key={level} style={styles.nameRow}>
              <CKText style={{ width: 25, textAlign: 'center' }}>{left}</CKText>
              <View style={{ flex: 1, alignItems: 'flex-end' }}>
                <View
                  style={{
                    height: 7,
                    borderRadius: 4,
                    width: `${(left / Math.max(1, war.teamSize ?? 1)) * 100}%`,
                    backgroundColor: ckColors.donationGreen,
                  }}
                />
              </View>
              <MobileWebImage
                imageUrl={ImageAssets.townHall(level)}
                style={{ width: 36, height: 36 }}
              />
              <View style={{ flex: 1 }}>
                <View
                  style={{
                    height: 7,
                    borderRadius: 4,
                    width: `${(right / Math.max(1, war.teamSize ?? 1)) * 100}%`,
                    backgroundColor: ckColors.primaryRed,
                  }}
                />
              </View>
              <CKText style={{ width: 25, textAlign: 'center' }}>{right}</CKText>
            </View>
          );
        })
      ) : (
        <CKText muted>{t('generalNoDataAvailable')}</CKText>
      )}
    </Surface>
  );
}
function WarEventCard({ event, attacking }: { event: WarReplayEvent; attacking: boolean }) {
  return (
    <WarAttackCard
      testID={'war-event-' + event.attack.order}
      attack={event.attack}
      attacker={event.attacker}
      defender={event.defender}
      attacking={attacking}
    />
  );
}
export { WarResultStars } from './war-attack-card';
const styles = StyleSheet.create({
  grow: { flex: 1, minWidth: 0 },
  content: {
    flexShrink: 0,
    width: '100%',
    maxWidth: 840,
    alignSelf: 'center',
    paddingHorizontal: 16,
    paddingTop: 8,
    gap: 12,
  },
  smallBadge: { width: 26, height: 26 },
  icon: { width: 23, height: 23 },
  smallIcon: { width: 13, height: 13 },
  playerCard: { borderWidth: 0, paddingHorizontal: 12, paddingVertical: 6 },
  playerHeading: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  playerIcon: { width: 44, minHeight: 60, alignItems: 'center', justifyContent: 'center' },
  townHall: { width: 40, height: 40 },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  attackSummary: { gap: 4 },
  summaryHit: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  playerLogs: { gap: 6, paddingHorizontal: 4, paddingBottom: 12, paddingTop: 8 },
  attackRow: { minHeight: 44, flexDirection: 'row', gap: 8, alignItems: 'center' },
  tinyTownHall: { width: 24, height: 24 },
  stars: { flexDirection: 'row', gap: 1 },
  resultColumn: { alignItems: 'flex-end', gap: 4 },
  eventSurface: { borderWidth: 0, borderRadius: 22 },
});
