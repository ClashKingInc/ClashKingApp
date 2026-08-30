import { useMemo, useState } from 'react';
import {
  Linking,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  ArrowDownUp,
  Calculator,
  ChevronDown,
  ListFilter,
  Search,
  Sword,
  Users,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import {
  CKText,
  ClashHandoffDialog,
  GlassSurface,
  EmptyState,
  MobileWebImage,
  PillSurface,
  ProfileTabs,
  SearchSortBar,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { WarAttack, WarInfo, WarMember } from '../models';
import { clanGameUrl } from '../../clan/presentation/clan-root-state';
import type { WarPresentationActions } from './contracts';
import {
  analyzeWarState,
  buildWarEvents,
  calculateFastWarResult,
  filterWarMembers,
  formatPercent,
  warComparisonStats,
  type WarMemberFilter,
} from './presentation-utils';
import { AttackDetailsModal, SectionPanel, SelectionModal, WarHero } from './war-components';

type WarTab = 'statistics' | 'events' | 'team';

export function WarDetailScreen({
  war,
  linkedPlayerTags = [],
  cwlRoundNumber,
  actions,
  onBack,
  onOpenCwl,
}: {
  war: WarInfo;
  linkedPlayerTags?: readonly string[];
  cwlRoundNumber?: number | null;
  actions: WarPresentationActions;
  onBack: () => void;
  onOpenCwl?: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const [tab, setTab] = useState<WarTab>('statistics');
  const [handoffUrl, setHandoffUrl] = useState<string>();
  const openClan = (tag: string) => {
    if (
      Platform.OS !== 'web' &&
      (war.state === 'preparation' || war.state === 'inWar' || war.state === 'warInWar')
    ) {
      setHandoffUrl(clanGameUrl(tag, locale));
      return;
    }
    actions.openClan(tag);
  };
  const tabs = [
    {
      key: 'statistics',
      label: t('navigationStatistics'),
      icon: (
        <ArrowDownUp
          size={18}
          color={tab === 'statistics' ? theme.primary : theme.onSurfaceVariant}
        />
      ),
    },
    {
      key: 'events',
      label: t('warEventsTitle'),
      icon: <Sword size={18} color={tab === 'events' ? theme.primary : theme.onSurfaceVariant} />,
    },
    {
      key: 'team',
      label: t('navigationTeam'),
      icon: <Users size={18} color={tab === 'team' ? theme.primary : theme.onSurfaceVariant} />,
    },
  ];
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      <ScrollView contentContainerStyle={{ paddingBottom: insets.bottom + 18 }}>
        <WarHero
          war={war}
          cwlRoundNumber={cwlRoundNumber}
          onBack={onBack}
          onOpenClan={openClan}
          onCopy={(tag) =>
            void actions
              .copyText(tag)
              .then(() => actions.showMessage(t('generalCopiedToClipboard')))
          }
          onOpenCwl={onOpenCwl}
        />
        <View style={styles.tabs}>
          <ProfileTabs tabs={tabs} selectedKey={tab} onSelect={(key) => setTab(key as WarTab)} />
        </View>
        <View style={styles.content}>
          {tab === 'statistics' ? <WarStatistics war={war} /> : null}
          {tab === 'events' ? (
            <WarEvents
              war={war}
              linkedPlayerTags={linkedPlayerTags}
              onOpenPlayer={actions.openPlayer}
            />
          ) : null}
          {tab === 'team' ? <WarTeam war={war} onOpenPlayer={actions.openPlayer} /> : null}
        </View>
      </ScrollView>
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

function WarStatistics({ war }: { war: WarInfo }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { width } = useWindowDimensions();
  const [showCalculator, setShowCalculator] = useState(false);
  const stats = useMemo(() => warComparisonStats(war), [war]);
  const analysis = useMemo(() => analyzeWarState(war), [war]);
  if (!war.clan || !war.opponent) return <EmptyState title={t('generalNoDataAvailable')} />;
  const teamSize = war.teamSize ?? 15;
  const maxStars = teamSize * 3;
  const capacity = teamSize * war.effectiveAttacksPerMember;
  const progress = (value: number) => Math.min(1, capacity ? value / capacity : 0);
  return (
    <View style={styles.stack}>
      <View style={styles.calculatorActionRow}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('warCalculatorFast')}
          accessibilityState={{ selected: showCalculator }}
          onPress={() => setShowCalculator((current) => !current)}
        >
          <GlassSurface
            interactive
            cornerRadius={18}
            style={[styles.calculatorButton, width < 360 && styles.calculatorButtonCompact]}
          >
            {width >= 360 ? (
              <CKText role="labelMedium" numberOfLines={1} style={styles.grow}>
                {t('warCalculatorFast')}
              </CKText>
            ) : null}
            <Calculator size={20} color={theme.onSurfaceVariant} />
          </GlassSurface>
        </Pressable>
      </View>
      {showCalculator ? <WarCalculator war={war} initiallyExpanded /> : null}
      <SectionPanel title={t('navigationStatistics')}>
        <ComparisonMetric
          label={t('warStarsTitle')}
          left={`${war.clan.stars}/${maxStars}`}
          right={`${war.opponent.stars}/${maxStars}`}
          leftProgress={maxStars ? war.clan.stars / maxStars : 0}
          rightProgress={maxStars ? war.opponent.stars / maxStars : 0}
          image={ImageAssets.attackStar}
          leftColor={war.clan.stars >= war.opponent.stars ? '#2EAD70' : theme.error}
          rightColor={war.opponent.stars >= war.clan.stars ? '#2EAD70' : theme.error}
        />
        <ComparisonMetric
          label={t('warDestructionRate')}
          left={formatPercent(war.clan.destructionPercentage)}
          right={formatPercent(war.opponent.destructionPercentage)}
          leftProgress={war.clan.destructionPercentage / 100}
          rightProgress={war.opponent.destructionPercentage / 100}
          symbol="%"
          leftColor={
            war.clan.destructionPercentage >= war.opponent.destructionPercentage
              ? '#2EAD70'
              : theme.error
          }
          rightColor={
            war.opponent.destructionPercentage >= war.clan.destructionPercentage
              ? '#2EAD70'
              : theme.error
          }
        />
        <ComparisonMetric
          label={t('warAttacksTitle')}
          left={`${war.clan.attacks}/${capacity}`}
          right={`${war.opponent.attacks}/${capacity}`}
          leftProgress={progress(war.clan.attacks)}
          rightProgress={progress(war.opponent.attacks)}
          image={ImageAssets.sword}
          leftColor="#2EAD70"
          rightColor={theme.error}
        />
      </SectionPanel>
      <SectionPanel title={t('warStarsNumber')}>
        {[3, 2, 1, 0].map((stars) => (
          <ComparisonRow
            key={stars}
            label={`${'★'.repeat(stars)}${'☆'.repeat(3 - stars)}`}
            left={String(stats.clanStarCounts[stars] ?? 0)}
            right={String(stats.opponentStarCounts[stars] ?? 0)}
          />
        ))}
      </SectionPanel>
      {analysis ? <WarAnalysisPanel analysis={analysis} clanName={war.clan.name} /> : null}
    </View>
  );
}

type WarEventFilter = 'all' | 'clan' | 'opponent' | '3' | '2' | '1' | '0';

function WarEvents({
  war,
  linkedPlayerTags,
  onOpenPlayer,
}: {
  war: WarInfo;
  linkedPlayerTags: readonly string[];
  onOpenPlayer: (tag: string) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState<WarEventFilter>('all');
  const [filterOpen, setFilterOpen] = useState(false);
  const [selected, setSelected] = useState<WarAttack | null>(null);
  const events = useMemo(
    () =>
      buildWarEvents(war, {
        query,
        stars: /^[0-3]$/.test(filter) ? Number(filter) : null,
        side: filter === 'clan' || filter === 'opponent' ? filter : null,
      }),
    [filter, query, war],
  );
  const options: readonly { key: WarEventFilter; label: string }[] = [
    { key: 'all', label: t('generalAll') },
    { key: 'clan', label: war.clan?.name ?? t('clanTitle') },
    { key: 'opponent', label: war.opponent?.name ?? t('capitalOpponentsSection') },
    { key: '3', label: '★★★' },
    { key: '2', label: '★★☆' },
    { key: '1', label: '★☆☆' },
    { key: '0', label: '☆☆☆' },
  ];
  const linked = new Set(linkedPlayerTags);
  return (
    <View style={styles.stack}>
      <SearchSortBar
        value={query}
        onChangeText={setQuery}
        placeholder={t('playerSearchPlaceholder')}
        searchIcon={<Search size={18} color={theme.onSurfaceVariant} />}
        sortLabel={t('generalFilters')}
        sortValue={options.find((option) => option.key === filter)?.label}
        sortIcon={<ListFilter size={18} color={theme.onSurface} />}
        onSortPress={() => setFilterOpen(true)}
      />
      {!events.length ? (
        <EmptyState title={t('generalNoDataAvailable')} />
      ) : (
        events.map((event) => {
          const highlighted =
            linked.has(event.attack.attackerTag) || linked.has(event.attack.defenderTag);
          return (
            <Pressable
              key={`${event.attack.order}:${event.attack.attackerTag}`}
              accessibilityRole="button"
              accessibilityLabel={`${event.attacker?.name} ${event.attack.stars} stars`}
              onPress={() => setSelected(event.attack)}
            >
              <Surface
                style={[
                  styles.eventRow,
                  highlighted && {
                    borderColor: colorWithAlpha('#D6A633', 0.48),
                    backgroundColor: colorWithAlpha('#D6A633', 0.07),
                  },
                ]}
              >
                <View style={styles.orderBadge}>
                  <CKText role="labelLarge">#{event.attack.order}</CKText>
                </View>
                <MemberMini member={event.attacker} />
                <View style={styles.eventResult}>
                  <CKText role="titleMedium">
                    {'★'.repeat(event.attack.stars)}
                    {'☆'.repeat(3 - event.attack.stars)}
                  </CKText>
                  <CKText muted role="labelSmall">
                    {formatPercent(event.attack.destructionPercentage)}
                  </CKText>
                </View>
                <MemberMini member={event.defender} align="right" />
              </Surface>
            </Pressable>
          );
        })
      )}
      <SelectionModal
        visible={filterOpen}
        title={t('generalFilters')}
        options={options}
        selected={filter}
        onSelect={setFilter}
        onClose={() => setFilterOpen(false)}
      />
      <AttackDetailsModal
        visible={selected !== null}
        attack={selected}
        war={war}
        onClose={() => setSelected(null)}
        onOpenPlayer={onOpenPlayer}
      />
    </View>
  );
}

function WarTeam({ war, onOpenPlayer }: { war: WarInfo; onOpenPlayer: (tag: string) => void }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [side, setSide] = useState<'clan' | 'opponent'>('clan');
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState<WarMemberFilter>('all');
  const [filterOpen, setFilterOpen] = useState(false);
  const [selected, setSelected] = useState<WarAttack | null>(null);
  const members = useMemo(
    () =>
      filterWarMembers(
        side === 'clan' ? (war.clan?.members ?? []) : (war.opponent?.members ?? []),
        filter,
        query,
      ),
    [filter, query, side, war],
  );
  const options = warFilterOptions(t);
  return (
    <View style={styles.stack}>
      <View style={styles.segment}>
        {(['clan', 'opponent'] as const).map((value) => (
          <Pressable
            key={value}
            accessibilityRole="tab"
            accessibilityState={{ selected: side === value }}
            onPress={() => setSide(value)}
            style={[
              styles.segmentButton,
              side === value && { backgroundColor: colorWithAlpha(theme.primary, 0.16) },
            ]}
          >
            <CKText role="labelLarge" style={side === value ? { color: theme.primary } : undefined}>
              {value === 'clan' ? war.clan?.name : war.opponent?.name}
            </CKText>
          </Pressable>
        ))}
      </View>
      <SearchSortBar
        value={query}
        onChangeText={setQuery}
        placeholder={t('playerSearchPlaceholder')}
        searchIcon={<Search size={18} color={theme.onSurfaceVariant} />}
        sortLabel={t('generalFilters')}
        sortValue={options.find((option) => option.key === filter)?.label}
        sortIcon={<ListFilter size={18} color={theme.onSurface} />}
        onSortPress={() => setFilterOpen(true)}
      />
      {!members.length ? (
        <EmptyState title={t('generalNoFilteredResults')} body={t('generalAdjustFilters')} />
      ) : (
        members.map((member) => (
          <WarMemberCard
            key={member.tag}
            member={member}
            war={war}
            attacksPerMember={war.effectiveAttacksPerMember}
            onOpenAttack={setSelected}
          />
        ))
      )}
      <SelectionModal
        visible={filterOpen}
        title={t('generalFilters')}
        options={options}
        selected={filter}
        onSelect={setFilter}
        onClose={() => setFilterOpen(false)}
      />
      <AttackDetailsModal
        visible={selected !== null}
        attack={selected}
        war={war}
        onClose={() => setSelected(null)}
        onOpenPlayer={onOpenPlayer}
      />
    </View>
  );
}

function WarMemberCard({
  member,
  war,
  attacksPerMember,
  onOpenAttack,
}: {
  member: WarMember;
  war: WarInfo;
  attacksPerMember: number;
  onOpenAttack: (attack: WarAttack) => void;
}) {
  const { t } = useI18n();
  const attacks = member.attacks ?? [];
  return (
    <Surface style={styles.memberCard}>
      <View style={styles.memberHeader}>
        <MobileWebImage
          imageUrl={ImageAssets.townHall(member.townhallLevel)}
          style={styles.thImage}
        />
        <View style={styles.grow}>
          <CKText muted role="labelSmall">
            N°{member.mapPosition}
          </CKText>
          <CKText role="rowTitle">{member.name}</CKText>
        </View>
        <View style={styles.attackCount}>
          <MobileWebImage imageUrl={ImageAssets.sword} style={styles.inlineIcon} />
          <CKText role="labelMedium">
            {attacks.length}/{attacksPerMember}
          </CKText>
        </View>
      </View>
      <View style={styles.memberColumns}>
        <View style={styles.memberColumn}>
          <ActionColumnHeader image={ImageAssets.sword} label={t('warAttacksTitle')} />
          {Array.from({ length: attacksPerMember }, (_, index) => {
            const attack = attacks[index] ?? null;
            return (
              <AttackLine
                key={attack?.order ?? `empty-${index}`}
                attack={attack}
                member={attack ? war.getMemberByTag(attack.defenderTag) : null}
                placeholderTownHall={member.townhallLevel}
                emptyLabel={t('warAttacksNone')}
                onPress={() => attack && onOpenAttack(attack)}
              />
            );
          })}
        </View>
        <View style={styles.memberColumn}>
          <ActionColumnHeader
            image={ImageAssets.shieldWithArrow}
            label={t('warDefensesBestOutOf', { number: member.opponentAttacks })}
          />
          <AttackLine
            attack={member.bestOpponentAttack}
            member={
              member.bestOpponentAttack
                ? war.getMemberByTag(member.bestOpponentAttack.attackerTag)
                : null
            }
            placeholderTownHall={member.townhallLevel}
            emptyLabel={t('warDefensesNone')}
            onPress={() => member.bestOpponentAttack && onOpenAttack(member.bestOpponentAttack)}
          />
        </View>
      </View>
    </Surface>
  );
}

function ActionColumnHeader({ image, label }: { image: string; label: string }) {
  return (
    <View style={styles.actionHeader}>
      <MobileWebImage imageUrl={image} style={styles.inlineIcon} />
      <CKText muted role="labelSmall" numberOfLines={1}>
        {label}
      </CKText>
    </View>
  );
}

function AttackLine({
  attack,
  member,
  placeholderTownHall,
  emptyLabel,
  onPress,
}: {
  attack: WarAttack | null;
  member: WarMember | null;
  placeholderTownHall: number;
  emptyLabel: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole={attack ? 'button' : undefined}
      accessibilityLabel={attack ? member?.name : emptyLabel}
      disabled={!attack}
      onPress={onPress}
      style={styles.attackLine}
    >
      <MobileWebImage
        imageUrl={ImageAssets.townHall(member?.townhallLevel ?? placeholderTownHall)}
        style={[styles.actionTownHall, !attack && styles.mutedImage]}
      />
      <View style={styles.grow}>
        <CKText role="labelMedium" numberOfLines={1} style={!attack ? styles.mutedText : undefined}>
          {attack ? `${member?.mapPosition ?? '-'}. ${member?.name ?? '—'}` : '-'}
        </CKText>
        <View style={styles.starLine}>
          {[0, 1, 2].map((index) => (
            <MobileWebImage
              key={index}
              imageUrl={
                index < (attack?.stars ?? 0) ? ImageAssets.builderBaseStar : ImageAssets.emptyStar
              }
              style={[styles.starIcon, !attack && styles.mutedImage]}
            />
          ))}
          <CKText muted role="labelSmall">
            {attack ? formatPercent(attack.destructionPercentage, 0) : '-%'}
          </CKText>
        </View>
      </View>
    </Pressable>
  );
}

function WarCalculator({
  war,
  initiallyExpanded = false,
}: {
  war: WarInfo;
  initiallyExpanded?: boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const initialPercent =
    Math.abs((war.clan?.destructionPercentage ?? 0) - (war.opponent?.destructionPercentage ?? 0)) +
    0.01;
  const [teamSize, setTeamSize] = useState(String(war.teamSize ?? 15));
  const [percentNeeded, setPercentNeeded] = useState(initialPercent.toFixed(2));
  const [expanded, setExpanded] = useState(initiallyExpanded);
  const [result, setResult] = useState(
    calculateFastWarResult(String(war.teamSize ?? 15), initialPercent.toFixed(2)),
  );
  return (
    <Surface style={styles.calculatorSheet}>
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ expanded }}
        onPress={() => setExpanded((current) => !current)}
        style={styles.calculatorHeader}
      >
        <CKText role="titleSmall" style={styles.grow}>
          {t('warCalculatorFast')}
        </CKText>
        <Calculator size={20} color={theme.onSurfaceVariant} />
        <ChevronDown
          size={20}
          color={theme.onSurfaceVariant}
          style={{ transform: [{ rotate: expanded ? '180deg' : '0deg' }] }}
        />
      </Pressable>
      {expanded ? (
        <View style={styles.calculatorBody}>
          <View style={styles.calculatorFields}>
            <View style={styles.calculatorField}>
              <CKText muted role="labelMedium">
                {t('warTeamSize')}
              </CKText>
              <View
                style={[
                  styles.numberInput,
                  { borderColor: colorWithAlpha(theme.outlineVariant, 0.5) },
                ]}
              >
                <TextInput
                  value={teamSize}
                  onChangeText={setTeamSize}
                  keyboardType="decimal-pad"
                  style={[styles.inputText, { color: theme.onSurface }]}
                />
              </View>
            </View>
            <View style={styles.calculatorField}>
              <CKText muted role="labelMedium">
                {t('warCalculatorNeededOverall')}
              </CKText>
              <View
                style={[
                  styles.numberInput,
                  { borderColor: colorWithAlpha(theme.outlineVariant, 0.5) },
                ]}
              >
                <TextInput
                  value={percentNeeded}
                  onChangeText={setPercentNeeded}
                  keyboardType="decimal-pad"
                  style={[styles.inputText, { color: theme.onSurface }]}
                />
                <CKText>%</CKText>
              </View>
            </View>
          </View>
          <Pressable
            accessibilityRole="button"
            onPress={() => setResult(calculateFastWarResult(teamSize, percentNeeded))}
            style={[
              styles.calculateButton,
              { borderColor: colorWithAlpha(theme.outlineVariant, 0.72) },
            ]}
          >
            <CKText role="labelLarge">{t('warCalculatorCalculate')}</CKText>
          </Pressable>
          <Surface muted style={styles.calculatorResult}>
            <CKText style={styles.calculatorAnswer}>
              {t('warCalculatorAnswer', { percentNeeded, result: Math.ceil(result) })}
            </CKText>
          </Surface>
        </View>
      ) : null}
    </Surface>
  );
}

function WarAnalysisPanel({
  analysis,
  clanName,
}: {
  analysis: NonNullable<ReturnType<typeof analyzeWarState>>;
  clanName: string;
}) {
  const { t, locale } = useI18n();
  const percent = (value: number) => {
    const text = value >= 10 ? value.toFixed(1) : value.toFixed(2);
    return locale.startsWith('fr') ? text.replace('.', ',') : text;
  };
  let headline = t('warOngoing');
  let summary: string | null = null;
  let objective: string | null = null;
  let badge: string | null = null;
  if (analysis.kind === 'notStarted') {
    headline = t('warNotStarted');
    summary = `${t('warAnalysisRemainingAttempts', { attacks: analysis.clanRemaining })} · ${t('warAnalysisRemainingAttempts', { attacks: analysis.opponentRemaining })}`;
  } else if (analysis.kind === 'perfectDraw') {
    headline = t('warPerfectDraw');
    summary = t('warAnalysisNoBetterResult');
  } else if (analysis.kind === 'secured') {
    headline = t('warAnalysisCannotLose', { clanName });
    badge = t('warAnalysisSecuredBadge');
    objective = t('warAnalysisAlreadySecured');
  } else {
    summary = analysis.canSecure
      ? t('warAnalysisSecureAgainst', { clanName: analysis.opponentName })
      : t('warAnalysisCannotSecureAgainst', { clanName: analysis.opponentName });
    if (!analysis.canSecure) objective = t('warAnalysisNoSecureObjective');
    else {
      const parts = [];
      if (analysis.starsGoal > 0)
        parts.push(t('warAnalysisStarGoal', { stars: analysis.starsGoal }));
      if (analysis.destructionGoal > 0) parts.push(`+${percent(analysis.destructionGoal)}%`);
      objective = parts.join(' · ') || t('warAnalysisNoSecureObjective');
    }
  }
  return (
    <SectionPanel>
      <View style={styles.analysisHeader}>
        <MobileWebImage imageUrl={ImageAssets.war} style={styles.analysisIcon} />
        <CKText role="titleMedium" style={styles.grow}>
          {t('warStateOfTheWar')}
        </CKText>
        {badge ? (
          <PillSurface>
            <CKText role="labelSmall">{badge}</CKText>
          </PillSurface>
        ) : null}
      </View>
      <CKText role="labelLarge">{headline}</CKText>
      {summary ? <CKText muted>{summary}</CKText> : null}
      {objective ? (
        <View style={styles.analysisObjective}>
          <CKText role="labelSmall">{t('warAnalysisToWin')}</CKText>
          <CKText muted>{objective}</CKText>
        </View>
      ) : null}
    </SectionPanel>
  );
}

function ComparisonRow({ label, left, right }: { label: string; left: string; right: string }) {
  return (
    <View style={styles.comparison}>
      <CKText role="titleMedium" style={styles.comparisonValue}>
        {left}
      </CKText>
      <CKText muted style={styles.comparisonLabel}>
        {label}
      </CKText>
      <CKText role="titleMedium" style={styles.comparisonValue}>
        {right}
      </CKText>
    </View>
  );
}

function ComparisonMetric({
  label,
  left,
  right,
  leftProgress,
  rightProgress,
  leftColor,
  rightColor,
  image,
  symbol,
}: {
  label: string;
  left: string;
  right: string;
  leftProgress: number;
  rightProgress: number;
  leftColor: string;
  rightColor: string;
  image?: string;
  symbol?: string;
}) {
  return (
    <View style={styles.comparisonMetric}>
      <View style={styles.comparison}>
        <CKText role="labelLarge" style={styles.comparisonValue}>
          {left}
        </CKText>
        <View style={styles.comparisonMetricLabel}>
          {image ? <MobileWebImage imageUrl={image} style={styles.comparisonIcon} /> : null}
          {symbol ? <CKText role="labelLarge">{symbol}</CKText> : null}
          <CKText muted role="labelMedium" numberOfLines={1}>
            {label}
          </CKText>
        </View>
        <CKText role="labelLarge" style={styles.comparisonValue}>
          {right}
        </CKText>
      </View>
      <View style={styles.dualProgress}>
        <View style={styles.progressHalf}>
          <View
            style={[
              styles.progressBar,
              {
                width: `${Math.min(1, Math.max(0, leftProgress)) * 100}%`,
                backgroundColor: leftColor,
                alignSelf: 'flex-end',
              },
            ]}
          />
        </View>
        <View style={styles.progressHalf}>
          <View
            style={[
              styles.progressBar,
              {
                width: `${Math.min(1, Math.max(0, rightProgress)) * 100}%`,
                backgroundColor: rightColor,
              },
            ]}
          />
        </View>
      </View>
    </View>
  );
}

function MemberMini({
  member,
  align = 'left',
}: {
  member: WarMember | null;
  align?: 'left' | 'right';
}) {
  return (
    <View style={[styles.memberMini, align === 'right' && styles.memberMiniRight]}>
      <MobileWebImage
        imageUrl={ImageAssets.townHall(member?.townhallLevel ?? 1)}
        style={styles.miniTh}
      />
      <View style={styles.grow}>
        <CKText role="labelMedium" numberOfLines={1}>
          {member?.name ?? '—'}
        </CKText>
        <CKText muted role="labelSmall">
          #{member?.mapPosition ?? '—'}
        </CKText>
      </View>
    </View>
  );
}

function warFilterOptions(
  t: ReturnType<typeof useI18n>['t'],
): { key: WarMemberFilter; label: string }[] {
  return [
    { key: 'all', label: t('warPositionMap') },
    { key: 'rattacks', label: t('warAttacksTitle') },
    { key: 'rdefenses', label: t('warDefensesTitle') },
    { key: 'bestAttacks', label: t('warAttacksBest') },
    { key: 'bestDefenses', label: t('warDefensesBest') },
    { key: 'bestPerformance', label: t('warStarsBestPerformance') },
    { key: 'noattacks', label: t('warAttacksNone') },
    { key: 'nodefenses', label: t('warDefensesNone') },
    { key: '3stars', label: `⚔ 3 ★` },
    { key: '2stars', label: `⚔ 2 ★` },
    { key: '1star', label: `⚔ 1 ★` },
    { key: '0star', label: `⚔ 0 ★` },
    { key: 'def_3stars', label: `🛡 3 ★` },
    { key: 'def_2stars', label: `🛡 2 ★` },
    { key: 'def_1star', label: `🛡 1 ★` },
    { key: 'def_0star', label: `🛡 0 ★` },
  ];
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  tabs: { paddingHorizontal: 12, marginTop: -12 },
  content: { width: '100%', maxWidth: 1320, alignSelf: 'center', padding: 10 },
  stack: { gap: 10 },
  grow: { flex: 1 },
  comparison: { minHeight: 34, flexDirection: 'row', alignItems: 'center' },
  comparisonValue: { width: 82, textAlign: 'center' },
  comparisonLabel: { flex: 1, textAlign: 'center' },
  comparisonMetric: { gap: 5, marginBottom: 9 },
  comparisonMetricLabel: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 5,
  },
  comparisonIcon: { width: 16, height: 16 },
  dualProgress: {
    height: 7,
    borderRadius: 4,
    backgroundColor: '#8888882e',
    overflow: 'hidden',
    flexDirection: 'row',
  },
  progressHalf: { width: '50%', height: 7 },
  progressBar: { height: 7 },
  metricWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 7 },
  calculatorActionRow: { alignItems: 'flex-end' },
  calculatorButton: {
    width: 176,
    minHeight: 44,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 10,
  },
  calculatorButtonCompact: { width: 44, paddingHorizontal: 0, justifyContent: 'center' },
  filterRail: { gap: 7 },
  filterChip: {
    minHeight: 34,
    paddingHorizontal: 12,
    borderRadius: 17,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  eventRow: { minHeight: 78, padding: 9, flexDirection: 'row', alignItems: 'center', gap: 7 },
  orderBadge: {
    minWidth: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: '#88888822',
    alignItems: 'center',
    justifyContent: 'center',
  },
  memberMini: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: 5 },
  memberMiniRight: { flexDirection: 'row-reverse' },
  miniTh: { width: 34, height: 34, resizeMode: 'contain' },
  eventResult: { width: 90, alignItems: 'center' },
  segment: {
    minHeight: 44,
    borderRadius: 16,
    backgroundColor: '#8888881f',
    flexDirection: 'row',
    padding: 3,
  },
  segmentButton: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 13,
    paddingHorizontal: 8,
  },
  memberCard: { padding: 11, gap: 10 },
  memberHeader: { flexDirection: 'row', alignItems: 'center', gap: 9 },
  thImage: { width: 48, height: 48, resizeMode: 'contain' },
  memberColumns: { flexDirection: 'row', gap: 10 },
  memberColumn: { flex: 1, gap: 5 },
  attackCount: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  actionHeader: { flexDirection: 'row', alignItems: 'center', gap: 5, minHeight: 20 },
  inlineIcon: { width: 18, height: 18 },
  attackLine: {
    minHeight: 43,
    paddingVertical: 2,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
  },
  actionTownHall: { width: 28, height: 28 },
  starLine: { flexDirection: 'row', alignItems: 'center', gap: 2, marginTop: 3 },
  starIcon: { width: 13, height: 13 },
  mutedImage: { opacity: 0.42 },
  mutedText: { opacity: 0.56 },
  calculatorSheet: { width: '100%', padding: 0, overflow: 'hidden' },
  calculatorHeader: {
    minHeight: 52,
    paddingHorizontal: 16,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  calculatorBody: { paddingHorizontal: 16, paddingBottom: 16, gap: 12 },
  calculatorFields: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  calculatorField: { flex: 1, minWidth: 180, gap: 6 },
  numberInput: {
    minHeight: 48,
    borderWidth: 1,
    borderRadius: 14,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
  },
  inputText: { flex: 1, fontSize: 16, fontWeight: '800' },
  calculateButton: {
    minHeight: 44,
    borderWidth: 1,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  calculatorResult: { padding: 14, gap: 5 },
  calculatorAnswer: { textAlign: 'center', fontWeight: '700' },
  analysisHeader: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  analysisIcon: { width: 22, height: 22 },
  analysisObjective: { gap: 3, marginTop: 4 },
});
