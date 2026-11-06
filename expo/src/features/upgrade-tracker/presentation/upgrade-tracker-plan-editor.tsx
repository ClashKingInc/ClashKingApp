import { modalOrientations } from '../../../ui/modal-orientations';
import {
  type ViewInstance,
  type ScrollViewInstance,
  Modal,
  PanResponder,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  View,
  type ScrollViewProps,
} from 'react-native';
import { createContext, useCallback, useContext, useMemo, useRef, useState } from 'react';
import { GripVertical, SlidersHorizontal, X } from 'lucide-react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { trackerCategoryImage, trackerCategoryImageScale } from './tracker-category-art';
import { InfoTooltip } from '../../../ui/info-tooltip';
import { MobileWebImage } from '../../../ui/mobile-web-image';
import DraggableFlatList, { type DraggableFlatListProps } from 'react-native-draggable-flatlist';
import { runOnJS, useAnimatedReaction, useSharedValue } from 'react-native-reanimated';
import { CARD_REORDER_HOLD_MS, DragJiggle } from '../../../ui/drag-jiggle';

import { useI18n } from '../../../i18n';
import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { ReservedRegionLayout } from '../../../ui/reserved-region-layout';
import { CKText, PillSurface, PressableSurface, Surface, ckRadius, useCKTheme } from '../../../ui';
import {
  UpgradeCategory,
  UpgradePlanPreferences,
  UpgradeQueue,
  UpgradeVillage,
  UpgradeWallResourcePreference,
  type UpgradeCategoryValue,
  type UpgradePlanPreferences as UpgradePlanPreferencesType,
  type UpgradeQueueValue,
  type UpgradeTrackerSnapshot,
  type UpgradeVillageValue,
} from '../models';

type PriorityScrollState = {
  viewport: React.RefObject<ViewInstance | null>;
  scroll: React.RefObject<ScrollViewInstance | null>;
  offset: ReturnType<typeof useSharedValue<number>>;
  height: ReturnType<typeof useSharedValue<number>>;
  contentHeight: ReturnType<typeof useSharedValue<number>>;
  setDragging: (dragging: boolean) => void;
};
const PriorityScrollContext = createContext<PriorityScrollState | null>(null);

function PriorityScrollContainer({ children, ...props }: ScrollViewProps) {
  const viewport = useRef<ViewInstance>(null);
  const scroll = useRef<ScrollViewInstance>(null);
  const offset = useSharedValue(0);
  const height = useSharedValue(0);
  const contentHeight = useSharedValue(0);
  const [dragging, setDragging] = useState(false);
  return (
    <PriorityScrollContext.Provider
      value={{ viewport, scroll, offset, height, contentHeight, setDragging }}
    >
      <View
        ref={viewport}
        collapsable={false}
        style={{ flex: 1 }}
        onLayout={(event) => {
          height.value = event.nativeEvent.layout.height;
        }}
      >
        <ScrollView
          {...props}
          ref={scroll}
          scrollEnabled={!dragging}
          scrollEventThrottle={16}
          onScroll={(event) => {
            offset.value = event.nativeEvent.contentOffset.y;
          }}
          onContentSizeChange={(_width, nextHeight) => {
            contentHeight.value = nextHeight;
          }}
        >
          {children}
        </ScrollView>
      </View>
    </PriorityScrollContext.Provider>
  );
}

function PriorityDraggableList<T>(props: DraggableFlatListProps<T>) {
  const parent = useContext(PriorityScrollContext);
  if (!parent) throw new Error('PriorityDraggableList requires PriorityScrollContainer');
  const { viewport, scroll, offset, height, contentHeight, setDragging } = parent;
  const listTop = useSharedValue(0);
  const [animValues, setAnimValues] = useState<
    Parameters<NonNullable<DraggableFlatListProps<T>['onAnimValInit']>>[0] | null
  >(null);
  const dragging = useSharedValue(false);
  const pendingTarget = useSharedValue(-1);
  const scrollOuter = useCallback(
    (y: number) => scroll.current?.scrollTo({ y, animated: true }),
    [scroll],
  );
  useAnimatedReaction(
    () => {
      if (!dragging.value || !animValues?.isTouchActiveNative.value || height.value <= 0) return -1;
      if (pendingTarget.value >= 0 && Math.abs(pendingTarget.value - offset.value) > 2) return -1;
      const top = listTop.value + animValues.hoverOffset.value - offset.value;
      const bottom = height.value - top - animValues.activeCellSize.value;
      if (top < 48) return Math.max(0, offset.value - 80);
      if (bottom < 48)
        return Math.min(Math.max(0, contentHeight.value - height.value), offset.value + 80);
      return -1;
    },
    (target) => {
      if (target < 0 || Math.abs(target - offset.value) < 2) return;
      pendingTarget.value = target;
      runOnJS(scrollOuter)(target);
    },
    [scrollOuter, animValues],
  );
  return (
    <DraggableFlatList
      {...props}
      scrollEnabled={false}
      outerScrollOffset={offset}
      activationDistance={20}
      onContainerLayout={({ containerRef }) => {
        // RN Fabric requires host refs for measureLayout; the library's nesting adapter passes a
        // numeric findNodeHandle. Window measurements also avoid measuring through a composite ScrollView.
        containerRef.current?.measureInWindow((_x, y) => {
          viewport.current?.measureInWindow((_outerX, outerY) => {
            listTop.value = y - outerY + offset.value;
          });
        });
      }}
      onAnimValInit={(values) => {
        // Keep the library's UI-thread shared values, including touch release, for edge auto-scroll.
        setAnimValues(values);
        props.onAnimValInit?.(values);
      }}
      onDragBegin={(index) => {
        setDragging(true);
        dragging.value = true;
        pendingTarget.set(-1);
        props.onDragBegin?.(index);
      }}
      onRelease={(index) => {
        dragging.value = false;
        props.onRelease?.(index);
      }}
      onDragEnd={(result) => {
        dragging.value = false;
        setDragging(false);
        props.onDragEnd?.(result);
      }}
    />
  );
}

export function planQueueOrder(
  snapshot: UpgradeTrackerSnapshot,
  preferences: UpgradePlanPreferencesType,
  village: UpgradeVillageValue,
  queue: UpgradeQueueValue,
) {
  const available = new Set<UpgradeCategoryValue>(
    snapshot
      .itemsFor({ village, queue })
      .map((item) => item.category)
      .filter((category) => category !== UpgradeCategory.builders),
  );
  const saved = preferences.orderFor(village);
  return [
    ...saved.filter((category) => available.has(category)),
    ...Object.values(UpgradeCategory).filter(
      (category) => available.has(category) && !saved.includes(category),
    ),
  ];
}

export function replacePlanQueueOrder(
  snapshot: UpgradeTrackerSnapshot,
  saved: readonly UpgradeCategoryValue[],
  village: UpgradeVillageValue,
  queue: UpgradeQueueValue,
  queueOrder: readonly UpgradeCategoryValue[],
) {
  const queueCategories = new Set<UpgradeCategoryValue>(
    snapshot
      .itemsFor({ village, queue })
      .map((item) => item.category)
      .filter((category) => category !== UpgradeCategory.builders),
  );
  return [...saved.filter((category) => !queueCategories.has(category)), ...queueOrder];
}

export function priorityTierForOrder(
  order: readonly UpgradeCategoryValue[],
  shares: ReadonlyMap<UpgradeCategoryValue, number>,
  target: UpgradeCategoryValue,
) {
  let tier = 0;
  let previousWasShared = false;
  for (const category of order) {
    const shared = (shares.get(category) ?? 0) > 0;
    if (tier === 0 || !shared || !previousWasShared) tier += 1;
    if (category === target) return tier;
    previousWasShared = shared;
  }
  return 999;
}

type PlanEditorProps = {
  visible: boolean;
  snapshot: UpgradeTrackerSnapshot;
  preferences: UpgradePlanPreferencesType;
  onClose: () => void;
  onSave: (value: UpgradePlanPreferencesType) => void;
};

export function UpgradeTrackerPlanEditor({
  visible,
  snapshot,
  preferences,
  onClose,
  onSave,
}: PlanEditorProps) {
  const theme = useCKTheme();
  const [draft, setDraft] = useState(preferences);
  return (
    <Modal
      supportedOrientations={modalOrientations}
      visible={visible}
      presentationStyle="fullScreen"
      animationType="fade"
      onRequestClose={onClose}
      onShow={() => setDraft(preferences)}
    >
      {/* Keep the gesture root and its full-window background outside the pane. */}
      <GestureHandlerRootView style={[editorStyles.overlay, { backgroundColor: theme.background }]}>
        <ReservedRegionLayout>
          <PlanEditorContent
            snapshot={snapshot}
            draft={draft}
            setDraft={setDraft}
            onClose={onClose}
            onSave={onSave}
          />
        </ReservedRegionLayout>
      </GestureHandlerRootView>
    </Modal>
  );
}

function PlanEditorContent({
  snapshot,
  draft,
  setDraft,
  onClose,
  onSave,
}: {
  snapshot: UpgradeTrackerSnapshot;
  draft: UpgradePlanPreferencesType;
  setDraft: (value: UpgradePlanPreferencesType) => void;
  onClose: () => void;
  onSave: (value: UpgradePlanPreferencesType) => void;
}) {
  const theme = useCKTheme();
  const { t } = useI18n();
  const insets = useSafeAreaInsets();
  const layout = useAdaptiveLayout();
  const expanded = layout.isExpanded;
  const sections = useMemo(
    () =>
      [
        {
          title: t('dashboardUpgradeTrackerBuilders'),
          subtitle: t('upgradeTrackerPlanConstructionSubtitle'),
          queue: UpgradeQueue.builders,
          toggle: draft.prioritizeUnbuiltBuilders,
          setToggle: (value: boolean) =>
            updateDraft(draft, setDraft, { prioritizeUnbuiltBuilders: value }),
          villages: [UpgradeVillage.home, UpgradeVillage.builderBase],
        },
        {
          title: t('upgradeTrackerLaboratory'),
          subtitle: t('upgradeTrackerPlanResearchSubtitle'),
          queue: UpgradeQueue.laboratory,
          toggle: draft.prioritizeUnbuiltLaboratory,
          setToggle: (value: boolean) =>
            updateDraft(draft, setDraft, { prioritizeUnbuiltLaboratory: value }),
          villages: [UpgradeVillage.home, UpgradeVillage.builderBase],
        },
        {
          title: t('upgradeTrackerPets'),
          subtitle: t('upgradeTrackerPlanPetHouseSubtitle'),
          queue: UpgradeQueue.pets,
          toggle: draft.prioritizeUnbuiltPets,
          setToggle: (value: boolean) =>
            updateDraft(draft, setDraft, { prioritizeUnbuiltPets: value }),
          villages: [UpgradeVillage.home],
        },
      ] as const,
    [draft, t, setDraft],
  );
  return (
    <Surface
      radius={0}
      style={[
        editorStyles.modal,
        { paddingTop: insets.top + 12, paddingBottom: insets.bottom + 12 },
        layout.isDuo &&
          !expanded && {
            paddingLeft: insets.left + 16,
            paddingRight: insets.right + 16,
          },
        expanded && {
          maxWidth: layout.contentMaxWidth,
          paddingLeft: insets.left + 24,
          paddingRight: insets.right + 24,
        },
      ]}
    >
      <View style={editorStyles.header}>
        <View style={editorStyles.grow}>
          <CKText role="titleLarge">{t('upgradeTrackerPlanPrioritiesTitle')}</CKText>
        </View>
        <InfoTooltip
          label={t('upgradeTrackerPlanPrioritiesTitle')}
          message={t('upgradeTrackerPlanRuleNote')}
        />
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('upgradeTrackerPlanClose')}
          onPress={onClose}
        >
          <X color={theme.onSurface} />
        </Pressable>
      </View>
      <PriorityScrollContainer contentContainerStyle={editorStyles.content}>
        {sections.map((section) => {
          const villageOrders = section.villages.map((village) => ({
            village,
            order: planQueueOrder(snapshot, draft, village, section.queue),
          }));
          if (!villageOrders.some(({ order }) => order.length)) return null;
          return (
            <View key={section.title} style={editorStyles.section}>
              {section.queue !== UpgradeQueue.builders ? (
                <SectionTitle title={section.title} />
              ) : null}
              <CompactToggle
                label={t('upgradeTrackerPlanPrioritizeNewItems')}
                description={t('upgradeTrackerPlanPrioritizeNewDescription')}
                value={section.toggle}
                onChange={section.setToggle}
              />
              <View
                style={
                  expanded
                    ? { flexDirection: 'row', gap: 24, alignItems: 'flex-start' }
                    : { gap: 5 }
                }
              >
                {villageOrders.map(({ village, order }) => {
                  return order.length ? (
                    <View
                      key={village}
                      style={[editorStyles.village, expanded && { flex: 1, minWidth: 0 }]}
                    >
                      <CKText role="labelLarge">
                        {village === UpgradeVillage.home
                          ? t('upgradeTrackerHomeVillage')
                          : t('upgradeTrackerBuilderBase')}
                      </CKText>
                      <PriorityList
                        snapshot={snapshot}
                        village={village}
                        order={order}
                        targets={
                          village === UpgradeVillage.home
                            ? draft.homeCategoryTargets
                            : draft.builderBaseCategoryTargets
                        }
                        shares={
                          village === UpgradeVillage.home
                            ? draft.homeCategoryShares
                            : draft.builderBaseCategoryShares
                        }
                        onReorder={(next) => {
                          const replacement = replacePlanQueueOrder(
                            snapshot,
                            draft.orderFor(village),
                            village,
                            section.queue,
                            next,
                          );
                          updateDraft(draft, setDraft, {
                            ...(village === UpgradeVillage.home
                              ? { homeCategoryOrder: replacement }
                              : { builderBaseCategoryOrder: replacement }),
                          });
                        }}
                        onTarget={(category, target) =>
                          updateMap(draft, setDraft, village, 'target', category, target)
                        }
                        onShare={(category, share) =>
                          updateMap(draft, setDraft, village, 'share', category, share)
                        }
                      />
                    </View>
                  ) : null;
                })}
              </View>
            </View>
          );
        })}
        <SectionTitle title={t('upgradeTrackerWalls')} />
        <StepSlider
          label={t('upgradeTrackerPlanWallsEachWeek')}
          value={draft.wallsPerWeek}
          minimum={0}
          maximum={20}
          lowLabel={t('upgradeTrackerPlanOff')}
          highLabel={t('upgradeTrackerPlanPerWeek', { count: draft.wallsPerWeek })}
          onChange={(wallsPerWeek) => updateDraft(draft, setDraft, { wallsPerWeek })}
        />
        <CompactToggle
          label={t('upgradeTrackerPlanPreferGold')}
          description={t('upgradeTrackerPlanPreferGoldDescription')}
          value={draft.wallResourcePreference === UpgradeWallResourcePreference.gold}
          onChange={(value) =>
            updateDraft(draft, setDraft, {
              wallResourcePreference: value
                ? UpgradeWallResourcePreference.gold
                : UpgradeWallResourcePreference.elixir,
            })
          }
        />
      </PriorityScrollContainer>
      <PressableSurface
        accessibilityRole="button"
        onPress={() => onSave(draft)}
        style={editorStyles.primaryAction}
      >
        <CKText>{t('upgradeTrackerPlanApplyPriorities')}</CKText>
      </PressableSurface>
    </Surface>
  );
}

function PriorityList({
  snapshot,
  village,
  order,
  targets,
  shares,
  onReorder,
  onTarget,
  onShare,
}: {
  snapshot: UpgradeTrackerSnapshot;
  village: UpgradeVillageValue;
  order: readonly UpgradeCategoryValue[];
  targets: ReadonlyMap<UpgradeCategoryValue, number>;
  shares: ReadonlyMap<UpgradeCategoryValue, number>;
  onReorder: (order: readonly UpgradeCategoryValue[]) => void;
  onTarget: (category: UpgradeCategoryValue, target: number) => void;
  onShare: (category: UpgradeCategoryValue, share: number) => void;
}) {
  const theme = useCKTheme();
  const { t } = useI18n();
  const [expandedCategory, setExpandedCategory] = useState<UpgradeCategoryValue | null>(null);
  const [menu, setMenu] = useState<{
    category: UpgradeCategoryValue;
    kind: 'share' | 'target';
  } | null>(null);
  const menuValue = menu
    ? menu.kind === 'share'
      ? (shares.get(menu.category) ?? 0)
      : (targets.get(menu.category) ?? 100)
    : 0;
  const menuOptions = menu?.kind === 'share' ? [0, 20, 25, 33, 50, 67, 75, 80] : [50, 75, 90, 100];
  return (
    <View>
      <PriorityDraggableList
        data={[...order]}
        keyExtractor={(category) => category}
        onDragEnd={({ data, from, to }) => {
          if (from !== to) onReorder(data);
        }}
        renderItem={({ item: category, drag, isActive }) => {
          const target = targets.get(category) ?? 100;
          const share = shares.get(category) ?? 0;
          const tier = priorityTierForOrder(order, shares, category);
          const sharedWeightTotal = order
            .filter((candidate) => priorityTierForOrder(order, shares, candidate) === tier)
            .reduce((sum, candidate) => sum + Math.max(0, shares.get(candidate) ?? 0), 0);
          const normalized =
            share > 0 && sharedWeightTotal > 0 ? Math.round((share * 100) / sharedWeightTotal) : 0;
          return (
            <DragJiggle active={isActive} scale={1.01}>
              <View style={[editorStyles.priorityRow, isActive && editorStyles.activePriorityRow]}>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={t('upgradeTrackerPlanReorder', {
                    category: categoryLabel(category, t),
                  })}
                  disabled={isActive}
                  delayLongPress={CARD_REORDER_HOLD_MS}
                  onLongPress={drag}
                  style={editorStyles.reorder}
                  testID={`upgrade-priority-drag-${category}`}
                >
                  <GripVertical size={20} color={theme.onSurfaceVariant} />
                </Pressable>
                <View style={editorStyles.tier}>
                  <CKText role="metadata">{tier}</CKText>
                </View>
                <MobileWebImage
                  imageUrl={trackerCategoryImage(category, village)}
                  style={{
                    width: 38,
                    height: 38,
                    transform: [{ scale: trackerCategoryImageScale(category) }],
                  }}
                />
                <View style={editorStyles.grow}>
                  <CKText role="rowTitle">{categoryLabel(category, t)}</CKText>
                  {expandedCategory === category ? (
                    <>
                      <CKText muted role="metadata">
                        {share > 0
                          ? t('upgradeTrackerPlanSharedSummary', {
                              tier,
                              normalized,
                              share,
                              total: sharedWeightTotal,
                              completion:
                                target >= 100
                                  ? t('upgradeTrackerPlanRunsUntilMaxed')
                                  : t('upgradeTrackerPlanYieldsAfter', { target }),
                            })
                          : t('upgradeTrackerPlanStrictSummary', {
                              tier,
                              completion:
                                target >= 100
                                  ? t('upgradeTrackerPlanRunsUntilMaxed')
                                  : t('upgradeTrackerPlanYieldsAfter', { target }),
                            })}
                      </CKText>
                      <View style={editorStyles.priorityControls}>
                        <PillButton
                          label={share === 0 ? t('upgradeTrackerPlanStrict') : `${share}%`}
                          selected={share > 0}
                          onPress={() => setMenu({ category, kind: 'share' })}
                          compact
                        />
                        <PillButton
                          label={target === 100 ? t('upgradeTrackerPlanMax') : `${target}%`}
                          selected={target < 100}
                          onPress={() => setMenu({ category, kind: 'target' })}
                          compact
                        />
                      </View>
                    </>
                  ) : share > 0 || target < 100 ? (
                    <CKText role="metadata" muted>
                      {share > 0 ? `${share}% · ` : ''}
                      {target < 100 ? `${target}%` : t('upgradeTrackerPlanMax')}
                    </CKText>
                  ) : null}
                </View>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={t('upgradeTrackerPlanPrioritiesTitle')}
                  accessibilityState={{ expanded: expandedCategory === category }}
                  style={editorStyles.reorder}
                  onPress={() =>
                    setExpandedCategory(expandedCategory === category ? null : category)
                  }
                >
                  <SlidersHorizontal size={18} color={theme.onSurfaceVariant} />
                </Pressable>
              </View>
            </DragJiggle>
          );
        }}
      />
      <Modal
        supportedOrientations={modalOrientations}
        visible={menu !== null}
        transparent
        animationType="fade"
        onRequestClose={() => setMenu(null)}
      >
        <Pressable style={editorStyles.menuOverlay} onPress={() => setMenu(null)}>
          <Surface radius={ckRadius.card} style={editorStyles.menuCard}>
            <CKText role="sectionTitle">
              {menu?.kind === 'share'
                ? t('upgradeTrackerPlanRelativeTierWeight')
                : t('upgradeTrackerPlanCompletionTarget')}
            </CKText>
            {menuOptions.map((value) => (
              <PressableSurface
                key={value}
                accessibilityRole="button"
                accessibilityState={{ selected: menuValue === value }}
                onPress={() => {
                  if (!menu) return;
                  if (menu.kind === 'share') onShare(menu.category, value);
                  else onTarget(menu.category, value);
                  setMenu(null);
                }}
                style={editorStyles.menuItem}
              >
                <CKText>
                  {menu?.kind === 'share'
                    ? value === 0
                      ? t('upgradeTrackerPlanStrictTier')
                      : t('upgradeTrackerPlanWeight', { value })
                    : value === 100
                      ? t('upgradeTrackerPlanUntilMaxed')
                      : t('upgradeTrackerPlanUntilPercent', { value })}
                </CKText>
              </PressableSurface>
            ))}
          </Surface>
        </Pressable>
      </Modal>
    </View>
  );
}

function CompactToggle({
  label,
  description,
  value,
  onChange,
}: {
  label: string;
  description: string;
  value: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <View style={editorStyles.toggle}>
      <View style={editorStyles.grow}>
        <CKText role="bodyMedium">{label}</CKText>
        <CKText muted role="metadata">
          {description}
        </CKText>
      </View>
      <Switch value={value} onValueChange={onChange} />
    </View>
  );
}

function StepSlider({
  label,
  value,
  minimum,
  maximum,
  lowLabel,
  highLabel,
  onChange,
}: {
  label: string;
  value: number;
  minimum: number;
  maximum: number;
  lowLabel: string;
  highLabel: string;
  onChange: (value: number) => void;
}) {
  const [width, setWidth] = useState(0);
  const range = maximum - minimum;
  const updateFromPosition = useCallback(
    (position: number) => {
      if (width <= 0 || range <= 0) return;
      onChange(
        Math.max(minimum, Math.min(maximum, Math.round(minimum + (position / width) * range))),
      );
    },
    [maximum, minimum, onChange, range, width],
  );
  const responder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: (event) => updateFromPosition(event.nativeEvent.locationX),
        onPanResponderMove: (event) => updateFromPosition(event.nativeEvent.locationX),
      }),
    [updateFromPosition],
  );
  const fraction = range <= 0 ? 0 : (value - minimum) / range;
  return (
    <View style={editorStyles.village}>
      <CKText role="rowTitle">{label}</CKText>
      <View
        accessibilityRole="adjustable"
        accessibilityLabel={label}
        accessibilityValue={{ min: minimum, max: maximum, now: value, text: highLabel }}
        onAccessibilityAction={(event) => {
          if (event.nativeEvent.actionName === 'increment') onChange(Math.min(maximum, value + 1));
          if (event.nativeEvent.actionName === 'decrement') onChange(Math.max(minimum, value - 1));
        }}
        accessibilityActions={[{ name: 'increment' }, { name: 'decrement' }]}
        onLayout={(event) => setWidth(event.nativeEvent.layout.width)}
        style={editorStyles.slider}
        {...responder.panHandlers}
      >
        <View style={editorStyles.sliderTrack} />
        <View
          style={[
            editorStyles.sliderFill,
            { width: `${Math.max(0, Math.min(1, fraction)) * 100}%` },
          ]}
        />
        <View
          style={[
            editorStyles.sliderThumb,
            { left: `${Math.max(0, Math.min(1, fraction)) * 100}%` },
          ]}
        />
      </View>
      <View style={editorStyles.sliderLabels}>
        <CKText muted role="labelSmall">
          {lowLabel}
        </CKText>
        <CKText muted role="labelSmall">
          {highLabel}
        </CKText>
      </View>
    </View>
  );
}

function PillButton({
  label,
  selected,
  onPress,
  compact = false,
}: {
  label: string;
  selected: boolean;
  onPress: () => void;
  compact?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <Pressable onPress={onPress}>
      <PillSurface
        style={[
          editorStyles.pill,
          compact && editorStyles.compactPill,
          selected && { borderColor: theme.primary },
        ]}
      >
        <CKText role="metadata">{label}</CKText>
      </PillSurface>
    </Pressable>
  );
}

function SectionTitle({ title }: { title: string }) {
  return <CKText role="sectionTitle">{title}</CKText>;
}

function updateDraft(
  current: UpgradePlanPreferencesType,
  setDraft: (value: UpgradePlanPreferencesType) => void,
  patch: Partial<ConstructorParameters<typeof UpgradePlanPreferences>[0]>,
) {
  setDraft(new UpgradePlanPreferences({ ...preferencesOptions(current), ...patch }));
}

function updateMap(
  current: UpgradePlanPreferencesType,
  setDraft: (value: UpgradePlanPreferencesType) => void,
  village: UpgradeVillageValue,
  kind: 'target' | 'share',
  category: UpgradeCategoryValue,
  value: number,
) {
  const source = new Map(
    kind === 'target'
      ? village === UpgradeVillage.home
        ? current.homeCategoryTargets
        : current.builderBaseCategoryTargets
      : village === UpgradeVillage.home
        ? current.homeCategoryShares
        : current.builderBaseCategoryShares,
  );
  if (kind === 'share' && value <= 0) source.delete(category);
  else source.set(category, value);
  updateDraft(
    current,
    setDraft,
    village === UpgradeVillage.home
      ? kind === 'target'
        ? { homeCategoryTargets: source }
        : { homeCategoryShares: source }
      : kind === 'target'
        ? { builderBaseCategoryTargets: source }
        : { builderBaseCategoryShares: source },
  );
}

function preferencesOptions(value: UpgradePlanPreferencesType) {
  return {
    // Retain legacy goal fields on save, but do not expose controls while the
    // planner forecasts current imported inventory rather than future halls.
    homeGoal: value.homeGoal,
    builderBaseGoal: value.builderBaseGoal,
    homeCategoryOrder: value.homeCategoryOrder,
    builderBaseCategoryOrder: value.builderBaseCategoryOrder,
    homeCategoryTargets: value.homeCategoryTargets,
    builderBaseCategoryTargets: value.builderBaseCategoryTargets,
    homeCategoryShares: value.homeCategoryShares,
    builderBaseCategoryShares: value.builderBaseCategoryShares,
    prioritizeUnbuiltBuilders: value.prioritizeUnbuiltBuilders,
    prioritizeUnbuiltLaboratory: value.prioritizeUnbuiltLaboratory,
    prioritizeUnbuiltPets: value.prioritizeUnbuiltPets,
    wallResourcePreference: value.wallResourcePreference,
    wallsPerWeek: value.wallsPerWeek,
  };
}

type Translate = ReturnType<typeof useI18n>['t'];

function categoryLabel(category: string, t: Translate) {
  const labels: Record<string, Parameters<Translate>[0]> = {
    defenses: 'warDefensesTitle',
    guardians: 'gameAssetsCategoryGuardians',
    craftedDefenses: 'upgradeTrackerPlanCategoryCraftedDefenses',
    traps: 'upgradeTrackerPlanCategoryTraps',
    army: 'upgradeTrackerPlanCategoryArmy',
    resources: 'assetFolderResources',
    troops: 'upgradeSectionTroops',
    darkTroops: 'upgradeTrackerPlanCategoryDarkTroops',
    spells: 'upgradeSectionSpells',
    sieges: 'upgradeTrackerPlanCategorySieges',
    heroes: 'upgradeSectionHeroes',
    equipment: 'upgradeTrackerEquipment',
    pets: 'upgradeTrackerPets',
    walls: 'upgradeTrackerWalls',
    builders: 'dashboardUpgradeTrackerBuilders',
    supercharge: 'upgradeTrackerPlanCategorySupercharge',
  };
  return labels[category] ? t(labels[category]) : category;
}
const editorStyles = StyleSheet.create({
  overlay: { flex: 1 },
  modal: { flex: 1, width: '100%', maxWidth: 820, alignSelf: 'center', padding: 16 },
  header: { flexDirection: 'row', alignItems: 'flex-start', gap: 10, paddingBottom: 8 },
  grow: { flex: 1 },
  content: { gap: 12, paddingBottom: 32 },
  note: { padding: 12 },
  wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  section: { gap: 5 },
  village: { gap: 6, marginTop: 5 },
  toggle: { minHeight: 52, flexDirection: 'row', alignItems: 'center', gap: 8 },
  priorityRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingVertical: 6,
    paddingRight: 4,
    marginVertical: 3,
    minHeight: 56,
    borderRadius: 16,
    backgroundColor: '#80808012',
  },
  activePriorityRow: { opacity: 0.9, backgroundColor: '#80808018' },
  tier: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#80808022',
    alignItems: 'center',
    justifyContent: 'center',
  },
  reorder: { width: 44, minHeight: 44, alignItems: 'center', justifyContent: 'center' },
  priorityControls: { flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 5 },
  menuOverlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
    backgroundColor: '#00000070',
  },
  menuCard: { width: '100%', maxWidth: 380, padding: 16, gap: 5 },
  menuItem: { minHeight: 44, justifyContent: 'center', paddingHorizontal: 12, paddingVertical: 8 },
  slider: { height: 40, justifyContent: 'center', marginHorizontal: 10 },
  sliderTrack: { height: 4, borderRadius: 2, backgroundColor: '#80808055' },
  sliderFill: {
    position: 'absolute',
    left: 0,
    height: 4,
    borderRadius: 2,
    backgroundColor: '#4F91FF',
  },
  sliderThumb: {
    position: 'absolute',
    width: 22,
    height: 22,
    marginLeft: -11,
    borderRadius: 11,
    backgroundColor: '#4F91FF',
  },
  sliderLabels: { flexDirection: 'row', justifyContent: 'space-between' },
  pill: { borderWidth: 1, borderColor: 'transparent', paddingHorizontal: 10, paddingVertical: 7 },
  compactPill: { paddingHorizontal: 7, paddingVertical: 4 },
  primaryAction: {
    minHeight: 50,
    marginTop: 12,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
  },
});
