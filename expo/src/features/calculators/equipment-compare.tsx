import { isDuoDevice, useAdaptiveLayout } from '../../ui/adaptive-layout';
import { CalculatorWorkspaceColumns } from './calculator-workspace-columns';
import { useMemo, useState, useSyncExternalStore, type ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { Copy, SlidersHorizontal, Trash2, X } from 'lucide-react-native';
import { gameDataState, subscribeToGameDataRevision } from '../../core/game-data/game-data-state';
import { ImageAssets } from '../../core/assets/image-assets';
import { localizedNameForItem } from '../../core/game-data/game-data-localization';
import { materialCloseLabel, toIntlLocale, useI18n } from '../../i18n';
import { LevelSlider } from '../../ui/level-slider';
import { SelectionPicker, SelectionPickerModal } from '../../ui/selection-picker';
import { CKText, EmptyState, MobileWebImage, Surface, colorWithAlpha, useCKTheme } from '../../ui';
import type { Player } from '../player/models';
import {
  abilityFieldLabel,
  formatAbilityValue,
} from '../upgrade-tracker/presentation/ability-details';
import { CalcChip, CalcHeader, CalcSelect, calcStyles as s } from './calculator-controls';
import { HeroCarousel, heroAccents } from './hero-carousel';
import { HeaderArtwork } from '../../ui/header-artwork';
import { CalculatorSelectionModal } from './calculator-selection-modal';
import {
  EquipmentComparisonCopy,
  type EquipmentComparisonExportData,
} from './equipment-comparison-export';
import {
  abilitiesFor,
  comparisonItems,
  compareMetric,
  equipmentMetrics,
  makePairs,
  type ComparisonItem,
  type ComparisonMetric,
  type Loadout,
} from './equipment-comparison';

function itemLabel(item: ComparisonItem) {
  return localizedNameForItem(item.raw) || item.name;
}

function GearImage({ item, size = 40 }: { item: ComparisonItem; size?: number }) {
  return (
    <MobileWebImage
      imageUrl={ImageAssets.getGearImage(item.name)}
      accessibilityLabel={itemLabel(item)}
      contentFit="contain"
      style={{ width: size, height: size }}
    />
  );
}

export function EquipmentCompare({
  players,
  onBack,
}: {
  players: readonly Player[];
  onBack: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const revision = useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const heroes = useMemo(() => {
    void revision;
    return comparisonItems(gameDataState.bundleData.heroes).filter(
      (item) => item.raw.village === 'home',
    );
  }, [revision]);
  const equipment = useMemo(() => {
    void revision;
    return comparisonItems(gameDataState.bundleData.equipment);
  }, [revision]);
  const [heroId, setHeroId] = useState('28000001');
  const hero = heroes.find((item) => item.id === heroId) ?? heroes[0];
  return (
    <View style={[s.page, { backgroundColor: theme.background }]} testID="equipment-compare">
      {hero ? (
        <EquipmentEditor
          key={revision}
          hero={hero}
          heroes={heroes}
          items={equipment.filter((item) => item.hero === hero.name)}
          players={players}
          onHero={setHeroId}
          onBack={onBack}
        />
      ) : (
        <EquipmentSafeContent enabled={isDuoDevice}>
          <View>
            <CalcHeader onBack={onBack} />
            <EmptyState title={t('damageNoStaticDataTitle')} body={t('damageNoStaticDataBody')} />
          </View>
        </EquipmentSafeContent>
      )}
    </View>
  );
}

function EquipmentEditor({
  hero,
  heroes,
  items,
  players,
  onHero,
  onBack,
}: {
  hero: ComparisonItem;
  heroes: ComparisonItem[];
  items: ComparisonItem[];
  players: readonly Player[];
  onHero: (id: string) => void;
  onBack: () => void;
}) {
  const insets = useSafeAreaInsets();
  const layout = useAdaptiveLayout();
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const number = new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 2 });
  const maxHero = Number(hero.levels.at(-1)!.level);
  const initialLevels = Object.fromEntries(
    items.map((item) => [item.id, Number(item.levels.at(-1)!.level)]),
  );
  const [heroLevel, setHeroLevel] = useState(maxHero);
  const [levels, setLevels] = useState<Record<string, number>>(initialLevels);
  const [pool, setPool] = useState(items.map((item) => item.id));
  const [rows, setRows] = useState<Loadout[]>(() => makePairs(items, initialLevels, maxHero));
  const [metrics, setMetrics] = useState(['dps', 'hitpoints', 'healing']);
  const [sortMetric, setSortMetric] = useState('dps');
  const [preset, setPreset] = useState('manual');
  const [levelAccountTag, setLevelAccountTag] = useState<string>();
  const [editingRow, setEditingRow] = useState<string>();
  const [attributesOpen, setAttributesOpen] = useState(false);
  const [pinOpen, setPinOpen] = useState(false);
  const [gradientHeight, setGradientHeight] = useState(700);
  const [pinned, setPinned] = useState('none');
  const [editorHeroId, setEditorHeroId] = useState(hero.id);
  // Reset hero-specific controls without remounting the editor/carousel. A
  // hero-keyed parent destroys every warm WebView even when its child keys stay
  // stable, making every selection show the initial loading spinner again.
  if (editorHeroId !== hero.id) {
    setEditorHeroId(hero.id);
    setHeroLevel(maxHero);
    setLevels(initialLevels);
    setPool(items.map((item) => item.id));
    setRows(makePairs(items, initialLevels, maxHero));
    setMetrics(['dps', 'hitpoints', 'healing']);
    setSortMetric('dps');
    setPreset('manual');
    setLevelAccountTag(undefined);
    setEditingRow(undefined);
    setAttributesOpen(false);
    setPinOpen(false);
    setPinned('none');
    // React retries this render before committing the scheduled state updates.
    // Do not evaluate old loadout IDs against the new hero's equipment first.
    return null;
  }
  const availablePlayers = players.filter((player) =>
    player.heroes.some((item) => item.name === hero.name && item.level > 0),
  );
  const levelAccount = players.find((player) => player.tag === levelAccountTag);
  const primaryMetrics: ComparisonMetric[] = [
    { id: 'dps', label: t('calcHeroDps') },
    { id: 'hitpoints', label: t('calcHeroHp') },
    { id: 'healing', label: t('calcActivationHealing') },
    { id: 'regeneration', label: t('calcRegeneration') },
  ];
  const allMetrics = [
    ...primaryMetrics.filter(
      (metric) =>
        metric.id === 'dps' ||
        metric.id === 'hitpoints' ||
        items.filter((item) => {
          const value = compareMetric(
            hero,
            items,
            {
              id: item.id,
              heroLevel: maxHero,
              equipment: [{ id: item.id, level: Number(item.levels.at(-1)!.level) }],
            },
            metric,
          );
          return typeof value === 'number' && value > 0;
        }).length >= 2,
    ),
    // A one-off equipment mechanic belongs in its detail sheet, not as an
    // almost-empty comparison column. Compare only compatible shared effects.
    ...equipmentMetrics(items)
      .filter((metric) => (metric.sources?.length ?? 0) >= 2)
      .map((metric) => {
        const source = metric.sources?.[0] ?? {
          equipmentId: metric.equipmentId!,
          abilityIndex: metric.abilityIndex ?? 0,
        };
        const item = items.find((item) => item.id === source.equipmentId)!;
        const abilities = abilitiesFor(item);
        const ability = abilities[source.abilityIndex]!;
        const stage =
          abilities.filter((entry) => entry.name === ability.name).length > 1
            ? ` ${source.abilityIndex + 1}`
            : '';
        return {
          ...metric,
          label: `${metric.sources ? '' : `${itemLabel(item)} · `}${ability.name}${stage} · ${abilityFieldLabel(metric.field!)}`,
        };
      }),
  ];
  const chosenMetrics = metrics
    .map((id) => allMetrics.find((metric) => metric.id === id))
    .filter((metric): metric is ComparisonMetric => Boolean(metric));
  // Hero level belongs to the whole comparison, never to an individual loadout.
  const sorted = rows
    .map((row) => ({ ...row, heroLevel }))
    .sort((a, b) => {
      const metric = allMetrics.find((metric) => metric.id === sortMetric) ?? primaryMetrics[0]!;
      const x = compareMetric(hero, items, a, metric),
        y = compareMetric(hero, items, b, metric);
      return typeof x === 'number' && typeof y === 'number'
        ? y - x || a.id.localeCompare(b.id)
        : a.id.localeCompare(b.id);
    });
  const displayed = sorted;
  const baseline: Loadout = { id: 'baseline', heroLevel, equipment: [] };
  const activeRow = rows.find((row) => row.id === editingRow);
  const regenerate = (
    nextPool = pool,
    nextLevels = levels,
    nextHero = heroLevel,
    nextPin = pinned,
  ) => {
    const pin = nextPool.includes(nextPin) ? nextPin : 'none';
    setPinned(pin);
    setRows(
      makePairs(
        items.filter((item) => nextPool.includes(item.id)),
        nextLevels,
        nextHero,
      ).filter((row) => pin === 'none' || row.equipment.some((gear) => gear.id === pin)),
    );
    setEditingRow(undefined);
  };
  const choosePreset = (tag: string) => {
    setPreset(tag);
    if (tag === 'custom') return;
    const player = players.find((player) => player.tag === tag);
    setLevelAccountTag(player?.tag);
    const nextHero = Math.min(
      player?.heroes.find((item) => item.name === hero.name)?.level ?? maxHero,
      maxHero,
    );
    const nextLevels = Object.fromEntries(
      items.map((item) => [
        item.id,
        player
          ? Math.min(
              Number(item.levels.at(-1)!.level),
              Math.max(1, player.equipments.find((gear) => gear.name === item.name)?.level ?? 1),
            )
          : Number(item.levels.at(-1)!.level),
      ]),
    );
    // Account presets seed levels, not eligibility. Keep unowned equipment
    // selectable at level 1 so an account can plan future loadouts.
    setLevels(nextLevels);
    setHeroLevel(nextHero);
    regenerate(pool, nextLevels, nextHero);
  };
  const changeRow = (id: string, update: Pick<Loadout, 'equipment'>) => {
    setPreset('custom');
    setRows((current) => current.map((row) => (row.id === id ? { ...row, ...update } : row)));
  };
  const format = (metric: ComparisonMetric, value: unknown): string =>
    Array.isArray(value)
      ? value.map((entry) => format(metric, entry)).join(' / ')
      : metric.field
        ? formatAbilityValue(metric.field, value, number)
        : typeof value === 'number'
          ? number.format(value)
          : '—';
  const exportData: EquipmentComparisonExportData = {
    heroName: itemLabel(hero),
    heroImage: ImageAssets.getHeroImage(hero.name),
    heroLevel,
    mode: t('calcCompareLoadouts'),
    columns: chosenMetrics.map((metric) => metric.label),
    rows: [baseline, ...displayed].map((row) => ({
      id: row.id,
      equipment: row.equipment.map((gear) => {
        const item = items.find((item) => item.id === gear.id)!;
        return {
          name: itemLabel(item),
          image: ImageAssets.getGearImage(item.name),
          level: gear.level,
        };
      }),
      values: chosenMetrics.map((metric) =>
        format(metric, compareMetric(hero, items, row, metric)),
      ),
    })),
  };
  const levelOptions = (item: ComparisonItem) =>
    item.levels.map((level) => ({
      key: String(level.level),
      label: t('sideLevel', { level: Number(level.level) }),
    }));
  const equipmentLevelOptions = (item: ComparisonItem, current: number) => {
    const maximum = Number(item.levels.at(-1)!.level);
    const owned = levelAccount?.equipments.find((gear) => gear.name === item.name)?.level;
    // Offer upgrade breakpoints without rounding live account data. Keep the
    // owned level even after a manual edit so the user can return to it.
    return levelOptions(item).filter(({ key }) => {
      const level = Number(key);
      return (
        level === 1 || level % 3 === 0 || level === maximum || level === current || level === owned
      );
    });
  };
  return (
    <ScrollView
      style={styles.mainScroll}
      contentContainerStyle={
        layout.isDuo
          ? undefined
          : [
              s.content,
              { paddingTop: insets.top + 16, gap: 12 },
              (layout.isExpanded || layout.isDuo) && { maxWidth: layout.contentMaxWidth },
            ]
      }
      keyboardShouldPersistTaps="handled"
    >
      <View
        pointerEvents="none"
        style={{ position: 'absolute', top: 0, left: 0, right: 0, height: gradientHeight }}
      >
        <HeaderArtwork
          pointerEvents="none"
          accessible={false}
          source={require('../../../assets/clashking/backgrounds/header-atmosphere.png')}
          contentFit="fill"
          tintColor={heroAccents[hero.name] ?? theme.secondary}
          // A 2px-wide gradient can retain its intrinsic size on native even
          // with edge constraints. Explicit dimensions fill the measured area.
          style={[StyleSheet.absoluteFill, { width: '100%', height: '100%' }]}
        />
      </View>
      <EquipmentContent
        enabled={layout.isDuo}
        top={insets.top + 16}
        maxWidth={layout.contentMaxWidth}
      >
        <CalculatorWorkspaceColumns compactGap={4}>
          <HeroCarousel
            leading={<CalcHeader onBack={onBack} />}
            selectedId={hero.id}
            onSelect={onHero}
            heroes={heroes.map((item) => ({
              id: item.id,
              name: item.name,
              label: itemLabel(item),
            }))}
            trailing={
              <SelectionPicker
                title={t('damageAccountPresetShort')}
                accessibilityLabel={t('damageAccountPresetShort')}
                selectedKey={preset}
                options={[
                  { key: 'manual', label: t('calcMaxLevels') },
                  ...(preset === 'custom' ? [{ key: 'custom', label: t('calcCustomLevels') }] : []),
                  ...availablePlayers.map((player) => ({ key: player.tag, label: player.name })),
                ]}
                onSelect={choosePreset}
              />
            }
          >
            <LevelSlider
              label={t('calcHeroLevel')}
              value={heroLevel}
              minimum={Number(hero.levels[0]!.level)}
              maximum={maxHero}
              onChange={(value) => {
                setPreset('custom');
                setHeroLevel(value);
                setRows((current) => current.map((row) => ({ ...row, heroLevel: value })));
              }}
            />
          </HeroCarousel>
          <CalculatorSelectionModal
            inline
            visible
            title={t('calcEquipmentPool')}
            testID="equipment-selection-inline"
            onClose={() => {}}
            items={items.map((item) => {
              const owned =
                levelAccount?.equipments.find((gear) => gear.name === item.name)?.level ?? 0;
              return {
                key: item.id,
                label: itemLabel(item),
                imageUrl: ImageAssets.getGearImage(item.name),
                selected: pool.includes(item.id),
                level: levels[item.id]!,
                minimum: Number(item.levels[0]!.level),
                maximum: Number(item.levels.at(-1)!.level),
                steps: equipmentLevelOptions(item, levels[item.id]!).map((option) =>
                  Number(option.key),
                ),
                detail: levelAccount
                  ? owned > 0
                    ? t('calcOwnedLevel', { level: owned })
                    : t('calcNotOwned')
                  : undefined,
              };
            })}
            onToggle={(id) => {
              const next = pool.includes(id) ? pool.filter((key) => key !== id) : [...pool, id];
              setPool(next);
              regenerate(next);
            }}
            onLevelChange={(id, value) => {
              setPreset('custom');
              const next = { ...levels, [id]: value };
              setLevels(next);
              regenerate(pool, next);
            }}
            actions={
              <View style={{ gap: 4 }}>
                <CalcChip
                  label={t('calcSelectAll')}
                  onPress={() => {
                    const next = items.map((item) => item.id);
                    setPool(next);
                    regenerate(next);
                  }}
                />
                <CalcChip
                  label={t('calcClear')}
                  onPress={() => {
                    setPool([]);
                    regenerate([]);
                  }}
                />
              </View>
            }
          />
        </CalculatorWorkspaceColumns>
        <View
          onLayout={({ nativeEvent }) =>
            setGradientHeight(nativeEvent.layout.y + nativeEvent.layout.height + 20)
          }
          style={[s.row, { alignItems: 'flex-end', flexWrap: 'nowrap' }]}
        >
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`${t('calcKeepEquipped')}: ${items.find((item) => item.id === pinned)?.name ?? t('calcNone')}`}
            onPress={() => setPinOpen(true)}
            style={{
              width: 44,
              height: 44,
              borderRadius: 16,
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: colorWithAlpha(theme.onSurface, 0.06),
            }}
          >
            {items.find((item) => item.id === pinned) ? (
              <GearImage item={items.find((item) => item.id === pinned)!} size={30} />
            ) : (
              <MobileWebImage
                imageUrl={ImageAssets.upgradeCategoryIcons.equipment}
                style={{ width: 30, height: 30 }}
              />
            )}
          </Pressable>
          <CalcSelect
            title={t('calcSort')}
            value={sortMetric}
            options={chosenMetrics.map((metric) => ({ key: metric.id, label: metric.label }))}
            onChange={setSortMetric}
          />
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('calcAttributes')}
            onPress={() => setAttributesOpen(true)}
            style={{
              width: 44,
              height: 44,
              borderRadius: 16,
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: colorWithAlpha(theme.onSurface, 0.06),
            }}
          >
            <SlidersHorizontal size={20} color={theme.onSurface} />
          </Pressable>
        </View>
        <>
          <SelectionPickerModal
            visible={pinOpen}
            title={t('calcKeepEquipped')}
            selectedKey={pinned}
            options={[
              {
                key: 'none',
                label: t('calcNone'),
                icon: (
                  <MobileWebImage
                    imageUrl={ImageAssets.upgradeCategoryIcons.equipment}
                    style={{ width: 28, height: 28 }}
                  />
                ),
              },
              ...items
                .filter((item) => pool.includes(item.id))
                .map((item) => ({
                  key: item.id,
                  label: itemLabel(item),
                  icon: <GearImage item={item} size={28} />,
                })),
            ]}
            onClose={() => setPinOpen(false)}
            onSelect={(id) => {
              regenerate(pool, levels, heroLevel, id);
              setPinOpen(false);
            }}
          />
          <SelectionPickerModal
            visible={attributesOpen}
            title={t('calcAttributes')}
            selectedKey={chosenMetrics[0]?.id ?? ''}
            selectedKeys={chosenMetrics.map((metric) => metric.id)}
            options={allMetrics.map((metric) => ({
              key: metric.id,
              label: metric.label,
              disabled: chosenMetrics.length === 1 && chosenMetrics[0]?.id === metric.id,
            }))}
            onClose={() => setAttributesOpen(false)}
            onSelect={(id) => {
              const next = chosenMetrics.some((metric) => metric.id === id)
                ? chosenMetrics.filter((metric) => metric.id !== id).map((metric) => metric.id)
                : [...chosenMetrics.map((metric) => metric.id), id];
              if (next.length === 0) return;
              setMetrics(next);
              if (!next.includes(sortMetric)) setSortMetric(next[0]!);
            }}
          />
          <ComparisonMatrix
            exportData={exportData}
            hero={hero}
            items={items}
            rows={[baseline, ...displayed]}
            metrics={chosenMetrics}
            format={format}
            selected={editingRow}
            onSelect={(id) => setEditingRow((current) => (current === id ? undefined : id))}
          />
        </>
        {activeRow ? (
          <Surface style={s.card} testID="equipment-row-editor">
            <View style={s.row}>
              <CKText role="sectionTitle" style={s.grow}>
                {t('filtersOptions')}
              </CKText>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={t('calcDuplicate')}
                style={styles.action}
                onPress={() => {
                  const copy = { ...activeRow, id: `${activeRow.id}-copy-${Date.now()}` };
                  setRows((current) => [...current, copy]);
                  setEditingRow(copy.id);
                }}
              >
                <Copy size={20} color={theme.onSurface} />
              </Pressable>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={t('calcRemove')}
                style={styles.action}
                onPress={() => {
                  setRows((current) => current.filter((row) => row.id !== activeRow.id));
                  setEditingRow(undefined);
                }}
              >
                <Trash2 size={20} color={theme.onSurfaceVariant} />
              </Pressable>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={materialCloseLabel(locale)}
                style={styles.action}
                onPress={() => setEditingRow(undefined)}
              >
                <X size={20} color={theme.onSurface} />
              </Pressable>
            </View>
            <View style={s.row}>
              {activeRow.equipment.map((selection) => {
                const item = items.find((item) => item.id === selection.id)!;
                return (
                  <View
                    key={item.id}
                    style={styles.editorGear}
                    testID={`equipment-row-level-${item.id}`}
                  >
                    <GearImage item={item} />
                    <View style={styles.heroLevel}>
                      <LevelSlider
                        label={itemLabel(item)}
                        value={selection.level}
                        minimum={Number(item.levels[0]!.level)}
                        maximum={Number(item.levels.at(-1)!.level)}
                        steps={equipmentLevelOptions(item, selection.level).map((option) =>
                          Number(option.key),
                        )}
                        onChange={(value) =>
                          changeRow(activeRow.id, {
                            equipment: activeRow.equipment.map((gear) =>
                              gear.id === item.id ? { ...gear, level: value } : gear,
                            ),
                          })
                        }
                      />
                    </View>
                  </View>
                );
              })}
            </View>
          </Surface>
        ) : rows.length > 0 ? (
          <CKText muted role="metadata">
            {t('calcSelectLoadout')}
          </CKText>
        ) : null}
        {rows.length === 0 ? <EmptyState title={t('calcChooseEquipment')} /> : null}
      </EquipmentContent>
    </ScrollView>
  );
}

// Keep the scrolling gradient full width while controls clear the physical rail.
function EquipmentSafeContent({ enabled, children }: { enabled: boolean; children: ReactNode }) {
  return enabled ? (
    <SafeAreaView edges={['left', 'right']}>{children}</SafeAreaView>
  ) : (
    <>{children}</>
  );
}

function EquipmentContent({
  enabled,
  top,
  maxWidth,
  children,
}: {
  enabled: boolean;
  top: number;
  maxWidth: number;
  children: ReactNode;
}) {
  return enabled ? (
    <EquipmentSafeContent enabled>
      <View style={[s.content, { paddingTop: top, gap: 12, maxWidth }]}>{children}</View>
    </EquipmentSafeContent>
  ) : (
    <>{children}</>
  );
}

function LoadoutHeader({
  row,
  items,
  selected,
  onSelect,
  iconsOnly = false,
  expanded = false,
}: {
  row: Loadout;
  items: ComparisonItem[];
  selected?: boolean;
  onSelect: () => void;
  iconsOnly?: boolean;
  expanded?: boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole={row.id === 'baseline' ? 'text' : 'button'}
      accessibilityLabel={
        row.equipment.length === 0
          ? t('calcNoEquipment')
          : row.equipment
              .map(
                (gear) =>
                  `${itemLabel(items.find((item) => item.id === gear.id)!)}, ${t('sideLevel', { level: gear.level })}`,
              )
              .join(', ')
      }
      accessibilityState={{ selected }}
      onPress={onSelect}
      disabled={row.id === 'baseline'}
      style={[
        iconsOnly ? styles.iconHeader : styles.headerCell,
        expanded && { width: 120, height: 84 },
        {
          backgroundColor: colorWithAlpha(
            selected ? theme.secondary : theme.onSurface,
            selected ? 0.12 : 0.04,
          ),
        },
      ]}
      testID={`compare-row-${row.id}`}
    >
      {row.equipment.length === 0 ? (
        <CKText role="metadata">{t('calcNoEquipment')}</CKText>
      ) : (
        row.equipment.map((gear) => {
          const item = items.find((item) => item.id === gear.id)!;
          return (
            <View key={gear.id} style={styles.headerGear}>
              <GearImage item={item} size={expanded ? 42 : iconsOnly ? 32 : 40} />
              {!iconsOnly ? (
                <View>
                  <CKText muted role="metadata">
                    {t('sideLevel', { level: gear.level })}
                  </CKText>
                </View>
              ) : null}
            </View>
          );
        })
      )}
      {!iconsOnly ? (
        <CKText muted role="metadata">
          {t('calcHeroLevel')}: {row.heroLevel}
        </CKText>
      ) : null}
    </Pressable>
  );
}

function ComparisonMatrix({
  exportData,
  hero,
  items,
  rows,
  metrics,
  format,
  selected,
  onSelect,
}: {
  exportData: EquipmentComparisonExportData;
  hero: ComparisonItem;
  items: ComparisonItem[];
  rows: Loadout[];
  metrics: ComparisonMetric[];
  format: (metric: ComparisonMetric, value: unknown) => string;
  selected?: string;
  onSelect: (id: string) => void;
}) {
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  return (
    <ScrollView
      horizontal
      style={styles.horizontal}
      contentContainerStyle={styles.comparisonGrid}
      testID="equipment-comparison-table"
    >
      <View style={styles.comparisonRow}>
        {/* Keep export in the matrix corner so it stays aligned with the grid. */}
        <View
          style={[
            styles.iconHeader,
            styles.attributeHeading,
            layout.isExpanded && { width: 120, height: 84 },
          ]}
        >
          <EquipmentComparisonCopy data={exportData} />
        </View>
        {metrics.map((metric) => (
          <View
            key={metric.id}
            style={[
              styles.valueCell,
              styles.attributeColumn,
              styles.attributeHeading,
              layout.isExpanded && { width: 156, height: 84, padding: 14 },
            ]}
          >
            <CKText role="metadata" numberOfLines={3}>
              {metric.label}
            </CKText>
          </View>
        ))}
      </View>
      {rows.map((row) => (
        <View key={row.id} style={styles.comparisonRow}>
          <LoadoutHeader
            row={row}
            items={items}
            selected={selected === row.id}
            onSelect={() => onSelect(row.id)}
            iconsOnly
            expanded={layout.isExpanded}
          />
          {metrics.map((metric) => (
            <View
              key={metric.id}
              testID={`compare-value-${row.id}-${metric.id}`}
              accessible
              accessibilityLabel={`${metric.label}: ${format(metric, compareMetric(hero, items, row, metric))}`}
              style={[
                styles.valueCell,
                styles.attributeColumn,
                layout.isExpanded && { width: 156, height: 84, padding: 14 },
                { backgroundColor: colorWithAlpha(theme.onSurface, 0.03) },
              ]}
            >
              <CKText role="rowTitle" numberOfLines={2}>
                {format(metric, compareMetric(hero, items, row, metric))}
              </CKText>
            </View>
          ))}
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  mainScroll: { flex: 1 },
  heroLevel: { flex: 1, minWidth: 210 },
  // Horizontal ScrollViews retain intrinsic height inside the vertical page.
  // Flex growth here stretches the strip into a large overlapping panel.
  horizontal: { flexGrow: 0, flexShrink: 0 },
  comparisonGrid: { gap: 6, flexDirection: 'column' },
  comparisonRow: { flexDirection: 'row', gap: 6, alignItems: 'center' },
  attributeColumn: { width: 112, height: 60, padding: 8 },
  attributeHeading: { height: 68 },
  iconHeader: {
    width: 92,
    height: 60,
    padding: 8,
    flexDirection: 'row',
    gap: 6,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerCell: { height: 130, padding: 10, gap: 8, borderRadius: 16, justifyContent: 'center' },
  headerGear: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  valueCell: { height: 76, padding: 10, borderRadius: 12, justifyContent: 'center', gap: 4 },
  action: { minWidth: 44, minHeight: 44, alignItems: 'center', justifyContent: 'center' },
  editorGear: { flexDirection: 'row', alignItems: 'center', gap: 8, flex: 1, minWidth: 220 },
});
