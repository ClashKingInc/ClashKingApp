import { wikiSectionForUpgradeCategory, wikiSections } from '../../game-assets/wiki-catalogue';
import { formatWikiDuration } from '../../game-assets/wiki-duration';
import { WikiUpgradeCost } from '../../game-assets/wiki-upgrade-cost';
import {
  wikiItemHasStat,
  wikiCombatStats,
  wikiHasResearchUpgrades,
} from '../../game-assets/wiki-stat-visibility';
import { WikiStatBars } from '../../game-assets/wiki-stat-bars';
import { WikiScrollView } from '../../game-assets/wiki-scroll-view';
import { WikiHeader, WikiSectionLinks, WikiTheme } from '../../game-assets/wiki-layout';
import { WikiTable } from '../../game-assets/wiki-table';
import { useWikiNavigation } from '../../game-assets/wiki-navigation';
import { WikiSquadMembers } from '../../game-assets/wiki-squad-members';
import { modalOrientations } from '../../../ui/modal-orientations';
import { useEffect, useMemo, useRef, useState, type ReactNode, type ComponentRef } from 'react';
import { Modal, Pressable, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import { ArrowLeft, Lock, Clock3, Coins, Layers3, X } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { manifestImage } from '../../../core/assets/asset-manifest';
import { ImageAssets } from '../../../core/assets/image-assets';
import {
  localizedNameForItem,
  localizedInfoForItem,
  translationForTid,
} from '../../../core/game-data/game-data-localization';
import { gameDataState, isRecord } from '../../../core/game-data/game-data-state';
import { materialBackLabel, materialCloseLabel, toIntlLocale, useI18n } from '../../../i18n';
import { findLevelStats } from '../../player/data/player-item-utils';
import {
  CKText,
  MobileWebImage,
  ResponsiveGrid,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
  useCKAccessibility,
} from '../../../ui';
import {
  UpgradeCategory,
  UpgradeCost,
  UpgradeStep,
  UpgradeVillage,
  type UpgradeCategorySummary,
  type UpgradeCollectionItem,
  type UpgradeTrackerItem,
  type UpgradeTrackerSnapshot,
} from '../models';
import { formatTrackerDuration } from './upgrade-tracker-logic';
import { AbilityDetails, abilityFieldLabel, formatAbilityValue } from './ability-details';
import { trackerCategoryImage } from './tracker-category-art';
import { LevelSlider } from '../../../ui/level-slider';

export function UpgradeCollectionSummaryModal({
  visible,
  title,
  items,
  onClose,
}: {
  visible: boolean;
  title: string;
  items: readonly UpgradeCollectionItem[];
  onClose: () => void;
}) {
  const { t } = useI18n();
  const owned = items.filter((item) => item.owned);
  const type = items[0]?.type;
  const details =
    type === 'skins'
      ? ['Legendary', 'Gold', 'Basic', 'Default']
          .map((label) => ({
            label,
            count: owned.filter((item) => item.meta?.tier === label).length,
          }))
          .filter((entry) => entry.count > 0)
      : type === 'decorations'
        ? [
            ...owned.reduce((counts, item) => {
              const width = Number(item.meta?.width);
              const label = Number.isFinite(width) && width > 0 ? `${width}×${width}` : '';
              if (label) counts.set(label, (counts.get(label) ?? 0) + item.count);
              return counts;
            }, new Map<string, number>()),
          ].map(([label, count]) => ({ label, count }))
        : [];
  return (
    <BreakdownModal visible={visible} title={title} onClose={onClose}>
      <ResponsiveGrid minItemWidth={110} maxColumns={3}>
        <Metric label={t('upgradeTrackerHeaderOwned')} value={owned.length} />
        <Metric label={t('upgradeTrackerFilterMissing')} value={items.length - owned.length} />
        <Metric label={t('generalAvailable')} value={items.length} />
      </ResponsiveGrid>
      {details.length ? (
        <>
          <SectionLabel>
            {type === 'skins' ? t('upgradeTrackerOwnedByTier') : t('upgradeTrackerOwnedBySize')}
          </SectionLabel>
          <ResponsiveGrid minItemWidth={110} maxColumns={4}>
            {details.map((detail) => (
              <Metric key={detail.label} label={detail.label} value={detail.count} />
            ))}
          </ResponsiveGrid>
        </>
      ) : null}
    </BreakdownModal>
  );
}

export function UpgradeCategorySummaryModal({
  visible,
  title,
  summary,
  onClose,
}: {
  visible: boolean;
  title: string;
  summary: UpgradeCategorySummary | null;
  onClose: () => void;
}) {
  const { t, locale } = useI18n();
  const intlLocale = toIntlLocale(locale);
  if (!summary) return null;
  const formattedPercent = new Intl.NumberFormat(intlLocale, {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  }).format(summary.completion * 100);
  return (
    <BreakdownModal visible={visible} title={title} onClose={onClose}>
      <CKText muted role="bodySmall">
        {t('upgradeTrackerPercentComplete', { percent: formattedPercent })}
      </CKText>
      <ResponsiveGrid minItemWidth={112} maxColumns={3}>
        <Metric label={t('upgradeTrackerHeaderLevelsLeft')} value={summary.levelsRemaining} />
        {summary.seconds > 0 ? (
          <Metric label={t('upgradeTrackerTimeLeft')} value={formatTrackerDuration(summary.seconds)} />
        ) : null}
        {Object.entries(summary.costs)
          .sort(([left], [right]) => resourceWeight(left) - resourceWeight(right))
          .map(([resource, amount]) => (
            <Metric
              key={resource}
              label={resourceLabel(resource)}
              value={compact(amount, intlLocale)}
              imageUrl={resourceImage(resource)}
            />
          ))}
      </ResponsiveGrid>
    </BreakdownModal>
  );
}

export function UpgradeItemDetailModal({
  item,
  snapshot,
  onClose,
}: {
  item: UpgradeTrackerItem | null;
  snapshot: UpgradeTrackerSnapshot;
  onClose: () => void;
}) {
  const wiki = useWikiNavigation();
  const openItem = wiki?.openItem;
  const opened = useRef<UpgradeTrackerItem | null>(null);
  useEffect(() => {
    if (!item) opened.current = null;
    if (item && openItem && opened.current !== item) {
      opened.current = item;
      openItem(item, snapshot);
      onClose();
    }
  }, [item, snapshot, openItem, onClose]);
  if (!item || openItem) return null;
  return (
    <UpgradeItemDetailContent
      key={`${item.planKey}-${item.currentLevel}-${item.targetLevel}`}
      item={item}
      snapshot={snapshot}
      wikiSection={wikiSectionForUpgradeCategory(item.category)}
      page
      onClose={onClose}
    />
  );
}

export const upgradeDetailGradientEnd = '100%';

export function UpgradeItemDetailContent(props: Parameters<typeof UpgradeItemDetailBody>[0]) {
  return props.page ? (
    <WikiTheme>
      <UpgradeItemDetailBody {...props} />
    </WikiTheme>
  ) : (
    <UpgradeItemDetailBody {...props} />
  );
}

function UpgradeItemDetailBody({
  item,
  snapshot,
  page = false,
  embedded = false,
  wikiSection,
  onClose,
}: {
  item: UpgradeTrackerItem;
  snapshot?: UpgradeTrackerSnapshot;
  page?: boolean;
  embedded?: boolean;
  wikiSection?: string;
  onClose: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const scrollRef = useRef<ComponentRef<typeof ScrollView>>(null);
  const anchors = useRef<Record<string, number>>({});
  const minimum = minimumDetailLevel(item);
  const portraitCategory =
    item.category === UpgradeCategory.sieges || item.category === UpgradeCategory.darkTroops
      ? 'troops'
      : item.category;
  const portraitUrl = `${ImageAssets.baseUrl}/${portraitCategory}/${item.name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '')}/portrait.webp`;
  const portrait =
    typeof item.meta?.wiki_image === 'string'
      ? item.meta.wiki_image
      : typeof item.meta?.portrait === 'string'
        ? item.meta.portrait
        : manifestImage(portraitUrl)
          ? portraitUrl
          : null;
  const [selectedLevel, setSelectedLevel] = useState(() =>
    Math.max(minimumDetailLevel(item), item.currentLevel),
  );
  const shareSection =
    wikiSection ??
    wikiSections.find(({ id }) => {
      const values = gameDataState.bundleData[id];
      return (
        Array.isArray(values) &&
        values.some((entry) => isRecord(entry) && String(entry._id) === String(item.id))
      );
    })?.id ??
    String(item.category);
  const accent = page ? theme.primary : detailAccent(item.category);
  const selected = Math.max(minimum, Math.min(item.targetLevel, selectedLevel));
  const stats = findLevelStats(item.meta, selected);
  const isHall = item.name === 'Town Hall' || item.name === 'Builder Hall';
  const requiredHall = Number(stats?.required_townhall ?? item.meta?.required_townhall);
  const builder = item.village === UpgradeVillage.builderBase;
  const nextStats = selected < item.targetLevel ? findLevelStats(item.meta, selected + 1) : null;
  const steps = page ? [] : upgradeStepsFromLevel(item, selected);
  const unlocks = useMemo(() => unlocksAtLevel(item, selected), [item, selected]);
  const researchUnlocks = ['Laboratory', 'Star Laboratory', 'Hero Hall', 'Blacksmith'].includes(
    item.name,
  );
  const inlineUnlocks =
    page &&
    [
      'Barracks',
      'Dark Barracks',
      'Builder Barracks',
      'Squad Barracks',
      'Workshop',
      'Spell Factory',
      'Dark Spell Factory',
      'Pet House',
    ].includes(item.name);
  const description = page
    ? localizedInfoForItem(item.meta).replaceAll('\\n', '\n')
    : firstSentences(localizedInfoForItem(item.meta).replaceAll('\\n', ' '), 2);
  const abilityItems = gameDataState.bundleData.abilities;
  const abilities = useMemo(() => {
    const entry = Array.isArray(abilityItems)
      ? abilityItems.find(
          (candidate) =>
            isRecord(candidate) && (candidate._id === item.id || candidate.name === item.name),
        )
      : undefined;
    return isRecord(entry) && Array.isArray(entry.abilities)
      ? entry.abilities.filter(isRecord)
      : [];
  }, [abilityItems, item.id, item.name]);
  return (
    <BreakdownModal
      visible
      title={localizedNameForItem(item.meta) || item.name}
      onClose={onClose}
      scrollable
      accent={accent}
      customHeader
      page={page}
      embedded={embedded}
      scrollRef={scrollRef}
    >
      {page ? (
        <>
          <View style={{ marginHorizontal: -18 }}>
            <WikiHeader
              title={localizedNameForItem(item.meta) || item.name}
              image={
                ['buildings', 'traps'].includes(wikiSection ?? '')
                  ? selected === item.currentLevel
                    ? item.imageUrl
                    : upgradeImageForLevel(item, selected)
                  : (portrait ?? upgradeImageForLevel(item, selected))
              }
              large
              fallbackImages={upgradeImageFallbacks(item, selected)}
              subtitle={t(
                item.village === UpgradeVillage.builderBase
                  ? 'gameBaseBuilder'
                  : 'upgradeTrackerHomeVillage',
              )}
              onBack={onClose}
              shareParams={{
                category: shareSection,
                asset: `${shareSection}:${item.id}`,
              }}
            />
          </View>
          <View style={{ marginHorizontal: -18, marginTop: -18 }}>
            <WikiSectionLinks
              onSelect={(section) => {
                scrollRef.current?.scrollTo({
                  y: anchors.current[section] ?? 0,
                  animated: !reduceMotion,
                });
              }}
            />
          </View>
          <View
            onLayout={(event) => {
              anchors.current.overview = event.nativeEvent.layout.y;
            }}
          >
            {description ? (
              <CKText muted role="bodySmall" style={{ fontSize: 13, lineHeight: 21 }}>
                {description}
              </CKText>
            ) : null}
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 14 }}>
              {item.meta?.housing_space != null ? (
                <View style={[breakdownStyles.wikiChip, { backgroundColor: theme.card }]}>
                  <CKText muted role="bodySmall" style={{ fontSize: 11, lineHeight: 16 }}>
                    {t('gameItemHousingSpace')} · {String(item.meta.housing_space)}
                  </CKText>
                </View>
              ) : null}
              {[UpgradeCategory.troops, UpgradeCategory.darkTroops, UpgradeCategory.spells].some(
                (category) => category === item.category,
              ) && [true, 1, 'true'].includes(item.meta?.is_seasonal as never) ? (
                <View style={[breakdownStyles.wikiChip, { backgroundColor: theme.card }]}>
                  <CKText muted role="bodySmall" style={{ fontSize: 11, lineHeight: 16 }}>
                    {t('wikiSeasonal')}
                  </CKText>
                </View>
              ) : null}
              {!isHall && Number.isFinite(requiredHall) && requiredHall > 0 ? (
                <View
                  style={[
                    breakdownStyles.wikiChip,
                    {
                      backgroundColor: theme.card,
                      flexDirection: 'row',
                      alignItems: 'center',
                      gap: 5,
                    },
                  ]}
                >
                  <MobileWebImage
                    imageUrl={
                      builder
                        ? ImageAssets.builderHall(requiredHall)
                        : ImageAssets.townHall(requiredHall)
                    }
                    contentFit="contain"
                    style={{ width: 21, height: 23 }}
                  />
                  <CKText muted role="bodySmall" style={{ fontSize: 11, lineHeight: 16 }}>
                    {t(builder ? 'gameBuilderHallLevelNumber' : 'gameTownHallLevelNumber', {
                      level: requiredHall,
                    })}
                  </CKText>
                </View>
              ) : null}
              {inlineUnlocks
                ? unlocks.map((unlock) => (
                    <UnlockPill
                      key={`${unlock.name}-${unlock.minimumLevel ?? ''}`}
                      unlock={unlock}
                    />
                  ))
                : null}
            </View>
          </View>
        </>
      ) : (
        <>
          <View
            testID="upgrade-detail-hero"
            style={[
              breakdownStyles.detailHero,
              page && { flexDirection: 'column', alignItems: 'stretch', paddingTop: 48 },
            ]}
          >
            <View
              style={[
                breakdownStyles.heroArt,
                {
                  borderColor: colorWithAlpha(accent, 0.68),
                  backgroundColor: page ? 'transparent' : theme.surfaceContainerHighest,
                },
              ]}
            >
              <MobileWebImage
                imageUrl={page && portrait ? portrait : upgradeImageForLevel(item, selected)}
                fallbackImageUrls={upgradeImageFallbacks(item, selected)}
                style={[breakdownStyles.heroImage, page && { width: '100%', height: 172 }]}
              />
            </View>
            <View style={breakdownStyles.grow}>
              <CKText role="titleMedium" numberOfLines={2} style={breakdownStyles.detailTitle}>
                {localizedNameForItem(item.meta) || item.name}
              </CKText>
              {item.category === UpgradeCategory.equipment && item.meta?.hero ? (
                <CKText muted role="labelSmall">
                  For {String(item.meta.hero)}
                </CKText>
              ) : null}
              {description ? (
                <CKText
                  muted
                  role="bodySmall"
                  numberOfLines={page ? undefined : 4}
                  style={breakdownStyles.detailDescription}
                >
                  {description}
                </CKText>
              ) : null}
            </View>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={page ? materialBackLabel(locale) : materialCloseLabel(locale)}
              hitSlop={8}
              onPress={onClose}
              style={[
                breakdownStyles.detailClose,
                page && { position: 'absolute', top: 0, left: 0, width: 48, height: 48 },
              ]}
            >
              {page ? (
                <ArrowLeft color={theme.onSurface} size={22} />
              ) : (
                <X color={theme.onSurface} size={22} />
              )}
            </Pressable>
          </View>
        </>
      )}
      {item.name === 'Town Hall' && Array.isArray(stats?.variants) && stats.variants.length > 0 ? (
        <View style={{ gap: 10 }}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={{ gap: 10, paddingBottom: 4 }}
          >
            {stats.variants.filter(isRecord).map((variant) => {
              const required = isRecord(variant.required_troop) ? variant.required_troop : null;
              const troop = required
                ? snapshot?.items.find((candidate) => candidate.id === Number(required._id))
                : undefined;
              const unlocked =
                !snapshot || !required || (troop?.currentLevel ?? 0) >= Number(required.level);
              const tid = isRecord(variant.TID) ? variant.TID.name : undefined;
              const name =
                typeof tid === 'string'
                  ? (translationForTid(tid) ?? String(variant.name))
                  : String(variant.name);
              // Wiki detail has no player snapshot. Resolve the requirement's
              // canonical troop by ID; never construct an image URL from '' .
              const catalogueTroop =
                required && Array.isArray(gameDataState.bundleData.troops)
                  ? gameDataState.bundleData.troops
                      .filter(isRecord)
                      .find((candidate) => Number(candidate._id) === Number(required._id))
                  : undefined;
              const troopName = String(catalogueTroop?.name ?? troop?.name ?? required?.name ?? '');
              return (
                <Surface
                  key={String(variant._id)}
                  radius={ckRadius.tile}
                  accessibilityLabel={`${name}, ${unlocked ? t('playerActivityItemUnlocked', { name }) : t('widgetNotUnlocked')}${required ? `, ${troopName} ${troop?.currentLevel ?? 0}/${Number(required.level)}` : ''}`}
                  style={{ width: 142, padding: 12, gap: 8, alignItems: 'center' }}
                >
                  <View
                    style={{
                      alignSelf: 'stretch',
                      flexDirection: 'row',
                      alignItems: 'center',
                      minHeight: 24,
                    }}
                  >
                    {!unlocked ? <Lock size={16} color={theme.onSurfaceVariant} /> : null}
                    <View style={{ flex: 1 }} />
                    {required && troopName ? (
                      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
                        <MobileWebImage
                          imageUrl={ImageAssets.getTroopImage(troopName)}
                          contentFit="contain"
                          style={{ width: 24, height: 24 }}
                        />
                        {!unlocked ? (
                          <CKText muted role="labelSmall">
                            {troop?.currentLevel ?? 0}/{Number(required.level)}
                          </CKText>
                        ) : null}
                      </View>
                    ) : null}
                  </View>
                  <MobileWebImage
                    imageUrl={ImageAssets.getTownHallVariantImage(selected, Number(variant._id))}
                    contentFit="contain"
                    style={{ width: 84, height: 84, opacity: unlocked ? 1 : 0.65 }}
                  />
                  <CKText role="labelLarge" numberOfLines={2} style={{ textAlign: 'center' }}>
                    {name}
                  </CKText>
                </Surface>
              );
            })}
          </ScrollView>
        </View>
      ) : null}
      {isRecord(item.meta?.squad) ? <WikiSquadMembers squad={item.meta.squad} /> : null}
      <LevelSlider
        showStepButtons
        label={t('gameItemLevels')}
        compact={page}
        value={selected}
        minimum={minimum}
        maximum={item.targetLevel}
        accent={accent}
        onChange={setSelectedLevel}
        valueLabel={page ? `${selected} / ${item.targetLevel}` : undefined}
      />
      <>
        {!inlineUnlocks && unlocks.length ? (
          <>
            <SectionLabel>{t('wikiUnlocks')}</SectionLabel>
            {researchUnlocks ? (
              <ScrollView
                horizontal
                nestedScrollEnabled
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={breakdownStyles.unlockRow}
              >
                {unlocks.map((unlock) => (
                  <UnlockPill key={`${unlock.name}-${unlock.minimumLevel ?? ''}`} unlock={unlock} />
                ))}
              </ScrollView>
            ) : (
              <View style={breakdownStyles.wrap}>
                {unlocks.map((unlock) => (
                  <UnlockPill key={`${unlock.name}-${unlock.minimumLevel ?? ''}`} unlock={unlock} />
                ))}
              </View>
            )}
          </>
        ) : null}
        {page ? (
          <>
            <WikiUnitStats item={item} selected={selected} abilities={abilities} />
            <WikiStatBars item={item} selected={selected} />
          </>
        ) : (
          <>
            <SectionLabel>{t('generalStats')}</SectionLabel>
            <StatRow
              icon={<Clock3 size={18} color={accent} />}
              label={t('gameItemUpgradeTime')}
              value={steps.length ? formatTrackerDuration(steps[0]!.seconds) : 'Max'}
              accent={accent}
            />
            {steps[0]?.costs.length ? (
              <CostRow costs={steps[0].costs} accent={accent} />
            ) : (
              <StatRow
                icon={<Coins size={18} color={accent} />}
                label={t('gameItemUpgradeCost')}
                value={steps.length ? 'None' : 'Max'}
                accent={accent}
              />
            )}
            {showsWardenThreshold(item.category) && item.meta?.housing_space != null ? (
              <StatRow
                icon={<Layers3 size={18} color={accent} />}
                label={t('gameItemHousingSpace')}
                value={String(item.meta.housing_space)}
                accent={accent}
              />
            ) : null}
            {item.wardenWeight != null ? (
              <StatRow
                imageUrl={ImageAssets.getHeroImage('Grand Warden')}
                label={t('gameItemWardenWeight')}
                value={weightValue(item.wardenWeight)}
                accent={accent}
                detail={
                  showsWardenThreshold(item.category)
                    ? item.wardenWeight > 0
                      ? `${Math.ceil(20 / item.wardenWeight)} copies to follow`
                      : 'No threshold contribution'
                    : undefined
                }
              />
            ) : null}
            {item.healerWeight != null ? (
              <StatRow
                imageUrl={ImageAssets.getTroopImage('Healer')}
                label={t('gameItemHealerWeight')}
                value={weightValue(item.healerWeight)}
                accent={accent}
              />
            ) : null}
            {stats
              ? trackerStatRows(item, stats, nextStats).map((row) => (
                  <StatRow
                    key={row.label}
                    icon={<Layers3 size={18} color={accent} />}
                    label={detailStatLabel(row.label, t)}
                    value={row.value}
                    accent={accent}
                  />
                ))
              : null}
          </>
        )}
        {!page &&
          abilities.map((ability, index) => (
            <AbilityDetails
              key={`${String(ability.name)}-${index}`}
              ability={ability}
              level={selected}
              maximum={item.targetLevel}
              renderStat={(row) => (
                <StatRow
                  key={row.key}
                  icon={<Layers3 size={18} color={accent} />}
                  label={row.label}
                  value={row.value}
                  accent={accent}
                />
              )}
            />
          ))}
      </>
      {/* Keep comparisons in the same document as the selected-level stats.
          A view toggle hid useful context and made Wiki pages feel like modals. */}
      <View
        onLayout={(event) => {
          anchors.current.levels = event.nativeEvent.layout.y;
        }}
      >
        <SectionLabel>{t('wikiStatsByLevel')}</SectionLabel>
      </View>
      <LevelStatsTable
        item={item}
        minimum={minimum}
        abilities={abilities}
        locale={toIntlLocale(locale)}
        selected={selected}
      />
    </BreakdownModal>
  );
}

/** Match the guide's compact two-column stats, while retaining each item's
 * mechanics. These are selected-level values; the full table owns comparison. */
function WikiUnitStats({
  item,
  selected,
  abilities,
}: {
  item: UpgradeTrackerItem;
  selected: number;
  abilities: readonly Record<string, unknown>[];
}) {
  const { t, locale } = useI18n(),
    theme = useCKTheme();
  const stats = findLevelStats(item.meta, selected);
  const number = useMemo(
    () => new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 2 }),
    [locale],
  );
  const all = (stats ? trackerStatRows(item, stats, null) : []).filter((row) => {
    const field = wikiCombatStats[row.label as keyof typeof wikiCombatStats];
    return !field || wikiItemHasStat(item.meta?.levels, field, item.meta);
  });
  const first = ['HP', 'DPS', 'Damage', 'Healing'];
  const rows = [...all].sort((a, b) => {
    const ai = first.indexOf(a.label),
      bi = first.indexOf(b.label);
    return (ai < 0 ? 99 : ai) - (bi < 0 ? 99 : bi);
  });
  // Derive the complete card set on first render. A transition-end gate used
  // to insert invariant/ability cards later and visibly rearrange the page.
  const levels = useMemo(
    () => detailTableRows(item, minimumDetailLevel(item), abilities, number),
    [item, abilities, number],
  );
  // Fixed mechanics belong beside the selected-level headline stats, never repeated
  // in every table row. Compare all available levels, including explicit zeroes.
  const invariant = new Set(
    [...new Set(levels.flatMap((row) => [...row.cells.keys()]))].filter((key) =>
      levels.every((row) => row.cells.has(key) && row.cells.get(key) === levels[0]?.cells.get(key)),
    ),
  );
  const shown = rows.filter(
    (row, index) => isRecord(item.meta?.squad) || index < 2 || invariant.has(row.label),
  );
  const isHall = item.name === 'Town Hall' || item.name === 'Builder Hall';
  if (typeof item.meta?.production_building === 'string')
    shown.push({
      label: t('wikiProductionBuilding'),
      value: item.meta.production_building,
    });
  for (const key of invariant) {
    if (
      !shown.some((row) => row.label === key) &&
      !(isHall && key === 'required-townhall') &&
      !['upgrade-cost', 'upgrade-time', 'required-townhall'].includes(key) &&
      !key.startsWith('ore:')
    )
      shown.push({ label: key, value: levels[0]!.cells.get(key)! });
  }
  let summonedImage: string | undefined;
  for (const ability of abilities) {
    const row = Array.isArray(ability.levels)
      ? ability.levels.filter(isRecord).find((r) => r.level === selected)
      : undefined;
    if (isRecord(row?.spawned_unit) && typeof row.spawned_unit.name === 'string')
      summonedImage =
        typeof row.spawned_unit._id === 'number' &&
        row.spawned_unit._id >= 28000000 &&
        row.spawned_unit._id < 29000000
          ? ImageAssets.getHeroImage(row.spawned_unit.name)
          : ImageAssets.getTroopImage(row.spawned_unit.name);
    if (row?.units_spawned != null && !shown.some((r) => r.label === 'Units summoned'))
      shown.push({ label: 'Units summoned', value: number.format(Number(row.units_spawned)) });
  }
  return (
    <View style={breakdownStyles.wikiStats}>
      <WikiUpgradeCost meta={item.meta ?? {}} level={stats} />
      {shown.map((row, index) => {
        const icon =
          row.label === t('wikiProductionBuilding') &&
          typeof item.meta?.production_building === 'string'
            ? item.village === UpgradeVillage.builderBase
              ? ImageAssets.getBuilderBaseBuildingImage(
                  item.meta.production_building,
                  Number(
                    stats?.required_hero_tavern_level ?? item.meta.production_building_level,
                  ) || 1,
                )
              : ImageAssets.getHomeVillageBuildingImage(
                  item.meta.production_building,
                  Number(
                    stats?.required_hero_tavern_level ?? item.meta.production_building_level,
                  ) || 1,
                )
            : row.label === 'HP'
              ? ImageAssets.shield
              : /DPS|Damage|Attack/i.test(row.label)
                ? ImageAssets.sword
                : row.label === 'Units summoned' || row.label === 'Summoned unit'
                  ? summonedImage
                  : undefined;
        return (
          <View
            key={`${row.label}:${index}`}
            style={[
              breakdownStyles.wikiStat,
              {
                backgroundColor: theme.card,
                borderColor: colorWithAlpha(theme.outlineVariant, 0.25),
              },
            ]}
          >
            {icon ? (
              <MobileWebImage
                imageUrl={icon}
                contentFit="contain"
                style={{ width: 27, height: 30 }}
              />
            ) : null}
            <View style={{ flex: 1, gap: 3 }}>
              <CKText style={{ fontSize: 19, lineHeight: 25, fontVariant: ['tabular-nums'] }}>
                {detailStatValue(row.value, t)}
              </CKText>
              <CKText muted style={{ fontSize: 11, lineHeight: 16 }}>
                {detailStatLabel(row.label, t)}
              </CKText>
            </View>
          </View>
        );
      })}
    </View>
  );
}

/** One source for table columns and fixed-stat cards keeps the same ability
 * fields visible at every level without duplicating the old modal sections. */
function detailTableRows(
  item: UpgradeTrackerItem,
  minimum: number,
  abilities: readonly Record<string, unknown>[],
  number: Intl.NumberFormat,
) {
  // Cards and the table share the same all-level combat-stat visibility.
  // Do not apply this to costs: an explicit zero cost is meaningful.
  const hiddenStats = Object.entries(wikiCombatStats)
    .filter(([, field]) => !wikiItemHasStat(item.meta?.levels, field, item.meta))
    .map(([label]) => label);
  return Array.from({ length: Math.max(0, item.targetLevel - minimum + 1) }, (_, index) => {
    const level = minimum + index;
    const stats = findLevelStats(item.meta, level);
    const cells = new Map(
      stats ? trackerStatRows(item, stats, null, true).map((row) => [row.label, row.value]) : [],
    );
    if (stats) {
      const cost = stats.build_cost ?? stats.upgrade_cost;
      const research = wikiHasResearchUpgrades(item.meta);
      if (research && typeof cost === 'number') cells.set('upgrade-cost', number.format(cost));
      if (research && isRecord(stats.upgrade_cost))
        for (const [resource, amount] of Object.entries(stats.upgrade_cost))
          if (typeof amount === 'number') cells.set(`ore:${resource}`, number.format(amount));
      // Construction data uses build_time; research uses upgrade_time. Both
      // belong to the same displayed level row as their respective cost.
      const upgradeSeconds = stats.build_time ?? stats.upgrade_time;
      if (research && typeof upgradeSeconds === 'number')
        cells.set('upgrade-time', formatTrackerDuration(upgradeSeconds));
      if (research && typeof stats.required_lab_level === 'number')
        cells.set('Laboratory', number.format(stats.required_lab_level));
      if (typeof stats.required_hero_tavern_level === 'number')
        cells.set('Hero Hall', number.format(stats.required_hero_tavern_level));
      if (
        item.name !== 'Town Hall' &&
        item.name !== 'Builder Hall' &&
        typeof stats.required_townhall === 'number' &&
        stats.required_townhall > 0
      )
        cells.set('required-townhall', number.format(stats.required_townhall));
    }
    for (const ability of abilities) {
      const data = Array.isArray(ability.levels)
        ? ability.levels.filter(isRecord).find((row) => row.level === level)
        : undefined;
      if (!data) continue;
      for (const [key, value] of Object.entries(data)) {
        if (key === 'level') continue;
        const label = abilityFieldLabel(key);
        // Only qualify collisions between genuinely distinct effects, not every
        // column with the equipment name (which makes mobile headers enormous).
        cells.set(
          cells.has(label)
            ? `${localizedNameForItem(ability) || String(ability.name)} · ${label}`
            : label,
          formatAbilityValue(key, value, number),
        );
      }
    }
    for (const label of hiddenStats) cells.delete(label);
    return { level, cells };
  });
}

function LevelStatsTable({
  item,
  minimum,
  abilities,
  locale,
  selected,
}: {
  item: UpgradeTrackerItem;
  minimum: number;
  abilities: readonly Record<string, unknown>[];
  locale: string;
  selected: number;
}) {
  const { t } = useI18n();
  const number = useMemo(
    () => new Intl.NumberFormat(locale, { maximumFractionDigits: 3 }),
    [locale],
  );
  const rows = useMemo(
    () => detailTableRows(item, minimum, abilities, number),
    [item, minimum, abilities, number],
  );
  const tableUnlocks = useMemo(() => {
    if (['Laboratory', 'Star Laboratory', 'Blacksmith'].includes(item.name))
      return new Map<number, readonly Unlock[]>();
    return new Map(
      Array.from({ length: Math.max(0, item.targetLevel - minimum + 1) }, (_, index) => {
        const level = minimum + index;
        const unlocked = unlocksAtLevel(item, level);
        // Hero-level caps belong in the separate research-style unlock rail.
        // The table marks only a hero's first availability, without repeating
        // that hero on every later Hall upgrade or labeling it as a level range.
        const tableEntries =
          item.name === 'Hero Hall'
            ? unlocked
                .filter((unlock) => unlock.minimumLevel == null || unlock.minimumLevel === 1)
                .map((unlock) => ({
                  ...unlock,
                  minimumLevel: undefined,
                  maximumLevel: undefined,
                }))
            : unlocked;
        return [level, tableEntries] as const;
      }),
    );
  }, [item, minimum]);
  const showUnlocks = [...tableUnlocks.values()].some((unlocks) => unlocks.length > 0);
  const priority = ['HP', 'DPS', 'Damage', 'upgrade-cost', 'upgrade-time', 'required-townhall'];
  const columns = [...new Set(rows.flatMap((row) => [...row.cells.keys()]))]
    .filter(
      (key) =>
        [
          'HP',
          'DPS',
          'Damage',
          'Healing',
          'upgrade-cost',
          'upgrade-time',
          'required-townhall',
        ].includes(key) ||
        key.startsWith('ore:') ||
        ['Laboratory', 'Hero Hall'].includes(key) ||
        !rows.every((row) => row.cells.has(key) && row.cells.get(key) === rows[0]?.cells.get(key)),
    )
    .sort((a, b) => {
      const ai = priority.indexOf(a),
        bi = priority.indexOf(b);
      return (ai < 0 ? 99 : ai) - (bi < 0 ? 99 : bi);
    });
  return (
    <WikiTable
      identityLabel={t('wikiLevel')}
      identityWidth={70}
      columns={[
        ...columns.map((column) => ({
          key: column,
          label:
            column === 'required-townhall' && item.village === UpgradeVillage.builderBase
              ? t('gameBuilderHall')
              : detailStatLabel(column, t),
          width: column === 'HP' || column === 'DPS' ? 74 : 146,
          image:
            column === 'upgrade-cost'
              ? resourceImage(String(item.meta?.upgrade_resource ?? 'gold'))
              : column === 'upgrade-time'
                ? ImageAssets.iconClock
                : column === 'required-townhall'
                  ? item.village === UpgradeVillage.builderBase
                    ? ImageAssets.builderHall(1)
                    : ImageAssets.townHall(1)
                  : column.startsWith('ore:')
                    ? resourceImage(column.slice(4))
                    : /^(HP|hitpoints|hit points)$/i.test(column)
                      ? ImageAssets.hitpoints
                      : /damage|dps/i.test(column)
                        ? ImageAssets.sword
                        : undefined,
        })),
        ...(showUnlocks ? [{ key: 'unlocks', label: t('wikiUnlocks'), width: 190 }] : []),
      ]}
      rows={rows.map((row) => ({
        key: String(row.level),
        selected: row.level === selected,
        label: number.format(row.level),
        values: {
          ...Object.fromEntries(
            [...row.cells].map(([key, value]) => [key, detailStatValue(value, t)]),
          ),
          ...(showUnlocks
            ? {
                unlocks: tableUnlocks.get(row.level)?.length ? (
                  <View style={{ gap: 5, width: '100%' }}>
                    {tableUnlocks.get(row.level)!.map((unlock) => (
                      <UnlockPill
                        key={`${unlock.name}-${unlock.minimumLevel ?? ''}`}
                        unlock={unlock}
                      />
                    ))}
                  </View>
                ) : null,
              }
            : {}),
        },
      }))}
    />
  );
}

function BreakdownModal({
  visible,
  title,
  onClose,
  children,
  scrollable = true,
  accent,
  customHeader = false,
  page = false,
  embedded = false,
  scrollRef,
}: {
  scrollRef?: React.RefObject<ComponentRef<typeof ScrollView> | null>;
  visible: boolean;
  title: string;
  onClose: () => void;
  children: ReactNode;
  scrollable?: boolean;
  accent?: string;
  customHeader?: boolean;
  page?: boolean;
  embedded?: boolean;
}) {
  const theme = useCKTheme();
  if (page) {
    const content = (
      <SafeAreaView style={{ flex: 1, backgroundColor: theme.background }}>
        <WikiScrollView
          scrollRef={scrollRef}
          contentContainerStyle={{
            paddingHorizontal: 18,
            paddingBottom: 32,
            gap: 18,
            width: '100%',
            maxWidth: 900,
            alignSelf: 'center',
          }}
        >
          {children}
        </WikiScrollView>
      </SafeAreaView>
    );
    return embedded ? (
      content
    ) : (
      <Modal
        visible={visible}
        supportedOrientations={modalOrientations}
        animationType="slide"
        onRequestClose={onClose}
      >
        {content}
      </Modal>
    );
  }
  const titleRow = (
    <View style={breakdownStyles.row}>
      <CKText role="titleLarge" style={breakdownStyles.grow}>
        {title}
      </CKText>
      <Pressable accessibilityRole="button" accessibilityLabel="Close" onPress={onClose}>
        <X color={theme.onSurface} />
      </Pressable>
    </View>
  );
  return (
    <Modal
      supportedOrientations={modalOrientations}
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={breakdownStyles.overlay}>
        <Pressable
          accessible={false}
          onPress={onClose}
          style={StyleSheet.absoluteFill}
          testID="upgrade-detail-backdrop"
        />
        <Surface
          accessibilityViewIsModal
          onAccessibilityEscape={onClose}
          testID="upgrade-detail-dialog"
          radius={ckRadius.card}
          style={[breakdownStyles.modal, accent ? { backgroundColor: theme.surface } : undefined]}
        >
          {accent ? (
            <Svg
              testID="upgrade-detail-gradient"
              style={StyleSheet.absoluteFill}
              pointerEvents="none"
              viewBox="0 0 100 100"
              preserveAspectRatio="none"
            >
              <Defs>
                <LinearGradient
                  id="upgrade-detail-accent"
                  x1="0%"
                  y1="0%"
                  x2="0%"
                  y2={upgradeDetailGradientEnd}
                >
                  <Stop offset="0" stopColor={accent} stopOpacity={0.28} />
                  <Stop offset="0.5" stopColor={theme.surface} stopOpacity={1} />
                  <Stop offset="1" stopColor={theme.surface} stopOpacity={1} />
                </LinearGradient>
              </Defs>
              <Rect width="100" height="100" fill="url(#upgrade-detail-accent)" />
            </Svg>
          ) : null}
          {scrollable ? (
            <>
              {customHeader ? null : titleRow}
              <ScrollView
                testID="breakdown-scroll"
                showsVerticalScrollIndicator={false}
                contentContainerStyle={breakdownStyles.content}
              >
                {children}
              </ScrollView>
            </>
          ) : (
            <ScaleDownContent>
              {customHeader ? null : titleRow}
              {children}
            </ScaleDownContent>
          )}
        </Surface>
      </View>
    </Modal>
  );
}

export function detailScaleDownFactor(contentHeight: number, maximumHeight: number) {
  if (contentHeight <= 0 || maximumHeight <= 0) return 1;
  return Math.min(1, maximumHeight / contentHeight);
}

export function detailModalMaximumContentHeight(viewportHeight: number) {
  const modalVerticalPadding = 38;
  const modalBorderAllowance = 2;
  return Math.max(220, viewportHeight * 0.88 - modalVerticalPadding - modalBorderAllowance);
}

function ScaleDownContent({ children }: { readonly children: ReactNode }) {
  const { height } = useWindowDimensions();
  const [contentHeight, setContentHeight] = useState(0);
  const maximumHeight = detailModalMaximumContentHeight(height);
  const scale = detailScaleDownFactor(contentHeight, maximumHeight);
  return (
    <View
      testID="breakdown-fixed-content"
      style={[
        breakdownStyles.fixedViewport,
        {
          maxHeight: maximumHeight,
          height: contentHeight > 0 ? contentHeight * scale : undefined,
        },
      ]}
    >
      <View
        testID="breakdown-scale-content"
        onLayout={(event) => setContentHeight(event.nativeEvent.layout.height)}
        style={[
          breakdownStyles.fixedContent,
          scale < 1 ? { transform: [{ scale }], transformOrigin: 'top center' } : undefined,
        ]}
      >
        {children}
      </View>
    </View>
  );
}

function Metric({
  label,
  value,
  imageUrl,
}: {
  readonly label: string;
  readonly value: string | number;
  readonly imageUrl?: string;
}) {
  return (
    <Surface
      radius={ckRadius.tile}
      style={[breakdownStyles.metric, imageUrl && breakdownStyles.metricWithImage]}
    >
      {imageUrl ? <MobileWebImage imageUrl={imageUrl} style={breakdownStyles.metricImage} /> : null}
      <View style={imageUrl ? breakdownStyles.grow : undefined}>
        <CKText role="rowTitle">{value}</CKText>
        <CKText muted role="labelSmall">
          {label}
        </CKText>
      </View>
    </Surface>
  );
}
function StatRow({
  icon,
  imageUrl,
  label,
  value,
  detail,
  accent,
}: {
  icon?: ReactNode;
  imageUrl?: string;
  label: string;
  value: string;
  detail?: string;
  accent: string;
}) {
  return (
    <View style={breakdownStyles.stat}>
      <View style={[breakdownStyles.statIcon, { backgroundColor: colorWithAlpha(accent, 0.13) }]}>
        {imageUrl ? <MobileWebImage imageUrl={imageUrl} style={breakdownStyles.statImage} /> : icon}
      </View>
      <View style={[breakdownStyles.grow, { minWidth: 80 }]}>
        <CKText muted>{label}</CKText>
        {detail ? (
          <CKText muted role="labelSmall">
            {detail}
          </CKText>
        ) : null}
      </View>
      <CKText role="rowTitle" style={{ maxWidth: '55%', flexShrink: 1, textAlign: 'right' }}>
        {value}
      </CKText>
    </View>
  );
}
function CostRow({ costs, accent }: { costs: readonly UpgradeCost[]; accent: string }) {
  const { locale } = useI18n();
  const intlLocale = toIntlLocale(locale);
  return (
    <View style={breakdownStyles.stat}>
      <View style={[breakdownStyles.statIcon, { backgroundColor: colorWithAlpha(accent, 0.13) }]}>
        <Coins size={18} color={accent} />
      </View>
      <CKText muted style={breakdownStyles.grow}>
        Upgrade cost
      </CKText>
      <View style={{ gap: 4 }}>
        {costs.map((cost) => (
          <View key={cost.resource} style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            <MobileWebImage
              imageUrl={resourceImage(cost.resource)}
              contentFit="contain"
              style={{ width: 24, height: 24 }}
              accessible={false}
            />
            <CKText role="rowTitle">
              {compact(cost.amount, intlLocale)} {resourceLabel(cost.resource)}
            </CKText>
          </View>
        ))}
      </View>
    </View>
  );
}
function SectionLabel({ children }: { children: ReactNode }) {
  return <CKText role="sectionTitle">{children}</CKText>;
}

export function upgradeStepsFromLevel(
  item: UpgradeTrackerItem,
  selectedLevel: number,
): readonly UpgradeStep[] {
  const steps: UpgradeStep[] = [];
  const levels = Array.isArray(item.meta?.levels) ? item.meta.levels.filter(isRecord) : [];
  const usesBuildFields = levels.some((level) => 'build_cost' in level || 'build_time' in level);
  for (let target = selectedLevel + 1; target <= item.targetLevel; target += 1) {
    const existing = item.steps.find((step) => step.targetLevel === target);
    if (existing) {
      steps.push(existing);
      continue;
    }
    const level = findLevelStats(item.meta, usesBuildFields ? target : target - 1);
    if (!level) continue;
    const rawCost = level[usesBuildFields ? 'build_cost' : 'upgrade_cost'];
    const costs: UpgradeCost[] = [];
    if (isRecord(rawCost)) {
      for (const [resource, rawAmount] of Object.entries(rawCost)) {
        const amount = Number(rawAmount);
        if (Number.isFinite(amount) && amount > 0) costs.push(new UpgradeCost(resource, amount));
      }
    } else {
      const amount = Number(rawCost);
      if (Number.isFinite(amount) && amount > 0) {
        costs.push(new UpgradeCost(String(item.meta?.upgrade_resource ?? 'gold'), amount));
      }
    }
    steps.push(
      new UpgradeStep(
        target,
        costs,
        Math.round(Number(level[usesBuildFields ? 'build_time' : 'upgrade_time']) || 0),
      ),
    );
  }
  return steps;
}
export function minimumDetailLevel(item: UpgradeTrackerItem) {
  const levels = Array.isArray(item.meta?.levels)
    ? item.meta.levels
        .filter(isRecord)
        .map((level) => Number(level.level))
        .filter((level) => Number.isFinite(level) && level > 0)
    : [];
  return levels.length ? Math.min(...levels) : 1;
}

type Unlock = {
  name: string;
  imageUrl: string;
  subtitle: string | null;
  minimumLevel?: number;
  maximumLevel?: number;
};

function UnlockPill({ unlock }: { unlock: Unlock }) {
  const { t, locale } = useI18n();
  const numbers = new Intl.NumberFormat(toIntlLocale(locale));
  const level =
    unlock.minimumLevel == null
      ? null
      : t('sideLevel', {
          level:
            unlock.minimumLevel === unlock.maximumLevel
              ? numbers.format(unlock.minimumLevel)
              : `${numbers.format(unlock.minimumLevel)}–${numbers.format(unlock.maximumLevel!)}`,
        });
  return (
    <Surface radius={6} style={breakdownStyles.unlock}>
      <MobileWebImage
        imageUrl={unlock.imageUrl}
        contentFit="contain"
        style={breakdownStyles.unlockImage}
      />
      <CKText role="labelSmall" style={{ flexShrink: 1 }}>
        {unlock.name}
      </CKText>
      {level || unlock.subtitle ? (
        <CKText muted role="labelSmall">
          {level ?? unlock.subtitle}
        </CKText>
      ) : null}
    </Surface>
  );
}

export function unlocksAtLevel(item: UpgradeTrackerItem, level: number): readonly Unlock[] {
  const direct = findLevelStats(item.meta, level)?.unlocks;
  if (Array.isArray(direct))
    return direct
      .filter(isRecord)
      .map((entry) => ({
        name: localizedNameForItem(entry) || String(entry.name ?? ''),
        imageUrl: directUnlockImage(String(entry.name ?? '')),
        subtitle: Number(entry.quantity ?? 1) > 1 ? `×${Number(entry.quantity)}` : null,
      }))
      .filter((entry) => entry.name);
  const result: Unlock[] = [];
  const buildings = Array.isArray(gameDataState.bundleData.buildings)
    ? gameDataState.bundleData.buildings.filter(isRecord)
    : [];
  // Most Wiki entries are not producers. Avoid rescanning the whole unit
  // catalogue for every level of a troop/equipment comparison table.
  if (!buildings.some((building) => Number(building._id) === item.id)) return [];
  const heroes = Array.isArray(gameDataState.bundleData.heroes)
    ? gameDataState.bundleData.heroes.filter(isRecord)
    : [];
  const village = item.village === UpgradeVillage.builderBase ? 'builderBase' : 'home';
  const researchBuilding = item.name === 'Laboratory' || item.name === 'Star Laboratory';
  const heroHall = item.name === 'Hero Hall';
  const blacksmith = item.name === 'Blacksmith';
  const buildingLevels = Array.isArray(item.meta?.levels) ? item.meta.levels.filter(isRecord) : [];
  const firstEligibleLevel = (requiredLevel: number, requiredHall: number) =>
    buildingLevels
      .filter(
        (row) =>
          Number(row.level) >= requiredLevel && Number(row.required_townhall) >= requiredHall,
      )
      .sort((a, b) => Number(a.level) - Number(b.level))[0]?.level;
  for (const section of ['troops', 'spells', 'pets', 'heroes', 'equipment'] as const) {
    const values = gameDataState.bundleData[section];
    if (!Array.isArray(values)) continue;
    for (const raw of values.filter(isRecord)) {
      const name = String(raw.name ?? '');
      const unitVillage =
        raw.village === 'builderBase' || raw.village === 'builder' ? 'builderBase' : 'home';
      if (!name || unitVillage !== village || isSuperTroop(raw) || raw.is_seasonal) continue;
      const imageUrl = unlockImage(section, name);
      const displayName = localizedNameForItem(raw) || name;
      // Hero Hall and Blacksmith report level ranges below; ordinary producers
      // report the item itself once at its production-building unlock level.
      if (raw.production_building === item.name && !heroHall && !blacksmith) {
        if (Number(raw.production_building_level) === level)
          result.push({ name: displayName, imageUrl, subtitle: null });
      }
      if (
        (!researchBuilding && !heroHall && !blacksmith) ||
        isRecord(raw.squad) ||
        !Array.isArray(raw.levels)
      )
        continue;
      if (heroHall && section !== 'heroes') continue;
      if (blacksmith && section !== 'equipment') continue;
      if (researchBuilding && !['troops', 'spells'].includes(section)) continue;
      const production = buildings.find(
        (building) => building.name === raw.production_building && building.village === village,
      );
      const productionLevels = Array.isArray(production?.levels)
        ? production.levels.filter(isRecord)
        : [];
      const productionHall =
        Number(
          productionLevels.find((row) => row.level === raw.production_building_level)
            ?.required_townhall,
        ) || 0;
      const hero = blacksmith ? heroes.find((candidate) => candidate.name === raw.hero) : undefined;
      const heroFirst = Array.isArray(hero?.levels)
        ? hero.levels.filter(isRecord).find((row) => Number(row.level) === 1)
        : undefined;
      const eligibleLevels: number[] = [];
      for (const upgrade of raw.levels.filter(isRecord)) {
        const required = heroHall
          ? upgrade.required_hero_tavern_level
          : blacksmith
            ? upgrade.required_blacksmith_level
            : upgrade.required_lab_level;
        // Labs research upgrades after level one; Hero Hall/Blacksmith also
        // expose the first supported level. Blacksmith caps include Epic gear
        // without claiming it is acquired there, and never precede its hero.
        if ((researchBuilding && Number(upgrade.level) <= 1) || required == null) continue;
        const eligible = firstEligibleLevel(
          Number(required),
          Math.max(
            productionHall,
            Number(upgrade.required_townhall) || 0,
            Number(heroFirst?.required_townhall) || 0,
          ),
        );
        if (Number(eligible) === level) eligibleLevels.push(Number(upgrade.level));
      }
      // Coalesce only adjacent levels, never imply a gap is also unlocked.
      const sorted = [...new Set(eligibleLevels)].sort((a, b) => a - b);
      for (let index = 0; index < sorted.length;) {
        const minimumLevel = sorted[index]!;
        let maximumLevel = minimumLevel;
        while (sorted[index + 1] === maximumLevel + 1) maximumLevel = sorted[++index]!;
        index += 1;
        result.push({ name: displayName, imageUrl, subtitle: null, minimumLevel, maximumLevel });
      }
    }
  }
  return result;
}
function detailStatValue(value: string, t: ReturnType<typeof useI18n>['t']): string {
  switch (value) {
    case 'Yes':
      return t('generalYes');
    case 'No':
      return t('generalNo');
    case 'Air':
      return t('gameItemTargetsAir');
    case 'Ground':
      return t('gameItemTargetsGround');
    case 'Air & ground':
      return `${t('gameItemTargetsAir')} / ${t('gameItemTargetsGround')}`;
    case 'Shared targeting':
      return t('wikiSharedTargeting');
    default:
      return value;
  }
}

function detailStatLabel(label: string, t: ReturnType<typeof useI18n>['t']): string {
  // Labels are also stable data keys. Translate only at the rendering boundary
  // so localization cannot change column identity or the invariant-stat checks.
  const separator = label.indexOf(' · ');
  if (separator >= 0)
    return `${label.slice(0, separator)} · ${detailStatLabel(label.slice(separator + 3), t)}`;
  if (label === 'Hero Hall') {
    const buildings = gameDataState.bundleData.buildings;
    const hall = Array.isArray(buildings)
      ? buildings.find((entry) => isRecord(entry) && entry.name === 'Hero Hall')
      : undefined;
    return isRecord(hall) ? localizedNameForItem(hall) : t('gameItemHero');
  }
  for (const prefix of ['Summoned unit ', 'Spawned unit ']) {
    if (label.startsWith(prefix)) {
      const rest = label.slice(prefix.length);
      return `${t('wikiSummonedUnit')} · ${detailStatLabel(rest.charAt(0).toUpperCase() + rest.slice(1), t)}`;
    }
  }
  const keys = {
    'Minimum range': 'wikiMinimumRange',
    'Effect range': 'wikiEffectRange',
    'Building size': 'wikiBuildingSize',
    Ability: 'wikiAbility',
    'Units summoned': 'wikiUnitsSummoned',
    'Summoned unit': 'wikiSummonedUnit',
    'Trigger radius': 'wikiTriggerRadius',
    'Damage radius': 'wikiDamageRadius',
    'Cone angle': 'wikiConeAngle',
    'Splash damage cap': 'wikiSplashDamageCap',
    'Trap damage reduction': 'wikiTrapDamageReduction',
    'Damage reduction': 'wikiDamageReduction',
    'Damage increase': 'wikiDamageIncrease',
    'Shared targeting': 'wikiSharedTargeting',
    'Ability duration': 'warAttacksDetailsDuration',
    Laboratory: 'upgradeTrackerLaboratory',
    'Attack speed': 'gameItemAttackSpeed',
    'Attack range': 'gameItemAttackRange',
    'Movement speed': 'gameItemMovementSpeed',
    DPS: 'gameItemDps',
    HP: 'gameItemHitpoints',
    Healing: 'gameItemHealOnActivation',
    Targets: 'gameItemTargets',
    'upgrade-cost': 'gameItemUpgradeCost',
    'upgrade-time': 'gameItemUpgradeTime',
    'required-townhall': 'gameTownHallLevel',
    'ore:shiny_ore': 'resourceShinyOre',
    'ore:glowy_ore': 'resourceGlowyOre',
    'ore:starry_ore': 'resourceStarryOre',
    Damage: 'wikiDamage',
    Boost: 'wikiBoost',
    Duration: 'warAttacksDetailsDuration',
    Cooldown: 'wikiStatCooldown',
    Uses: 'wikiStatUses',
    Landings: 'wikiStatLandings',
    'Empowered attacks': 'wikiStatEmpoweredAttacks',
    'Destroys walls': 'wikiStatDestroysWalls',
    'Chain targets': 'wikiStatChainTargets',
    'Damage lost per chain': 'wikiStatChainLoss',
    Interval: 'wikiStatInterval',
    Slowdown: 'wikiStatSlowdown',
    Stun: 'wikiStatStun',
    Aura: 'wikiStatAura',
    Projectile: 'wikiStatProjectile',
    Reflection: 'wikiStatReflection',
    Recall: 'wikiStatRecall',
    Untargetable: 'wikiStatUntargetable',
    'Immune to friendly spells': 'wikiStatFriendlySpellImmunity',
    'Jumps walls': 'wikiStatJumpsWalls',
    'Housing space lost': 'wikiStatLostHousing',
    Proximity: 'wikiStatProximity',
    Altitude: 'wikiStatAltitude',
    'Units per wave': 'wikiStatUnitsPerWave',
    'Spawn distance': 'wikiStatSpawnDistance',
    'Affects owner': 'wikiStatAffectsOwner',
    'Affected by damage boosts': 'wikiStatDamageBoostsApply',
    Invisibility: 'wikiStatInvisibility',
    Radius: 'wikiStatRadius',
    Hits: 'wikiStatHits',
    Lifetime: 'warAttacksDetailsDuration',
  } as const;
  const key = keys[label as keyof typeof keys];
  if (key) return t(key);
  const pair = (a: string, b: string) => `${a} · ${b}`;
  const per = (a: string, b: string) => `${a} / ${b}`;
  const damage = t('wikiDamage'),
    heal = t('gameItemHealOnActivation');
  const duration = t('warAttacksDetailsDuration'),
    radius = t('wikiStatRadius');
  const named: Record<string, string> = {
    Invisible: t('wikiStatInvisibility'),
    'Invisibility duration': pair(t('wikiStatInvisibility'), duration),
    'Min damage': `${damage} ≥`,
    'Extra damage': `${damage} +`,
    Speed: t('gameItemMovementSpeed'),
    Health: t('gameItemHitpoints'),
    'Health increase': `${t('gameItemHitpoints')} +`,
    'Max health increase': `${t('gameItemHitpoints')} + ≤`,
    'Summon interval': pair(t('wikiSummonedUnit'), t('wikiStatInterval')),
    'Spawn interval': pair(t('wikiSummonedUnit'), t('wikiStatInterval')),
    'Proximity radius': pair(t('wikiStatProximity'), radius),
    'Proximity deactivate radius': `${pair(t('wikiStatProximity'), radius)} (−)`,
    'Proximity altitude': pair(t('wikiStatProximity'), t('wikiStatAltitude')),
    'Proximity requires can open cc': `${t('wikiStatProximity')} ⇒ ${t('legendsClanCastle')}`,
    'Stun duration': pair(t('wikiStatStun'), duration),
    'Slowdown percent': `${t('wikiStatSlowdown')} (%)`,
    'Slowdown duration': pair(t('wikiStatSlowdown'), duration),
    'Aura radius': pair(t('wikiStatAura'), radius),
    'Projectile radius': pair(t('wikiStatProjectile'), radius),
    'Projectile range': pair(t('wikiStatProjectile'), t('gameItemAttackRange')),
    'DPS stage 2': pair(t('gameItemDps'), 'II'),
    'DPS stage 3': pair(t('gameItemDps'), 'III'),
    'Stage 2 after': pair('II', duration),
    'Stage 3 after': pair('III', duration),
    'Housing limit': `${t('gameItemHousingSpace')} ≤`,
    'Targets hit': pair(t('gameItemTargets'), t('wikiStatHits')),
    'Target damage multiplier': `${pair(t('gameItemTargets'), damage)} ×`,
    'Bonus damage target': `${pair(t('gameItemTargets'), damage)} +`,
    'Building damage percent per hit': per(
      pair(t('gameAssetsCategoryBuildings'), damage),
      t('wikiStatHits'),
    ),
    'Troop damage percent per hit': per(pair(t('gameTroops'), damage), t('wikiStatHits')),
    'Hit interval': pair(t('wikiStatHits'), t('wikiStatInterval')),
    'Healing per second': `${heal} / s`,
    'Healing per attack': per(heal, t('wikiStatHits')),
    'Damage (% of target HP)': `${damage} / ${pair(t('gameItemTargets'), t('gameItemHitpoints'))} (%)`,
    'Deactivates at housing space': `${t('gameItemHousingSpace')} ≤`,
    'Housing space lost required': `${t('wikiStatLostHousing')} ≥`,
    'Damage taken per activation': per(`${t('gameItemHitpoints')} −`, t('wikiStatUses')),
    'Hero damage percent': `${pair(t('gameItemHero'), damage)} (%)`,
    'Reflected damage': pair(t('wikiStatReflection'), damage),
    'Healing per reflection': per(heal, t('wikiStatReflection')),
    'Reflection cooldown': pair(t('wikiStatReflection'), t('wikiStatCooldown')),
    'Recall speed boost': `${pair(t('wikiStatRecall'), t('gameItemMovementSpeed'))} +`,
    'Recall healing percent': `${pair(t('wikiStatRecall'), heal)} (%)`,
    'Recall housing space': pair(t('wikiStatRecall'), t('gameItemHousingSpace')),
    'Recall speed boost duration': pair(pair(t('wikiStatRecall'), t('wikiBoost')), duration),
    'Recall radius': pair(t('wikiStatRecall'), radius),
  };
  if (named[label]) return named[label];
  if (label.endsWith(' increase')) return `${detailStatLabel(label.slice(0, -9), t)} +`;
  return label;
}

function trackerStatRows(
  item: UpgradeTrackerItem,
  level: Record<string, unknown>,
  next: Record<string, unknown> | null,
  includeZero = false,
) {
  const rows: { label: string; value: string }[] = [];
  const add = (label: string, value: unknown, nextValue: unknown, suffix = '') => {
    // Tables distinguish an exported zero from an absent field; compact detail
    // rows still hide zero-only mechanics that do not apply at this level.
    if (value == null || value === '' || (!includeZero && Number(value) === 0)) return;
    const changed = nextValue != null && nextValue !== value;
    const current = Number(value),
      following = Number(nextValue);
    const percent =
      changed && Number.isFinite(current) && Number.isFinite(following) && current !== 0
        ? ((following - current) / Math.abs(current)) * 100
        : null;
    rows.push({
      label,
      value: changed
        ? `${String(value)}${suffix} → ${String(nextValue)}${suffix}${percent == null ? '' : ` (${percent >= 0 ? '+' : ''}${Math.abs(percent) >= 10 ? percent.toFixed(0) : percent.toFixed(1)}%)`}`
        : `${String(value)}${suffix}`,
    });
  };
  add('Boost', level.boost_multiplier, next?.boost_multiplier, '×');
  add(
    'Duration',
    typeof level.boost_time_seconds === 'number'
      ? formatWikiDuration(level.boost_time_seconds)
      : null,
    typeof next?.boost_time_seconds === 'number'
      ? formatWikiDuration(next.boost_time_seconds)
      : null,
  );
  add(
    'Attack speed',
    numberMap(level.attack_speed, 1000),
    numberMap(next?.attack_speed, 1000),
    's',
  );
  const isSquad = isRecord(item.meta?.squad) || item.meta?.production_building === 'Squad Barracks';
  // Squads are containers; their exported zero range/speed are not member stats.
  if (!isSquad)
    add(
      'Attack range',
      numberMap(
        level.attack_range ?? item.meta?.attack_range,
        usesUnitScaling(item.category) ? 100 : 1000,
      ),
      numberMap(
        next?.attack_range ?? item.meta?.attack_range,
        usesUnitScaling(item.category) ? 100 : 1000,
      ),
      ' tiles',
    );
  add(
    'Minimum range',
    tileValue(level.min_range ?? item.meta?.min_range),
    tileValue(next?.min_range ?? item.meta?.min_range),
    ' tiles',
  );
  add(
    'Effect range',
    tileValue(level.effect_range ?? item.meta?.effect_range),
    tileValue(next?.effect_range ?? item.meta?.effect_range),
    ' tiles',
  );
  if (!isSquad)
    add(
      'Movement speed',
      usesUnitScaling(item.category)
        ? movementSpeed(item.meta?.movement_speed)
        : item.meta?.movement_speed,
      usesUnitScaling(item.category)
        ? movementSpeed(item.meta?.movement_speed)
        : item.meta?.movement_speed,
      usesUnitScaling(item.category) ? ' tiles/sec' : '',
    );
  if (!isSquad) {
    add('DPS', level.dps, next?.dps);
    add('Damage', level.damage, next?.damage);
    add('HP', level.hitpoints, next?.hitpoints);
  } else {
    const squad = item.meta?.squad;
    const ability =
      isRecord(squad) && Array.isArray(squad.levels)
        ? squad.levels.find((entry) => isRecord(entry) && entry.level === level.level)
        : null;
    if (isRecord(ability)) {
      if (typeof ability.name === 'string') rows.push({ label: 'Ability', value: ability.name });
      else if (isRecord(ability.TID)) {
        const title = translationForTid(String(ability.TID.name ?? ''));
        if (title) rows.push({ label: 'Ability', value: title });
      }
      add('Splash damage cap', ability.splash_damage_cap, null);
      add('Trap damage reduction', ability.trap_damage_reduction_percent, null, '%');
      add('Damage reduction', ability.damage_reduction_percent, null, '%');
      add('Ability duration', numberMap(ability.duration_ms, 1000), null, 's');
      add('Damage increase', ability.damage_increase_percent, null, '%');
      if (ability.shared_targeting) rows.push({ label: 'Ability', value: 'Shared targeting' });
    }
  }
  add('Healing', level.heal_on_activation, next?.heal_on_activation);
  add(
    'Building size',
    item.meta?.width ? `${String(item.meta.width)} × ${String(item.meta.width)}` : null,
    null,
  );
  add(
    'Trigger radius',
    tileValue(item.meta?.trigger_radius),
    tileValue(item.meta?.trigger_radius),
    ' tiles',
  );
  add(
    'Damage radius',
    tileValue(level.damage_radius ?? item.meta?.damage_radius),
    tileValue(next?.damage_radius ?? item.meta?.damage_radius),
    ' tiles',
  );
  add('Cone angle', item.meta?.cone_angle, item.meta?.cone_angle, '°');
  const air =
    level.is_air_targeting === true ||
    item.meta?.is_air_targeting === true ||
    item.meta?.air_trigger === true;
  const ground =
    level.is_ground_targeting === true ||
    item.meta?.is_ground_targeting === true ||
    item.meta?.ground_trigger === true;
  if (air || ground)
    rows.push({ label: 'Targets', value: air && ground ? 'Air & ground' : air ? 'Air' : 'Ground' });
  return rows;
}
function upgradeImageForLevel(item: UpgradeTrackerItem, level: number) {
  // Module and supercharge levels describe stats, not building artwork levels.
  // Preserve the parent defense image already resolved by the tracker parser.
  if (
    item.category === UpgradeCategory.craftedDefenses ||
    item.category === UpgradeCategory.supercharge
  )
    return item.imageUrl;
  if (item.category === UpgradeCategory.traps)
    return item.village === UpgradeVillage.home
      ? ImageAssets.getHomeVillageTrapImage(item.name, level)
      : ImageAssets.getBuilderBaseTrapImage(item.name, level);
  if (
    [
      UpgradeCategory.defenses,
      UpgradeCategory.craftedDefenses,
      UpgradeCategory.army,
      UpgradeCategory.resources,
      UpgradeCategory.walls,
      UpgradeCategory.supercharge,
    ].includes(item.category as never)
  )
    return item.village === UpgradeVillage.home
      ? ImageAssets.getHomeVillageBuildingImage(item.name, level)
      : ImageAssets.getBuilderBaseBuildingImage(item.name, level);
  return item.imageUrl;
}
export function upgradeImageFallbacks(item: UpgradeTrackerItem, fromLevel: number) {
  if (item.category === UpgradeCategory.supercharge) return [];
  if (
    ![
      UpgradeCategory.defenses,
      UpgradeCategory.traps,
      UpgradeCategory.craftedDefenses,
      UpgradeCategory.army,
      UpgradeCategory.resources,
      UpgradeCategory.walls,
      UpgradeCategory.supercharge,
    ].includes(item.category as never) ||
    fromLevel <= 1
  )
    return [];
  return Array.from({ length: fromLevel - 1 }, (_, index) =>
    upgradeImageForLevel(item, fromLevel - index - 1),
  );
}
function directUnlockImage(name: string) {
  // Unlocks include traps and level-less buildings; neither has a normal
  // home-village building level_1 asset.
  if (name === "B.O.B's Hut") return ImageAssets.getHomeVillageBuildingImage("Builder's Hut", 1);
  if (name === 'Helper Hut') return ImageAssets.getHelperImage('Builder Apprentice');
  if (name === 'Crafting Station')
    return trackerCategoryImage('craftedDefenses', UpgradeVillage.home);
  if (name === 'Guardian Shrine') return trackerCategoryImage('guardians', UpgradeVillage.home);
  const traps = gameDataState.bundleData.traps;
  if (
    Array.isArray(traps) &&
    traps.some((entry) => isRecord(entry) && entry.name === name && entry.village === 'home')
  )
    return ImageAssets.getHomeVillageTrapImage(name, 1);
  return ImageAssets.getHomeVillageBuildingImage(name, 1);
}
function unlockImage(section: string, name: string) {
  return section === 'heroes'
    ? ImageAssets.getHeroImage(name)
    : section === 'equipment'
      ? ImageAssets.getGearImage(name)
      : section === 'spells'
        ? ImageAssets.getSpellImage(name)
        : section === 'pets'
          ? ImageAssets.getPetImage(name)
          : ImageAssets.getTroopImage(name);
}
function isSuperTroop(item: Record<string, unknown>) {
  return (
    isRecord(item.super_troop) ||
    [item.is_super_troop, item.super_troop, item.is_super].some(
      (value) => value === true || value === 1 || String(value).toLowerCase() === 'true',
    ) ||
    String(item.type).toLowerCase() === 'super_troop' ||
    String(item.category).toLowerCase() === 'super_troop'
  );
}
export function firstSentences(value: string, count: number) {
  return (
    value
      .replace(/\s+/g, ' ')
      .trim()
      .match(/(?:[^.!?]+[.!?]+)|(?:[^.!?]+$)/g) ?? []
  )
    .slice(0, count)
    .map((part) => part.trim())
    .join(' ');
}
function showsWardenThreshold(category: string) {
  return category === UpgradeCategory.troops || category === UpgradeCategory.darkTroops;
}
function usesUnitScaling(category: string) {
  return [
    UpgradeCategory.troops,
    UpgradeCategory.darkTroops,
    UpgradeCategory.heroes,
    UpgradeCategory.pets,
    UpgradeCategory.sieges,
  ].includes(category as never);
}
function numberMap(value: unknown, divisor: number) {
  if (value == null || value === '') return null;
  const number = Number(value);
  return Number.isFinite(number) ? String(Math.round((number / divisor) * 100) / 100) : null;
}
function tileValue(value: unknown) {
  return numberMap(value, 1000);
}
function movementSpeed(value: unknown) {
  if (value == null || value === '') return null;
  const number = Number(value);
  if (!Number.isFinite(number)) return null;
  const rounded = Math.round((number / 100) * 10) / 10;
  return Number.isInteger(rounded) ? String(rounded) : rounded.toFixed(1);
}
function resourceWeight(resource: string) {
  const normalized = resource.toLowerCase();
  if (normalized.includes('gold') && !normalized.includes('builder')) return 0;
  if (normalized.includes('elixir') && !normalized.includes('dark')) return 1;
  if (normalized.includes('dark')) return 2;
  if (normalized.includes('builder_gold')) return 3;
  if (normalized.includes('builder_elixir')) return 4;
  return 99;
}
export function detailAccent(category: string) {
  if (category === UpgradeCategory.heroes || category === UpgradeCategory.guardians)
    return '#AA57E8';
  if (
    [
      UpgradeCategory.troops,
      UpgradeCategory.darkTroops,
      UpgradeCategory.spells,
      UpgradeCategory.sieges,
    ].includes(category as never)
  )
    return '#7A65D9';
  if (category === UpgradeCategory.pets) return '#E56B9F';
  return '#4D9DE0';
}
export function weightValue(value: number) {
  return String(value);
}
function compact(value: number, intlLocale: string) {
  if (value >= 1e9) return `${trimCompact(value / 1e9)}B`;
  if (value >= 1e6) return `${trimCompact(value / 1e6)}M`;
  if (value >= 1e3) return `${trimCompact(value / 1e3)}K`;
  return new Intl.NumberFormat(intlLocale).format(Math.round(value));
}
function trimCompact(value: number) {
  return value.toFixed(1).replace(/\.0$/, '');
}
function resourceLabel(value: string) {
  return value.replaceAll('_', ' ').replace(/\b\w/g, (char) => char.toUpperCase());
}
function resourceImage(resource: string) {
  const normalized = resource
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+/, '')
    .replace(/_+$/, '');
  return `${ImageAssets.baseUrl}/resources/${normalized}.webp`;
}

const breakdownStyles = StyleSheet.create({
  wikiChip: {
    paddingHorizontal: 8,
    paddingVertical: 5,
    borderRadius: 6,
    justifyContent: 'center',
    alignItems: 'center',
  },
  wikiStats: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  wikiStat: {
    width: '47%',
    flexGrow: 1,
    minWidth: 130,
    padding: 13,
    borderRadius: 10,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },

  overlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#00000070',
    padding: 18,
  },
  modal: {
    width: '100%',
    maxWidth: 440,
    maxHeight: '88%',
    paddingHorizontal: 20,
    paddingTop: 18,
    paddingBottom: 20,
    overflow: 'hidden',
  },
  content: { gap: 10, paddingTop: 10, paddingBottom: 20 },
  fixedViewport: { width: '100%', overflow: 'hidden' },
  fixedContent: { width: '100%', gap: 10, paddingBottom: 4 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  grow: { flex: 1 },
  section: { padding: 12, gap: 10 },
  sectionImage: { width: 46, height: 42, resizeMode: 'contain' },
  metric: { minHeight: 58, justifyContent: 'center', padding: 8 },
  metricWithImage: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  metricImage: { width: 30, height: 30, resizeMode: 'contain' },
  hero: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  detailHero: {
    minHeight: 70,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    paddingRight: 38,
  },
  detailTitle: { fontWeight: '900', lineHeight: 22 },
  detailDescription: { fontSize: 11, lineHeight: 13 },
  detailClose: {
    position: 'absolute',
    top: -2,
    right: -2,
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroArt: {
    width: 70,
    height: 70,
    padding: 7,
    borderWidth: 1,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroImage: { width: 56, height: 56, resizeMode: 'contain' },
  wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  unlockRow: { flexDirection: 'row', alignItems: 'center', gap: 6, paddingBottom: 4 },
  unlock: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 7,
    paddingVertical: 4,
  },
  unlockImage: { width: 24, height: 24, resizeMode: 'contain' },
  stat: { minHeight: 48, flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 5 },
  statIcon: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: '#80808022',
    alignItems: 'center',
    justifyContent: 'center',
  },
  statImage: { width: 28, height: 28, resizeMode: 'contain' },
});
