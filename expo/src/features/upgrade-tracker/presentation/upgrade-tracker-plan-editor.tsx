import { useCallback, useMemo, useState } from 'react';
import { Modal, PanResponder, Pressable, StyleSheet, Switch, View } from 'react-native';
import { ChevronDown, GripVertical, X } from 'lucide-react-native';
import {
  NestableDraggableFlatList,
  NestableScrollContainer,
  ScaleDecorator,
} from 'react-native-draggable-flatlist';

import { CKText, PillSurface, PressableSurface, Surface, ckRadius, useCKTheme } from '../../../ui';
import {
  UpgradeCategory,
  UpgradePlanGoal,
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

export function UpgradeTrackerPlanEditor({
  visible,
  snapshot,
  preferences,
  onClose,
  onSave,
}: {
  visible: boolean;
  snapshot: UpgradeTrackerSnapshot;
  preferences: UpgradePlanPreferencesType;
  onClose: () => void;
  onSave: (value: UpgradePlanPreferencesType) => void;
}) {
  const theme = useCKTheme();
  const [draft, setDraft] = useState(preferences);
  const sections = useMemo(
    () =>
      [
        {
          title: 'Builders',
          subtitle: 'Construction and hero upgrades',
          queue: UpgradeQueue.builders,
          toggle: draft.prioritizeUnbuiltBuilders,
          setToggle: (value: boolean) =>
            updateDraft(draft, setDraft, { prioritizeUnbuiltBuilders: value }),
          villages: [UpgradeVillage.home, UpgradeVillage.builderBase],
        },
        {
          title: 'Laboratory',
          subtitle: 'Troops, spells and siege research',
          queue: UpgradeQueue.laboratory,
          toggle: draft.prioritizeUnbuiltLaboratory,
          setToggle: (value: boolean) =>
            updateDraft(draft, setDraft, { prioritizeUnbuiltLaboratory: value }),
          villages: [UpgradeVillage.home, UpgradeVillage.builderBase],
        },
        {
          title: 'Pets',
          subtitle: 'Pet House upgrades',
          queue: UpgradeQueue.pets,
          toggle: draft.prioritizeUnbuiltPets,
          setToggle: (value: boolean) =>
            updateDraft(draft, setDraft, { prioritizeUnbuiltPets: value }),
          villages: [UpgradeVillage.home],
        },
      ] as const,
    [draft],
  );
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={editorStyles.overlay}>
        <Surface radius={ckRadius.card} style={editorStyles.modal}>
          <View style={editorStyles.header}>
            <View style={editorStyles.grow}>
              <CKText role="titleLarge">Plan priorities</CKText>
              <CKText muted role="bodySmall">
                Rank what matters most. Upgrade levels and active work always stay in order.
              </CKText>
            </View>
            <Pressable accessibilityRole="button" accessibilityLabel="Close" onPress={onClose}>
              <X color={theme.onSurface} />
            </Pressable>
          </View>
          <NestableScrollContainer contentContainerStyle={editorStyles.content}>
            <RuleNote />
            <SectionTitle title="Planning goals" />
            <GoalSelector
              title="Home Village"
              value={draft.homeGoal}
              onChange={(homeGoal) => updateDraft(draft, setDraft, { homeGoal })}
            />
            <GoalSelector
              title="Builder Base"
              value={draft.builderBaseGoal}
              onChange={(builderBaseGoal) => updateDraft(draft, setDraft, { builderBaseGoal })}
            />
            {sections.map((section) => {
              const villageOrders = section.villages.map((village) => ({
                village,
                order: planQueueOrder(snapshot, draft, village, section.queue),
              }));
              if (!villageOrders.some(({ order }) => order.length)) return null;
              return (
                <View key={section.title} style={editorStyles.section}>
                  <SectionTitle title={section.title} />
                  <CKText muted role="labelSmall">
                    {section.subtitle}
                  </CKText>
                  <CompactToggle
                    label="Prioritize new items"
                    description="Place newly unlocked or unbuilt items first"
                    value={section.toggle}
                    onChange={section.setToggle}
                  />
                  {villageOrders.map(({ village, order }) => {
                    return order.length ? (
                      <View key={village} style={editorStyles.village}>
                        <CKText role="labelLarge">
                          {village === UpgradeVillage.home ? 'Home Village' : 'Builder Base'}
                        </CKText>
                        <PriorityList
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
              );
            })}
            <SectionTitle title="Walls" />
            <StepSlider
              label="Walls each week"
              value={draft.wallsPerWeek}
              minimum={0}
              maximum={20}
              lowLabel="Off"
              highLabel={`${draft.wallsPerWeek} / week`}
              onChange={(wallsPerWeek) => updateDraft(draft, setDraft, { wallsPerWeek })}
            />
            <CompactToggle
              label="Prefer Gold for walls"
              description="Use Gold before Elixir when spending walls"
              value={draft.wallResourcePreference === UpgradeWallResourcePreference.gold}
              onChange={(value) =>
                updateDraft(draft, setDraft, {
                  wallResourcePreference: value
                    ? UpgradeWallResourcePreference.gold
                    : UpgradeWallResourcePreference.elixir,
                })
              }
            />
            <PressableSurface
              accessibilityRole="button"
              onPress={() => onSave(draft)}
              style={editorStyles.primaryAction}
            >
              <CKText>Apply priorities</CKText>
            </PressableSurface>
          </NestableScrollContainer>
        </Surface>
      </View>
    </Modal>
  );
}

function PriorityList({
  order,
  targets,
  shares,
  onReorder,
  onTarget,
  onShare,
}: {
  order: readonly UpgradeCategoryValue[];
  targets: ReadonlyMap<UpgradeCategoryValue, number>;
  shares: ReadonlyMap<UpgradeCategoryValue, number>;
  onReorder: (order: readonly UpgradeCategoryValue[]) => void;
  onTarget: (category: UpgradeCategoryValue, target: number) => void;
  onShare: (category: UpgradeCategoryValue, share: number) => void;
}) {
  const theme = useCKTheme();
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
      <NestableDraggableFlatList
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
            <ScaleDecorator activeScale={1.01}>
              <View style={[editorStyles.priorityRow, isActive && editorStyles.activePriorityRow]}>
                <View style={editorStyles.tier}>
                  <CKText role="labelSmall">{tier}</CKText>
                </View>
                <View style={editorStyles.grow}>
                  <CKText role="rowTitle">{categoryLabel(category)}</CKText>
                  <CKText muted role="labelSmall">
                    {share > 0
                      ? `Tier ${tier} · shared mix ${normalized}% (${share}/${sharedWeightTotal})`
                      : `Tier ${tier} · strict`}
                    {' · '}
                    {target >= 100 ? 'runs until maxed' : `yields after ${target}%`}
                  </CKText>
                  <View style={editorStyles.priorityControls}>
                    <PillButton
                      label={share === 0 ? 'Strict' : `${share}%`}
                      selected={share > 0}
                      onPress={() => setMenu({ category, kind: 'share' })}
                      compact
                    />
                    <PillButton
                      label={target === 100 ? 'Max' : `${target}%`}
                      selected={target < 100}
                      onPress={() => setMenu({ category, kind: 'target' })}
                      compact
                    />
                  </View>
                </View>
                <View style={editorStyles.reorder}>
                  <Pressable
                    accessibilityRole="button"
                    accessibilityLabel={`Reorder ${categoryLabel(category)}`}
                    disabled={isActive}
                    delayLongPress={150}
                    onLongPress={drag}
                    testID={`upgrade-priority-drag-${category}`}
                  >
                    <GripVertical size={18} color={theme.onSurfaceVariant} />
                  </Pressable>
                </View>
              </View>
            </ScaleDecorator>
          );
        }}
      />
      <Modal
        visible={menu !== null}
        transparent
        animationType="fade"
        onRequestClose={() => setMenu(null)}
      >
        <Pressable style={editorStyles.menuOverlay} onPress={() => setMenu(null)}>
          <Surface radius={ckRadius.card} style={editorStyles.menuCard}>
            <CKText role="sectionTitle">
              {menu?.kind === 'share' ? 'Relative tier weight' : 'Completion target'}
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
                      ? 'Strict tier'
                      : `Weight ${value}%`
                    : value === 100
                      ? 'Until maxed'
                      : `Until ${value}%`}
                </CKText>
              </PressableSurface>
            ))}
          </Surface>
        </Pressable>
      </Modal>
    </View>
  );
}

function RuleNote() {
  return (
    <Surface radius={ckRadius.tile} style={editorStyles.note}>
      <CKText muted role="bodySmall">
        Numbered tiers run first. Shared rows keep the same tier number, and their mix is normalized
        from the relative weights, so 50 + 25 becomes 67% / 33%. A target makes a category yield
        after it reaches that percentage while it stays eligible later.
      </CKText>
    </Surface>
  );
}

function GoalSelector({
  title,
  value,
  onChange,
}: {
  title: string;
  value: string;
  onChange: (value: (typeof UpgradePlanGoal)[keyof typeof UpgradePlanGoal]) => void;
}) {
  const theme = useCKTheme();
  const [open, setOpen] = useState(false);
  return (
    <View style={editorStyles.village}>
      <CKText muted role="labelSmall">
        {title}
      </CKText>
      <PressableSurface
        accessibilityRole="button"
        accessibilityLabel={`${title}: ${goalLabel(value)}`}
        accessibilityState={{ expanded: open }}
        onPress={() => setOpen(true)}
        style={editorStyles.dropdown}
      >
        <CKText style={editorStyles.grow}>{goalLabel(value)}</CKText>
        <ChevronDown size={18} color={theme.onSurfaceVariant} />
      </PressableSurface>
      <Modal visible={open} transparent animationType="fade" onRequestClose={() => setOpen(false)}>
        <Pressable style={editorStyles.menuOverlay} onPress={() => setOpen(false)}>
          <Surface radius={ckRadius.card} style={editorStyles.menuCard}>
            {Object.values(UpgradePlanGoal).map((goal) => (
              <PressableSurface
                key={goal}
                accessibilityRole="button"
                accessibilityState={{ selected: value === goal }}
                onPress={() => {
                  onChange(goal);
                  setOpen(false);
                }}
                style={editorStyles.menuItem}
              >
                <CKText>{goalLabel(goal)}</CKText>
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
        <CKText role="labelLarge">{label}</CKText>
        <CKText muted role="labelSmall">
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
        <CKText role="labelSmall">{label}</CKText>
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

function goalLabel(goal: string) {
  if (goal === UpgradePlanGoal.maxCurrentHall) return 'Max before advancing';
  if (goal === UpgradePlanGoal.rushNextHall) return 'Reach the next hall quickly';
  if (goal === UpgradePlanGoal.catchUp) return 'Catch up rushed levels';
  return 'Unlock new things first';
}
function categoryLabel(category: string) {
  const labels: Record<string, string> = {
    defenses: 'Defenses',
    guardians: 'Guardians',
    craftedDefenses: 'Crafted defenses',
    traps: 'Traps',
    army: 'Army',
    resources: 'Resources',
    troops: 'Troops',
    darkTroops: 'Dark troops',
    spells: 'Spells',
    sieges: 'Sieges',
    heroes: 'Heroes',
    equipment: 'Equipment',
    pets: 'Pets',
    walls: 'Walls',
    builders: 'Builders',
    supercharge: 'Supercharge',
  };
  return labels[category] ?? category;
}
const editorStyles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#00000070' },
  modal: { height: '92%', width: '100%', maxWidth: 820, alignSelf: 'center', padding: 16 },
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
    alignItems: 'flex-start',
    gap: 8,
    paddingVertical: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderColor: '#80808055',
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
  reorder: { alignItems: 'center', gap: 2 },
  priorityControls: { flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 5 },
  dropdown: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
  },
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
  primaryAction: { minHeight: 50, alignItems: 'center', justifyContent: 'center', padding: 12 },
});
