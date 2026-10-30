import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChevronRight, Equal, ListFilter } from 'lucide-react-native';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  ArtworkToggleButton,
  InfoDialog,
  EmptyState,
  MobileWebImage,
  SkeletonContent,
  SelectionPicker,
  useCKTheme,
} from '../../../ui';
import { WarStatsFilter, type Player, type PlayerCwlHistory, type PlayerWarStats } from '../models';
import { warHistoryRangeFilter, type WarHistoryRange } from '../../war/models/war-history-range';
import { WarRangePicker } from '../../war/presentation/war-range-picker';
import { WarAttackCard } from '../../war/presentation/war-attack-card';
import type { PlayerDetailPresentationActions } from './player-detail-contracts';
import { WarPerformanceSummary, warCwlContext, type PlayerWarMode } from './player-war-overview';
import type { PlayerWarStatsData, WarAttackSnapshot } from '../models/player-war';
import { relativeWarTime } from '../../war/presentation/presentation-utils';

export function PlayerWarTab({
  data,
  actions,
  loading = false,
  cwlHistory,
  player,
}: {
  data?: PlayerWarStats | null;
  actions: PlayerDetailPresentationActions;
  player: Player;
  loading?: boolean;
  cwlHistory?: PlayerCwlHistory | null;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const [range, setRange] = useState<WarHistoryRange>('days:90');
  const [battleType, setBattleType] = useState<PlayerWarMode | 'all'>('all');
  // The TH control affects only card statistics; battle filters stay independent.
  const [thHelp, setThHelp] = useState(false);
  const [battleDirection, setBattleDirection] = useState<'all' | 'attacks' | 'defenses'>('all');
  const [sameHall, setSameHall] = useState(true);
  const [pending, setPending] = useState(false);
  const [failed, setFailed] = useState(false);
  const request = useRef(0);
  const loadCwl = actions.loadTab;
  useEffect(() => {
    void loadCwl('cwl');
  }, [loadCwl]);
  const changeRange = async (next: WarHistoryRange) => {
    const id = ++request.current;
    setRange(next);
    setFailed(false);
    setPending(true);
    try {
      await actions.updateWarFilter(new WarStatsFilter(warHistoryRangeFilter(next)));
    } catch {
      if (request.current === id) setFailed(true);
    } finally {
      if (request.current === id) setPending(false);
    }
  };
  return (
    <View
      style={[
        styles.sections,
        styles.content,
        layout.isExpanded && {
          width: '100%',
          maxWidth: layout.contentMaxWidth,
          alignSelf: 'center',
        },
      ]}
      testID="player-war-content"
    >
      <View style={styles.rangeRow}>
        <ArtworkToggleButton
          accessibilityRole="switch"
          accessibilityLabel={t('filtersSameTownHallOnly')}
          accessibilityHint={t('playerWarThScope')}
          accessibilityState={{ checked: sameHall }}
          onPress={() => setSameHall((value) => !value)}
          onLongPress={() => setThHelp(true)}
          active={sameHall}
        >
          <MobileWebImage
            imageUrl={ImageAssets.townHall(player.townHallLevel)}
            style={{ width: 28, height: 28 }}
          />
          <Equal
            size={13}
            color={sameHall ? theme.secondary : theme.onSurfaceVariant}
            style={styles.equalIcon}
          />
        </ArtworkToggleButton>
        <Pressable
          onPress={() => setThHelp(true)}
          accessibilityRole="button"
          accessibilityLabel={t('playerWarThScope')}
          style={styles.thCaption}
        >
          <CKText muted role="metadata">
            {t(sameHall ? 'warOpponentEqualThLevel' : 'warFiltersAnyTownHall')}
          </CKText>
        </Pressable>
        <View style={styles.rangePicker}>
          <WarRangePicker
            includeLifetime
            value={range}
            onChange={(next) => void changeRange(next)}
          />
        </View>
      </View>
      <InfoDialog
        visible={thHelp}
        title={t('filtersSameTownHallOnly')}
        message={t('playerWarThScope')}
        onClose={() => setThHelp(false)}
      />

      {failed ? (
        <EmptyState
          title={t('generalError')}
          body={t('generalTryAgain')}
          actionLabel={t('generalRetry')}
          onAction={() => void changeRange(range)}
        />
      ) : !data ? (
        <EmptyState title={t('generalNoDataAvailable')} />
      ) : (
        <SkeletonContent loading={loading || pending}>
          <View
            style={[
              styles.sections,
              layout.isExpanded &&
                layout.usableWidth >= 840 && {
                  flexDirection: 'row',
                  alignItems: 'flex-start',
                  gap: 24,
                },
            ]}
          >
            <View
              style={
                layout.isExpanded && layout.usableWidth >= 840
                  ? { width: 350 }
                  : { display: 'contents' }
              }
            >
              <WarPerformanceSummary data={data} sameHall={sameHall} />
            </View>
            <View
              style={
                layout.isExpanded && layout.usableWidth >= 840
                  ? { flex: 1, minWidth: 0 }
                  : { display: 'contents' }
              }
            >
              <PlayerWarBattles
                key={[range, battleType].join(':')}
                wars={data.wars}
                mode={battleType}
                onModeChange={(next) => {
                  setBattleType(next);
                }}
                cwlHistory={cwlHistory}
                direction={battleDirection}
                onDirectionChange={setBattleDirection}
                actions={actions}
              />
            </View>
          </View>
        </SkeletonContent>
      )}
    </View>
  );
}

type Battle = {
  war: PlayerWarStatsData;
  attack: WarAttackSnapshot;
  direction: 'attacks' | 'defenses';
};
function PlayerWarBattles({
  wars,
  mode,
  onModeChange,
  cwlHistory,
  direction,
  onDirectionChange,
  actions,
}: {
  wars: readonly PlayerWarStatsData[];
  mode: PlayerWarMode | 'all';
  onModeChange: (value: PlayerWarMode | 'all') => void;
  direction: 'all' | 'attacks' | 'defenses';
  onDirectionChange: (direction: 'all' | 'attacks' | 'defenses') => void;
  cwlHistory?: PlayerCwlHistory | null;
  actions: PlayerDetailPresentationActions;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [visible, setVisible] = useState(40);
  const entries = useMemo(
    () =>
      wars
        .filter((war) => mode === 'all' || warType(war) === mode)
        // Sort wars before flattening so equal end times never interleave their cards.
        .sort(
          (a, b) => (b.warDetails.endTime?.getTime() ?? 0) - (a.warDetails.endTime?.getTime() ?? 0),
        )
        .flatMap((war) =>
          (['attacks', 'defenses'] as const).flatMap((type) =>
            // Attacks precede defenses within each war; newest hit comes first in each group.
            [...war.memberData[type]]
              .sort((a, b) => b.order - a.order)
              .map((attack): Battle => ({ war, attack, direction: type })),
          ),
        )
        .filter((entry) => {
          if (direction !== 'all' && entry.direction !== direction) return false;
          return true;
        }),
    [wars, mode, direction],
  );
  const groups: { war: PlayerWarStatsData; key: string; entries: Battle[] }[] = [];
  for (const entry of entries.slice(0, visible)) {
    const key = [
      entry.war.warDetails.tag,
      entry.war.warDetails.clan?.tag,
      entry.war.warDetails.endTime?.toISOString(),
    ].join(':');
    const last = groups[groups.length - 1];
    if (last?.key === key) last.entries.push(entry);
    else groups.push({ key, war: entry.war, entries: [entry] });
  }
  return (
    <View style={styles.sections} testID="player-war-battles">
      <CKText skeleton={false} role="sectionTitle">
        {t('esportsBattles')}
      </CKText>
      <View style={styles.battleFilters}>
        <View style={styles.battlePicker}>
          <SelectionPicker
            title={t('filtersWarType')}
            selectedKey={mode}
            onSelect={onModeChange}
            options={[
              {
                key: 'all',
                label: t('warFiltersAllWars'),
                icon: <ListFilter size={18} color={theme.onSurfaceVariant} />,
              },
              {
                key: 'random',
                label: t('playerWarRegularWars'),
                icon: <MobileWebImage imageUrl={ImageAssets.sword} style={styles.dropdownIcon} />,
              },
              {
                key: 'cwl',
                label: t('cwlTitle'),
                icon: (
                  <MobileWebImage
                    imageUrl={ImageAssets.cwlSwordsNoBorder}
                    style={styles.dropdownIcon}
                  />
                ),
              },
              {
                key: 'friendly',
                label: t('warFiltersFriendly'),
                icon: <MobileWebImage imageUrl={ImageAssets.warClan} style={styles.dropdownIcon} />,
              },
            ]}
          />
        </View>
        <View style={styles.battlePicker}>
          <SelectionPicker
            title={t('esportsBattles')}
            selectedKey={direction}
            onSelect={(next) => {
              onDirectionChange(next);
              setVisible(40);
            }}
            options={[
              {
                key: 'all',
                label: t('generalAll'),
                icon: <ListFilter size={18} color={theme.onSurfaceVariant} />,
              },
              {
                key: 'attacks',
                label: t('warAttacksTitle'),
                icon: <MobileWebImage imageUrl={ImageAssets.sword} style={styles.dropdownIcon} />,
              },
              {
                key: 'defenses',
                label: t('warDefensesTitle'),
                icon: <MobileWebImage imageUrl={ImageAssets.shield} style={styles.dropdownIcon} />,
              },
            ]}
          />
        </View>
      </View>
      {!entries.length ? (
        <EmptyState title={t('playerBattlelogNoBattlesTitle')} body={t('statsNoDataBody')} />
      ) : (
        groups.map(({ war, key, entries: battles }) => {
          const date = war.warDetails.endTime ?? war.warDetails.startTime;
          const type = warType(war);
          const cwl = warCwlContext(war, cwlHistory);
          const clan =
            [war.warDetails.clan, war.warDetails.opponent].find((side) =>
              side?.members.some((member) => member.tag === war.memberData.tag),
            ) ??
            [war.warDetails.clan, war.warDetails.opponent].find(
              (side) => side?.tag === cwl?.season.clan.tag,
            ) ??
            war.warDetails.clan;
          const label =
            type === 'cwl'
              ? t('cwlTitle')
              : type === 'friendly'
                ? t('warFiltersFriendly')
                : t('playerWarRegularWars');
          const now = new Date();
          const dateLabel = date
            ? now.getTime() - date.getTime() >= 0 &&
              now.getTime() - date.getTime() <= 30 * 86_400_000
              ? relativeWarTime(date, now, t)
              : date.toLocaleDateString(toIntlLocale(locale), {
                  day: 'numeric',
                  month: 'short',
                  year: 'numeric',
                })
            : '';
          return (
            <View key={key} style={styles.sections}>
              <Pressable
                accessibilityRole="button"
                onPress={() => actions.openWar(war.warDetails)}
                style={styles.warHeader}
              >
                <MobileWebImage
                  imageUrl={clan?.badgeUrls.medium ?? ImageAssets.defaultImage}
                  style={styles.warIcon}
                />
                <View style={styles.grow}>
                  <CKText role="rowTitle">{clan?.name}</CKText>
                  <View style={styles.metadata}>
                    {type === 'cwl' && cwl?.season.clan.leagueName ? (
                      <MobileWebImage
                        imageUrl={ImageAssets.getWarLeagueImage(cwl.season.clan.leagueName)}
                        style={styles.leagueIcon}
                      />
                    ) : null}
                    <CKText muted role="metadata" style={styles.metadataText}>
                      {[
                        label,
                        cwl?.round ? t('cwlRoundShort', { round: cwl.round }) : '',
                        dateLabel,
                      ]
                        .filter(Boolean)
                        .join(' · ')}
                    </CKText>
                  </View>
                </View>
                <ChevronRight size={18} color={theme.onSurfaceVariant} />
              </Pressable>
              {battles.map(({ attack, direction: type }, index) => (
                <WarAttackCard
                  key={`${type}:${attack.order}:${index}`}
                  testID={`player-war-battle-${type}-${attack.order}`}
                  attack={attack}
                  attacker={type === 'attacks' ? war.memberData : attack.attacker}
                  defender={type === 'defenses' ? war.memberData : attack.defender}
                  attacking={type === 'attacks'}
                  showOpponent
                  onPress={() => actions.openWar(war.warDetails)}
                />
              ))}
            </View>
          );
        })
      )}
      {visible < entries.length ? (
        <Pressable
          accessibilityRole="button"
          onPress={() => setVisible((value) => value + 40)}
          style={styles.more}
        >
          <CKText role="rowTitle">{t('postsLoadMore')}</CKText>
        </Pressable>
      ) : null}
    </View>
  );
}
function warType(war: PlayerWarStatsData): PlayerWarMode {
  return war.warDetails.isClanWarLeague
    ? 'cwl'
    : war.warDetails.warType === 'friendly'
      ? 'friendly'
      : 'random';
}
const styles = StyleSheet.create({
  sections: { gap: 16 },
  dropdownIcon: { width: 20, height: 20 },
  rangeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-start',
    gap: 8,
  },
  rangePicker: { width: 190, maxWidth: '60%', flexShrink: 1, marginLeft: 'auto' },
  battleFilters: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  battlePicker: { flex: 1, minWidth: 0 },
  equalIcon: { position: 'absolute', right: 3, bottom: 3 },
  thCaption: { flexShrink: 1, minWidth: 0, justifyContent: 'center' },
  content: { paddingHorizontal: 16, paddingTop: 12 },
  metadata: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  metadataText: { flexShrink: 1 },
  leagueIcon: { width: 20, height: 20 },
  toolbar: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  grow: { flex: 1, minWidth: 0 },
  friendly: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 12,
    gap: 10,
  },
  warHeader: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10, gap: 10 },
  warIcon: { width: 36, height: 36 },
  more: { alignItems: 'center', padding: 16 },
});
