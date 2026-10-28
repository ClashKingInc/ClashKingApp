import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import { CalculatorWorkspaceColumns } from './calculator-workspace-columns';
import { useState, type ReactNode } from 'react';
import { Image as BackgroundImage, Pressable, ScrollView, View } from 'react-native';
import { Asset } from 'expo-asset';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { SuperchargedBuildingArtwork } from './supercharged-building-artwork';
import { SuperchargeBorder } from './supercharge-border';
import { ImageAssets } from '../../core/assets/image-assets';
import { gameDataState } from '../../core/game-data/game-data-state';
import { useI18n, toIntlLocale } from '../../i18n';
import {
  CKText,
  EmptyState,
  MobileWebImage,
  SelectionPicker,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../ui';
import { LevelSlider } from '../../ui/level-slider';
import {
  BuildingLevelDefinition,
  DamageSourceKind,
  DamageTarget,
  type DamageAccountPreset,
  type DamageCalculatorSession,
  type DamageStackEntry,
  type BuildingDefinition,
  type DamageSourceDefinition,
} from '../damage-calculator';
import { CalcChip, CalcHeader, CalcSelect, calcStyles as s } from './calculator-controls';
import {
  damageCombinations,
  equipmentLevelPenalty,
  type DamageCombination,
} from './damage-combinations';
import { records } from './equipment-comparison';
import { CalculatorSelectionModal } from './calculator-selection-modal';

export function DamageWorkbench({
  session,
  accounts,
  onBack,
}: {
  session: DamageCalculatorSession;
  accounts: readonly DamageAccountPreset[];
  onBack: () => void;
}) {
  const insets = useSafeAreaInsets();
  const layout = useAdaptiveLayout();
  const { t } = useI18n(),
    theme = useCKTheme();
  const [, setRevision] = useState(0),
    [account, setAccount] = useState('manual');
  const [enabled, setEnabled] = useState<string[]>([
    DamageSourceKind.Lightning,
    DamageSourceKind.Earthquake,
  ]);
  const targetTownHall = session.catalog.maxTownHall;
  const buildings = session.catalog
    .buildingsForTownHall(targetTownHall)
    .filter((item) => item.defensive || item.name === 'Clan Castle');
  const [buildingId, setBuildingId] = useState('1000012'),
    [targetLevels, setTargetLevels] = useState<Record<string, number>>({}),
    [charge, setCharge] = useState(0);
  const building = buildings.find((item) => item.id === buildingId) ?? buildings[0];
  const level =
    building
      ?.levelsForTownHall(targetTownHall)
      .find((item) => item.level === targetLevels[building.id]) ??
    building?.levelsForTownHall(targetTownHall).at(-1);
  const [modifier, setModifier] = useState('normal'),
    [showAll, setShowAll] = useState(false);
  const preset = accounts.find((item) => item.tag === account);
  const sources = session.availableSources.filter(
    (source) =>
      (source.housingSpace > 0 ||
        source.hero ||
        source.kind === DamageSourceKind.RocketBalloonImpact) &&
      // Defense-targeting balloons cannot deliver the assumed first hit to a Clan Castle.
      (source.kind !== DamageSourceKind.RocketBalloonImpact || building?.name !== 'Clan Castle') &&
      (source.kind !== DamageSourceKind.Lightning || building?.zapQuakeEligible) &&
      (!preset || preset.ownedLevels?.has(source.kind)) &&
      (source.kind !== DamageSourceKind.RocketBalloonImpact ||
        !preset ||
        (preset.ownedLevels?.get(source.kind) ?? 0) >= 7),
  );
  const selected = sources.flatMap((source) => {
    const selection = session.sources.get(source.kind);
    if (!selection || !enabled.includes(source.kind)) return [];
    const penalty = source.hero
      ? equipmentLevelPenalty(gameDataState.bundleData, modifier, source)
      : 0;
    const adjusted = source.level(Math.max(1, selection.level - penalty));
    return adjusted ? [{ source, level: adjusted, count: 1 }] : [];
  });
  const target =
    building && level
      ? new DamageTarget({
          building,
          level: new BuildingLevelDefinition({
            ...level,
            hitpoints:
              level.superchargeHitpoints[Math.min(charge, level.superchargeHitpoints.length) - 1] ??
              level.hitpoints,
          }),
        })
      : null;
  const results = target ? damageCombinations(target, selected, session.spellCapacity) : [];
  const rocket = selected.find(
    (entry) => entry.source.kind === DamageSourceKind.RocketBalloonImpact,
  );
  const modifiers = records(gameDataState.bundleData.battle_modifiers);
  const mutate = (operation: () => void) => {
    operation();
    setRevision((value) => value + 1);
    setShowAll(false);
  };
  const chooseAccount = (tag: string) => {
    setAccount(tag);
    mutate(() => {
      const selectedPreset = accounts.find((item) => item.tag === tag);
      if (selectedPreset) session.applyPreset(selectedPreset);
      else {
        session.setTownHall(session.catalog.maxTownHall);
        for (const source of session.availableSources)
          session.setSourceLevel(
            source.kind,
            source.levelsForTownHall(session.townHall).at(-1)!.level,
          );
      }
    });
  };
  const defensePicker = (
    <SelectionPicker
      title={t('calcTarget')}
      accessibilityLabel={t('calcTarget')}
      selectedKey={building?.id ?? ''}
      options={buildings.map((item) => ({
        key: item.id,
        label: item.name,
        icon: (
          <MobileWebImage
            imageUrl={ImageAssets.getHomeVillageBuildingImage(
              item.imageName,
              item.levelsForTownHall(targetTownHall).at(-1)!.level,
            )}
            style={s.image}
          />
        ),
      }))}
      searchPlaceholder={t('calcSearch')}
      onSelect={(id) => {
        setBuildingId(id);
        setCharge(0);
        setShowAll(false);
      }}
    />
  );
  return (
    <View style={[s.page, { backgroundColor: theme.background }]} testID="damage-workbench">
      <View
        pointerEvents="none"
        style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: 260 }}
      >
        <BackgroundImage
          source={
            theme.background === '#030304'
              ? require('../../../assets/clashking/backgrounds/hub-blue-dark.png')
              : require('../../../assets/clashking/backgrounds/hub-blue-light.png')
          }
          resizeMode="stretch"
          style={{ width: '100%', height: '100%' }}
        />
      </View>
      <DuoSafeContent enabled={layout.isDuo}>
        <ScrollView
          contentContainerStyle={[
            s.content,
            { paddingTop: insets.top + 16 },
            (layout.isExpanded || layout.isDuo) && { maxWidth: layout.contentMaxWidth },
          ]}
          keyboardShouldPersistTaps="handled"
        >
          {target ? (
            <>
              <View
                style={[
                  s.row,
                  { minHeight: 56, justifyContent: 'space-between', flexWrap: 'nowrap' },
                ]}
              >
                <CalcHeader onBack={onBack} />
                <View style={{ width: 164 }}>
                  <SelectionPicker
                    title={t('damageAccountPresetShort')}
                    accessibilityLabel={t('damageAccountPresetShort')}
                    selectedKey={account}
                    options={[
                      { key: 'manual', label: t('calcMaxLevels') },
                      ...accounts.map((item) => ({ key: item.tag, label: item.name })),
                    ]}
                    onSelect={chooseAccount}
                  />
                </View>
              </View>
              <CalculatorWorkspaceColumns>
                <>
                  <TargetPanel
                    key={`${building!.id}-${level!.level}`}
                    building={building!}
                    levels={building!.levelsForTownHall(targetTownHall)}
                    selectedLevel={level!}
                    charge={charge}
                    defensePicker={defensePicker}
                    onLevelChange={(value) => {
                      setTargetLevels((current) => ({ ...current, [building!.id]: value }));
                      setCharge(0);
                      setShowAll(false);
                    }}
                    onChargeChange={(value) => {
                      setCharge(value);
                      setShowAll(false);
                    }}
                  />
                  <DamageSourcePicker
                    sources={sources}
                    session={session}
                    enabled={enabled}
                    modifier={modifier}
                    onSelectAll={() => {
                      setEnabled(sources.map((source) => source.kind));
                      setShowAll(false);
                    }}
                    onClear={() => {
                      setEnabled([]);
                      setShowAll(false);
                    }}
                    onToggle={(kind) => {
                      setEnabled((current) =>
                        current.includes(kind)
                          ? current.filter((item) => item !== kind)
                          : [...current, kind],
                      );
                      setShowAll(false);
                    }}
                    onLevelChange={(kind, value) =>
                      mutate(() => session.setSourceLevel(kind, value))
                    }
                  >
                    <View style={s.row}>
                      <CalcSelect
                        title={t('damageSpellCapacity')}
                        searchable={false}
                        value={String(session.spellCapacity)}
                        options={Array.from(
                          {
                            length: session.catalog.spellCapacityForTownHall(session.townHall) + 1,
                          },
                          (_, i) => ({
                            key: String(
                              session.catalog.spellCapacityForTownHall(session.townHall) - i,
                            ),
                            label: String(
                              session.catalog.spellCapacityForTownHall(session.townHall) - i,
                            ),
                          }),
                        )}
                        onChange={(value) => mutate(() => session.setSpellCapacity(Number(value)))}
                      />
                      <CalcSelect
                        title={t('calcBattleModifier')}
                        value={modifier}
                        options={[
                          { key: 'normal', label: t('calcNormal') },
                          ...modifiers.map((item) => ({
                            key: String(item.name),
                            label:
                              item.name === 'Hard Mode'
                                ? t('calcEsports')
                                : item.name === 'Minus One'
                                  ? 'Legend I'
                                  : item.name === 'Minus Two'
                                    ? 'Legend II'
                                    : item.name === 'Minus Three'
                                      ? 'Legend III'
                                      : String(item.name),
                          })),
                        ]}
                        onChange={(value) => {
                          setModifier(value);
                          setShowAll(false);
                        }}
                      />
                    </View>
                  </DamageSourcePicker>
                </>
                <>
                  {rocket && (rocket.level.damage ?? 0) > 0 ? (
                    <Surface style={s.card} testID="rocket-balloon-estimate">
                      <View style={s.row}>
                        <MobileWebImage
                          imageUrl={rocket.source.imageUrl}
                          style={{ width: 56, height: 56 }}
                        />
                        <View style={s.grow}>
                          <CKText role="sectionTitle">
                            {rocket.source.name} ×
                            {Math.ceil(target.hitpoints / rocket.level.damage!)}
                          </CKText>
                          <CKText muted role="metadata">
                            {t('calcRocketBalloonAssumption', { damage: rocket.level.damage! })}
                          </CKText>
                          <CKText muted role="metadata">
                            {t('sideLevel', { level: rocket.level.level })}
                          </CKText>
                        </View>
                      </View>
                    </Surface>
                  ) : null}
                  {results.length || !rocket ? (
                    <View style={s.heading}>
                      <CKText role="sectionTitle">
                        {t('calcResults', { count: results.length })}
                      </CKText>
                    </View>
                  ) : null}
                  {!results.length && !rocket ? (
                    <EmptyState
                      title={t('damageNoValidZapQuake')}
                      body={t('calcNoCombinationHelp')}
                    />
                  ) : (
                    results
                      .slice(0, showAll ? results.length : 3)
                      .map((result, index) => (
                        <CombinationRow key={index} result={result} index={index} />
                      ))
                  )}
                  {!showAll && results.length > 3 ? (
                    <CalcChip
                      label={t('calcShowAll', { count: results.length })}
                      onPress={() => setShowAll(true)}
                    />
                  ) : null}
                </>
              </CalculatorWorkspaceColumns>
            </>
          ) : (
            <View>
              <CalcHeader onBack={onBack} />
              <EmptyState title={t('damageNoStaticDataTitle')} body={t('damageNoStaticDataBody')} />
            </View>
          )}
        </ScrollView>
      </DuoSafeContent>
    </View>
  );
}

// Only the controls clear the Duo rail; the backdrop fills the whole pane.
function DuoSafeContent({ enabled, children }: { enabled: boolean; children: ReactNode }) {
  return enabled ? (
    <SafeAreaView edges={['left', 'right']} style={{ flex: 1 }}>
      {children}
    </SafeAreaView>
  ) : (
    <>{children}</>
  );
}

function DamageSourcePicker({
  sources,
  session,
  enabled,
  modifier,
  onToggle,
  onLevelChange,
  onSelectAll,
  onClear,
  children,
}: {
  sources: readonly DamageSourceDefinition[];
  session: DamageCalculatorSession;
  enabled: readonly string[];
  modifier: string;
  onToggle: (kind: DamageSourceKind) => void;
  onLevelChange: (kind: DamageSourceKind, level: number) => void;
  onSelectAll: () => void;
  onClear: () => void;
  children: ReactNode;
}) {
  const { t } = useI18n();
  return (
    <CalculatorSelectionModal
      inline
      visible
      title={t('calcSelectDamageSources')}
      testID="damage-source-selection-inline"
      onClose={() => {}}
      actions={
        <View style={{ gap: 4 }}>
          <CalcChip label={t('calcSelectAll')} onPress={onSelectAll} />
          <CalcChip label={t('calcClear')} onPress={onClear} />
        </View>
      }
      onToggle={(key) => onToggle(key as DamageSourceKind)}
      onLevelChange={(key, level) => onLevelChange(key as DamageSourceKind, level)}
      items={sources.map((source) => {
        const levels = source.levelsForTownHall(session.townHall);
        const level = session.sources.get(source.kind)?.level ?? levels.at(-1)!.level;
        const penalty = source.hero
          ? equipmentLevelPenalty(gameDataState.bundleData, modifier, source)
          : 0;
        return {
          key: source.kind,
          label: source.name,
          imageUrl: source.imageUrl,
          selected: enabled.includes(source.kind),
          level,
          minimum: levels[0]!.level,
          maximum: levels.at(-1)!.level,
          // Equipment damage changes at three-level milestones. Keep spell and
          // troop controls continuous; the shared slider preserves exact owned levels.
          steps: source.hero
            ? levels
                .filter((entry) => entry.level === 1 || entry.level % 3 === 0)
                .map((entry) => entry.level)
            : undefined,
          detail:
            penalty > 0
              ? t('calcEffectiveLevel', { level: Math.max(1, level - penalty) })
              : undefined,
        };
      })}
    >
      {children}
    </CalculatorSelectionModal>
  );
}

function TargetPanel({
  building,
  levels,
  selectedLevel,
  charge,
  defensePicker,
  onLevelChange,
  onChargeChange,
}: {
  building: BuildingDefinition;
  levels: readonly BuildingLevelDefinition[];
  selectedLevel: BuildingLevelDefinition;
  charge: number;
  defensePicker: ReactNode;
  onLevelChange: (value: number) => void;
  onChargeChange: (value: number) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  // Pointer movement updates only this small panel. The parent retains the
  // committed level so the combination search runs once when dragging ends.
  const [preview, setPreview] = useState(selectedLevel.level);
  const level = levels.find((item) => item.level === preview) ?? selectedLevel;
  const activeCharge = preview === selectedLevel.level ? charge : 0;
  const hitpoints = level.superchargeHitpoints[activeCharge - 1] ?? level.hitpoints;
  return (
    <Surface
      style={[s.card, activeCharge > 0 && { overflow: 'visible', borderColor: 'transparent' }]}
      testID="damage-target-card"
    >
      {activeCharge > 0 ? <SuperchargeBorder /> : null}
      <View
        accessible
        accessibilityLabel={t('damageHitpoints', {
          hitpoints: new Intl.NumberFormat(toIntlLocale(locale)).format(hitpoints),
        })}
        style={{
          position: 'absolute',
          top: 16,
          left: 16,
          flexDirection: 'row',
          alignItems: 'center',
          gap: 5,
        }}
      >
        <MobileWebImage imageUrl={ImageAssets.hitpoints} style={{ width: 18, height: 18 }} />
        <CKText role="metadata">
          {new Intl.NumberFormat(toIntlLocale(locale)).format(hitpoints)}
        </CKText>
      </View>
      <View style={{ alignItems: 'center', paddingTop: 36 }}>
        <SuperchargedBuildingArtwork
          buildingId={building.id}
          level={level.level}
          imageUrl={ImageAssets.getHomeVillageBuildingImage(building.imageName, level.level)}
          active={activeCharge > 0}
          size={176}
        />
      </View>
      {defensePicker}
      <LevelSlider
        label={t('damageTargetLevelLabel')}
        value={selectedLevel.level}
        minimum={levels[0]!.level}
        maximum={levels.at(-1)!.level}
        onPreviewChange={setPreview}
        onChange={onLevelChange}
      />
      {level.superchargeHitpoints.length ? (
        <Pressable
          accessibilityRole="switch"
          accessibilityLabel={t('calcSupercharge')}
          accessibilityState={{ checked: activeCharge > 0 }}
          onPress={() => onChargeChange(activeCharge > 0 ? 0 : level.superchargeHitpoints.length)}
          style={{
            position: 'absolute',
            top: 12,
            right: 12,
            width: 44,
            height: 44,
            borderRadius: 14,
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: colorWithAlpha(
              activeCharge > 0 ? theme.secondary : theme.onSurface,
              activeCharge > 0 ? 0.2 : 0.06,
            ),
          }}
        >
          <MobileWebImage
            imageUrl={
              Asset.fromModule(
                require('../../../assets/clashking/calculators/supercharge-icon.webp'),
              ).uri
            }
            style={{ width: 28, height: 28, opacity: activeCharge > 0 ? 1 : 0.5 }}
          />
        </Pressable>
      ) : null}
    </Surface>
  );
}

function CombinationRow({ result, index }: { result: DamageCombination; index: number }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface
      style={[s.card, index === 0 && { backgroundColor: theme.surfaceContainerHighest }]}
      testID="damage-combination"
    >
      <View style={s.row}>
        <View style={s.grow}>
          <CKText role="labelLarge">
            {index === 0 ? t('calcMostEfficient') : t('calcAlternative')}
          </CKText>
          <CKText muted role="metadata">
            {t('calcCombinationCost', { housing: result.housing, equipment: result.equipment })}
          </CKText>
        </View>
      </View>
      <View style={s.row}>
        {result.entries.map((entry: DamageStackEntry) => (
          <View
            key={entry.source.kind}
            style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}
          >
            <MobileWebImage
              imageUrl={entry.source.imageUrl}
              style={{ width: index === 0 ? 56 : 40, height: index === 0 ? 56 : 40 }}
            />
            <View>
              <CKText role="rowTitle">×{entry.count}</CKText>
              <CKText muted role="metadata">
                {t('sideLevel', { level: entry.level.level })}
              </CKText>
            </View>
          </View>
        ))}
      </View>
    </Surface>
  );
}
