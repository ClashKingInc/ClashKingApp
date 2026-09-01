import { useState, type ReactNode } from 'react';
import { Modal, Pressable, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import { Clock3, Coins, Layers3, X } from 'lucide-react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { ImageAssets } from '../../../core/assets/image-assets';
import { localizedInfoForItem } from '../../../core/game-data/game-data-localization';
import { gameDataState, isRecord } from '../../../core/game-data/game-data-state';
import { toIntlLocale, useI18n } from '../../../i18n';
import { findLevelStats } from '../../player/data/player-item-utils';
import {
  CKText,
  MobileWebImage,
  ResponsiveGrid,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
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
          <SectionLabel>{type === 'skins' ? 'Owned by tier' : 'Owned by size'}</SectionLabel>
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
  const { locale } = useI18n();
  const intlLocale = toIntlLocale(locale);
  if (!summary) return null;
  return (
    <BreakdownModal visible={visible} title={title} onClose={onClose}>
      <CKText muted role="bodySmall">
        {(summary.completion * 100).toFixed(1)}% complete
      </CKText>
      <ResponsiveGrid minItemWidth={112} maxColumns={3}>
        <Metric label="Levels left" value={summary.levelsRemaining} />
        {summary.seconds > 0 ? (
          <Metric label="Time left" value={formatTrackerDuration(summary.seconds)} />
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
  onClose,
}: {
  item: UpgradeTrackerItem | null;
  snapshot: UpgradeTrackerSnapshot;
  onClose: () => void;
}) {
  if (!item) return null;
  return (
    <UpgradeItemDetailContent
      key={`${item.planKey}-${item.currentLevel}-${item.targetLevel}`}
      item={item}
      onClose={onClose}
    />
  );
}

export const upgradeDetailGradientEnd = '100%';

function UpgradeItemDetailContent({
  item,
  onClose,
}: {
  item: UpgradeTrackerItem;
  onClose: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const minimum = minimumDetailLevel(item);
  const [selectedLevel, setSelectedLevel] = useState(() =>
    Math.max(minimumDetailLevel(item), item.currentLevel),
  );
  const accent = detailAccent(item.category);
  const selected = Math.max(minimum, Math.min(item.targetLevel, selectedLevel));
  const stats = findLevelStats(item.meta, selected);
  const nextStats = selected < item.targetLevel ? findLevelStats(item.meta, selected + 1) : null;
  const steps = upgradeStepsFromLevel(item, selected);
  const unlocks = unlocksAtLevel(item, selected);
  const description = firstSentences(localizedInfoForItem(item.meta).replaceAll('\\n', ' '), 2);
  return (
    <BreakdownModal
      visible
      title={item.name}
      onClose={onClose}
      scrollable={false}
      accent={accent}
      customHeader
    >
      <View testID="upgrade-detail-hero" style={breakdownStyles.detailHero}>
        <View
          style={[
            breakdownStyles.heroArt,
            {
              borderColor: colorWithAlpha(accent, 0.68),
              backgroundColor: theme.surfaceContainerHighest,
            },
          ]}
        >
          <MobileWebImage
            imageUrl={upgradeImageForLevel(item, selected)}
            fallbackImageUrls={upgradeImageFallbacks(item, selected)}
            style={breakdownStyles.heroImage}
          />
        </View>
        <View style={breakdownStyles.grow}>
          <CKText role="titleMedium" numberOfLines={2} style={breakdownStyles.detailTitle}>
            {item.name}
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
              numberOfLines={4}
              style={breakdownStyles.detailDescription}
            >
              {description}
            </CKText>
          ) : null}
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Close"
          hitSlop={8}
          onPress={onClose}
          style={breakdownStyles.detailClose}
        >
          <X color={theme.onSurface} size={22} />
        </Pressable>
      </View>
      <DetailLevelSlider
        value={selected}
        minimum={minimum}
        maximum={item.targetLevel}
        accent={accent}
        onChange={setSelectedLevel}
      />
      {unlocks.length ? (
        <>
          <SectionLabel>Unlocks</SectionLabel>
          <View style={breakdownStyles.wrap}>
            {unlocks.map((unlock) => (
              <Surface
                key={`${unlock.name}-${unlock.subtitle}`}
                radius={999}
                style={breakdownStyles.unlock}
              >
                <MobileWebImage imageUrl={unlock.imageUrl} style={breakdownStyles.unlockImage} />
                <CKText role="labelSmall">{unlock.name}</CKText>
                {unlock.subtitle ? (
                  <CKText muted role="labelSmall">
                    {unlock.subtitle}
                  </CKText>
                ) : null}
              </Surface>
            ))}
          </View>
        </>
      ) : null}
      <SectionLabel>Stats</SectionLabel>
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
              label={row.label}
              value={row.value}
              accent={accent}
            />
          ))
        : null}
    </BreakdownModal>
  );
}

function DetailLevelSlider({
  value,
  minimum,
  maximum,
  accent,
  onChange,
}: {
  value: number;
  minimum: number;
  maximum: number;
  accent: string;
  onChange: (value: number) => void;
}) {
  const [width, setWidth] = useState(1);
  const range = Math.max(0, maximum - minimum);
  const fraction = range === 0 ? 0 : (value - minimum) / range;
  return (
    <View style={breakdownStyles.levelSliderWrap}>
      <Pressable
        accessibilityRole="adjustable"
        accessibilityLabel={`Level ${value}`}
        accessibilityValue={{ min: minimum, max: maximum, now: value }}
        accessibilityActions={[{ name: 'increment' }, { name: 'decrement' }]}
        onAccessibilityAction={(event) => {
          if (event.nativeEvent.actionName === 'increment') onChange(Math.min(maximum, value + 1));
          if (event.nativeEvent.actionName === 'decrement') onChange(Math.max(minimum, value - 1));
        }}
        onLayout={(event) => setWidth(Math.max(1, event.nativeEvent.layout.width))}
        onPress={(event) =>
          onChange(
            Math.max(
              minimum,
              Math.min(
                maximum,
                Math.round(minimum + (event.nativeEvent.locationX / width) * range),
              ),
            ),
          )
        }
        style={breakdownStyles.levelSlider}
      >
        <View style={breakdownStyles.levelSliderTrack} />
        <View
          style={[
            breakdownStyles.levelSliderFill,
            { width: `${fraction * 100}%`, backgroundColor: accent },
          ]}
        />
        <View
          style={[
            breakdownStyles.levelSliderThumb,
            { left: `${fraction * 100}%`, backgroundColor: accent },
          ]}
        />
      </Pressable>
      <View style={breakdownStyles.levelLabels}>
        <CKText role="labelSmall" style={{ color: accent, fontWeight: '800' }}>
          Level {value}
        </CKText>
        <CKText role="labelSmall">Max {maximum}</CKText>
      </View>
    </View>
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
}: {
  visible: boolean;
  title: string;
  onClose: () => void;
  children: ReactNode;
  scrollable?: boolean;
  accent?: string;
  customHeader?: boolean;
}) {
  const theme = useCKTheme();
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
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
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
              <ScrollView testID="breakdown-scroll" contentContainerStyle={breakdownStyles.content}>
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
      <View style={breakdownStyles.grow}>
        <CKText muted>{label}</CKText>
        {detail ? (
          <CKText muted role="labelSmall">
            {detail}
          </CKText>
        ) : null}
      </View>
      <CKText role="rowTitle">{value}</CKText>
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
      <View>
        {costs.map((cost) => (
          <CKText key={cost.resource} role="rowTitle">
            {compact(cost.amount, intlLocale)} {resourceLabel(cost.resource)}
          </CKText>
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

type Unlock = { name: string; imageUrl: string; subtitle: string | null };
export function unlocksAtLevel(item: UpgradeTrackerItem, level: number): readonly Unlock[] {
  const direct = findLevelStats(item.meta, level)?.unlocks;
  if (Array.isArray(direct))
    return direct
      .filter(isRecord)
      .map((entry) => ({
        name: String(entry.name ?? ''),
        imageUrl: directUnlockImage(String(entry.name ?? '')),
        subtitle: Number(entry.quantity ?? 1) > 1 ? `×${Number(entry.quantity)}` : null,
      }))
      .filter((entry) => entry.name);
  const result: Unlock[] = [];
  for (const section of ['troops', 'spells', 'pets'] as const) {
    const values = gameDataState.bundleData[section];
    if (!Array.isArray(values)) continue;
    for (const raw of values.filter(isRecord)) {
      const name = String(raw.name ?? '');
      if (!name || (item.name === 'Barracks' && isSuperTroop(raw))) continue;
      if (raw.production_building === item.name && Number(raw.production_building_level) === level)
        result.push({ name, imageUrl: unlockImage(section, name), subtitle: null });
      if (item.name === 'Laboratory' && Array.isArray(raw.levels))
        for (const upgrade of raw.levels.filter(isRecord))
          if (Number(upgrade.required_lab_level) === level)
            result.push({
              name,
              imageUrl: unlockImage(section, name),
              subtitle: `Level ${String(upgrade.level)}`,
            });
    }
  }
  return result;
}
function trackerStatRows(
  item: UpgradeTrackerItem,
  level: Record<string, unknown>,
  next: Record<string, unknown> | null,
) {
  const rows: { label: string; value: string }[] = [];
  const add = (label: string, value: unknown, nextValue: unknown, suffix = '') => {
    if (value == null || value === '' || value === 0) return;
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
  add(
    'Attack speed',
    numberMap(level.attack_speed, 1000),
    numberMap(next?.attack_speed, 1000),
    's',
  );
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
  add('DPS', level.dps, next?.dps);
  add('Damage', level.damage, next?.damage);
  add('HP', level.hitpoints, next?.hitpoints);
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
  return ImageAssets.getHomeVillageBuildingImage(name, 1);
}
function unlockImage(section: string, name: string) {
  return section === 'spells'
    ? ImageAssets.getSpellImage(name)
    : section === 'pets'
      ? ImageAssets.getPetImage(name)
      : ImageAssets.getTroopImage(name);
}
function isSuperTroop(item: Record<string, unknown>) {
  return (
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
  const number = Number(value);
  return Number.isFinite(number) ? String(Math.round((number / divisor) * 100) / 100) : null;
}
function tileValue(value: unknown) {
  return numberMap(value, 1000);
}
function movementSpeed(value: unknown) {
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
  levelSliderWrap: { gap: 2 },
  levelSlider: { height: 34, justifyContent: 'center', marginHorizontal: 7 },
  levelSliderTrack: { height: 5, borderRadius: 999, backgroundColor: '#80808044' },
  levelSliderFill: {
    position: 'absolute',
    left: 0,
    height: 5,
    borderRadius: 999,
    backgroundColor: '#4F91FF',
  },
  levelSliderThumb: {
    position: 'absolute',
    width: 14,
    height: 14,
    marginLeft: -7,
    borderRadius: 7,
    backgroundColor: '#4F91FF',
  },
  levelLabels: { flexDirection: 'row', justifyContent: 'space-between' },
  wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
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
