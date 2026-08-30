import { useEffect, useState, type ReactNode } from 'react';
import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import {
  ArrowLeft,
  ArrowRight,
  Bolt,
  Check,
  ChevronDown,
  CircleCheck,
  CloudOff,
  Flame,
  Info,
  Minus,
  Plus,
  Rocket,
  Search,
  SearchX,
  SlidersHorizontal,
  TriangleAlert,
  Upload,
  UsersRound,
  X,
} from 'lucide-react-native';

import { ImageAssets } from '../../core/assets/image-assets';
import { translationForTid } from '../../core/game-data/game-data-localization';
import {
  materialBackLabel,
  materialCloseLabel,
  toIntlLocale,
  useI18n,
  type MessageKey,
} from '../../i18n';
import {
  CKText,
  EmptyState,
  HeaderIconButton,
  MobileWebImage,
  PillSurface,
  Skeleton,
  Surface,
  colorWithAlpha,
  useCKTheme,
  useCKThemeMode,
} from '../../ui';
import {
  DamageCalculatorEngine,
  DamageCalculatorSession,
  DamageSourceKind,
  type BuildingDefinition,
  type DamageAccountPreset,
  type DamageResult,
  type DamageSourceDefinition,
  type DamageTarget,
  type SelectedDamageSource,
} from '../damage-calculator';
import type {
  UpgradePlanPreferences,
  UpgradeTrackerSnapshot,
} from '../upgrade-tracker/models/upgrade-tracker-models';
import {
  applyQuickSetup,
  availableSetupIds,
  calculatorSetupCounts,
  calculatorSetupIds,
  defaultFarmLoot,
  farmAttackScenarios,
  farmLeagueLootEstimate,
  farmSelectableBuildings,
  farmTargetLevels,
  farmTrackerTargets,
  farmUnpaidTargetLevels,
  parseFarmAmount,
  trackerCostForSelection,
  type FarmTrackerTarget,
} from './calculator-logic';

export type CalculatorMode = 'damage' | 'farmGoal';

export interface CalculatorsScreenProps {
  readonly session: DamageCalculatorSession;
  readonly accountPresets: readonly DamageAccountPreset[];
  readonly trackerSnapshot: UpgradeTrackerSnapshot | null;
  readonly trackerLoading: boolean;
  readonly trackerPreferences?: UpgradePlanPreferences;
  readonly trackerGoldPassPercent?: number;
  readonly onFarmAccountChanged: (tag: string | null) => void;
  readonly onOpenUpgradeTracker: (tag: string | null) => void;
  readonly onBack: () => void;
}

const engine = new DamageCalculatorEngine();

export function CalculatorsScreen(props: CalculatorsScreenProps) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [mode, setMode] = useState<CalculatorMode>('damage');
  const [revision, setRevision] = useState(0);
  const mutate = (operation: () => void) => {
    operation();
    setRevision((value) => value + 1);
  };
  const catalogMissing =
    props.session.catalog.buildings.length === 0 || props.session.catalog.sources.length === 0;
  void revision;
  return (
    <View style={[styles.screen, { backgroundColor: theme.background }]}>
      <CalculatorHero mode={mode} onBack={props.onBack} />
      <ModeTabs mode={mode} onChange={setMode} />
      {mode === 'damage' ? (
        catalogMissing ? (
          <View style={styles.emptyPage}>
            <EmptyState
              icon={<CloudOff color={theme.onSurfaceVariant} />}
              title={t('damageNoStaticDataTitle')}
              body={t('damageNoStaticDataBody')}
            />
          </View>
        ) : (
          <DamageMode {...props} mutate={mutate} />
        )
      ) : (
        <FarmGoalMode {...props} mutate={mutate} />
      )}
    </View>
  );
}

function CalculatorHero({ mode, onBack }: { mode: CalculatorMode; onBack: () => void }) {
  const { t, isRtl, locale } = useI18n();
  const themeMode = useCKThemeMode();
  const insets = useSafeAreaInsets();
  const { width, fontScale } = useWindowDimensions();
  const desktop = width >= 900;
  const scaleAllowance = Math.max(0, Math.min(72, (16 * fontScale - 16) * 1.5));
  const height = insets.top + (desktop ? 292 : 332 + scaleAllowance);
  const damage = mode === 'damage';
  return (
    <View style={[styles.hero, { height }]}>
      <MobileWebImage
        imageUrl={
          damage ? ImageAssets.playerWarStatsPageBackground : ImageAssets.homeBaseBackground
        }
        contentFit="cover"
        contentPosition="bottom center"
        style={StyleSheet.absoluteFill}
      />
      <Svg pointerEvents="none" style={StyleSheet.absoluteFill}>
        <Defs>
          <LinearGradient id="calculatorGradient" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.5 : 0.34} />
            <Stop offset="0.5" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.72 : 0.52} />
            <Stop offset="1" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.94 : 0.72} />
          </LinearGradient>
        </Defs>
        <Rect width="100%" height="100%" fill="url(#calculatorGradient)" />
      </Svg>
      <SafeAreaView
        edges={['top', 'left', 'right']}
        style={[styles.heroSafe, { paddingHorizontal: desktop ? 20 : 12 }]}
      >
        <HeaderIconButton
          glass={false}
          label={materialBackLabel(locale)}
          onPress={onBack}
          icon={isRtl ? <ArrowRight color="#fff" /> : <ArrowLeft color="#fff" />}
        />
        <View style={[styles.heroIdentity, desktop && styles.heroHorizontal]}>
          <MobileWebImage
            imageUrl={damage ? ImageAssets.getSpellImage('Lightning Spell') : ImageAssets.lootCart}
            contentFit="contain"
            style={{ width: desktop ? 104 : 112, height: desktop ? 104 : 112 }}
            errorFallback={
              damage ? <Bolt color="#fff" size={42} /> : <Rocket color="#fff" size={42} />
            }
          />
          <View
            style={[
              styles.heroCopy,
              { maxWidth: desktop ? 520 : 330, alignItems: desktop ? 'flex-start' : 'center' },
            ]}
          >
            <CKText role="screenTitle" numberOfLines={1} style={styles.heroTitle}>
              {t('calculatorsTitle')}
            </CKText>
            <CKText
              numberOfLines={2}
              style={[styles.heroSubtitle, { textAlign: desktop ? 'left' : 'center' }]}
            >
              {t(damage ? 'damageCalculatorSubtitle' : 'farmGoalFormTitle')}
            </CKText>
          </View>
        </View>
      </SafeAreaView>
    </View>
  );
}

function ModeTabs({
  mode,
  onChange,
}: {
  mode: CalculatorMode;
  onChange: (mode: CalculatorMode) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={[styles.tabs, { backgroundColor: theme.surface }]}>
      <ModeTab
        selected={mode === 'damage'}
        label={t('calculatorsModeDamage')}
        image={ImageAssets.getSpellImage('Lightning Spell')}
        onPress={() => onChange('damage')}
      />
      <ModeTab
        selected={mode === 'farmGoal'}
        label={t('calculatorsModeFarmGoal')}
        image={ImageAssets.lootCart}
        onPress={() => onChange('farmGoal')}
      />
    </View>
  );
}

function ModeTab({
  selected,
  label,
  image,
  onPress,
}: {
  selected: boolean;
  label: string;
  image: string;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="tab"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[styles.tab, selected && { borderBottomColor: theme.primary }]}
    >
      <MobileWebImage imageUrl={image} contentFit="contain" style={styles.tabImage} />
      <CKText role="labelLarge" style={selected ? { color: theme.primary } : undefined}>
        {label}
      </CKText>
    </Pressable>
  );
}

function DamageMode(props: CalculatorsScreenProps & { mutate: (operation: () => void) => void }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const session = props.session;
  const [setupId, setSetupId] = useState<string>(calculatorSetupIds.custom);
  const [showAll, setShowAll] = useState(false);
  const [accountPicker, setAccountPicker] = useState(false);
  const [buildingPicker, setBuildingPicker] = useState(false);
  const targets = session.resolvedTargets();
  const results = engine.evaluateAll(targets, session.resolvedStack());
  const resultById = new Map(results.map((result) => [result.target.id, result]));
  const setupIds = availableSetupIds(session);
  const setupKinds = new Set(calculatorSetupCounts[setupId]?.keys() ?? []);
  const primary =
    setupId === calculatorSetupIds.custom
      ? session.availableSources
      : session.availableSources.filter(
          (source) =>
            setupKinds.has(source.kind) || (session.sources.get(source.kind)?.count ?? 0) > 0,
        );
  const primaryKinds = new Set(primary.map((source) => source.kind));
  const extra = session.availableSources.filter((source) => !primaryKinds.has(source.kind));
  const selectedAccount = props.accountPresets.find(
    (account) => account.tag === session.selectedAccountTag,
  );
  const chooseAccount = (tag: string | null) =>
    props.mutate(() => {
      if (tag === null) {
        session.selectedAccountTag = undefined;
        session.setTownHall(session.catalog.maxTownHall);
      } else {
        const preset = props.accountPresets.find((candidate) => candidate.tag === tag);
        if (preset) session.applyPreset(preset);
      }
      if (setupId !== calculatorSetupIds.custom && !availableSetupIds(session).includes(setupId)) {
        setSetupId(calculatorSetupIds.custom);
        applyQuickSetup(session, calculatorSetupIds.custom);
      }
    });
  return (
    <ScrollView contentContainerStyle={styles.pageContent} keyboardShouldPersistTaps="handled">
      <SectionTitle>{t('damageAccountPresetShort')}</SectionTitle>
      <AccountPanel
        accounts={props.accountPresets}
        selected={selectedAccount}
        onOpen={() => setAccountPicker(true)}
        hint={t('damageAccountSelectorHint')}
      />
      <Spacer />
      <SectionTitle>{t('damageTargetSectionTitle')}</SectionTitle>
      {targets.length === 0 ? (
        <EmptyTarget onChoose={() => setBuildingPicker(true)} />
      ) : (
        <>
          {targets.map((target) => (
            <TargetCard
              key={target.id}
              target={target}
              result={resultById.get(target.id)}
              townHall={session.townHall}
              onLevel={(level) => props.mutate(() => session.setTargetLevel(target.id, level))}
              onRemove={() => props.mutate(() => session.removeTarget(target.id))}
            />
          ))}
          <ActionButton
            label={t('damageAddBuilding')}
            icon={<Plus size={19} color={theme.primary} />}
            disabled={session.availableBuildings.length === targets.length}
            tonal
            onPress={() => setBuildingPicker(true)}
          />
        </>
      )}
      <Spacer />
      <SectionTitle>{t('damageAttackStack')}</SectionTitle>
      <View style={styles.chips}>
        {setupIds.map((id) => (
          <SetupChip
            key={id}
            id={id}
            selected={id === setupId}
            image={quickSetupImage(session, id)}
            onPress={() =>
              props.mutate(() => {
                setSetupId(id);
                setShowAll(false);
                applyQuickSetup(session, id);
              })
            }
          />
        ))}
      </View>
      <View style={styles.sourceList}>
        {primary.map((source) => (
          <SourceRow
            key={source.kind}
            source={source}
            selection={session.sources.get(source.kind)!}
            townHall={session.townHall}
            onLevel={(level) => props.mutate(() => session.setSourceLevel(source.kind, level))}
            onCount={(count) => props.mutate(() => session.setSourceCount(source.kind, count))}
          />
        ))}
      </View>
      {session.availableSources.length === 0 ? (
        <InlineEmpty text={t('damageNoSourcesForTownHall')} />
      ) : null}
      {extra.length ? (
        <>
          {showAll ? (
            <>
              <InlineLabel>{t('damageOtherSources')}</InlineLabel>
              <View style={styles.sourceList}>
                {extra.map((source) => (
                  <SourceRow
                    key={source.kind}
                    source={source}
                    selection={session.sources.get(source.kind)!}
                    townHall={session.townHall}
                    onLevel={(level) =>
                      props.mutate(() => session.setSourceLevel(source.kind, level))
                    }
                    onCount={(count) =>
                      props.mutate(() => session.setSourceCount(source.kind, count))
                    }
                  />
                ))}
              </View>
            </>
          ) : null}
          <Pressable style={styles.textAction} onPress={() => setShowAll((value) => !value)}>
            <Plus size={18} color={theme.onSurfaceVariant} />
            <CKText role="labelLarge">
              {t(showAll ? 'damageShowFewerSources' : 'damageShowAllSources')}
            </CKText>
          </Pressable>
        </>
      ) : null}
      {setupId === calculatorSetupIds.zapQuake && targets.length > 0 ? (
        <>
          <Spacer />
          <SectionTitle>{t('damageZapQuakeOptimizer')}</SectionTitle>
          <ZapQuakePanel session={session} targets={targets} mutate={props.mutate} />
        </>
      ) : null}
      <AccountPicker
        visible={accountPicker}
        accounts={props.accountPresets}
        selectedTag={session.selectedAccountTag}
        onClose={() => setAccountPicker(false)}
        onSelect={(tag) => {
          setAccountPicker(false);
          chooseAccount(tag);
        }}
      />
      <BuildingPicker
        visible={buildingPicker}
        buildings={session.availableBuildings}
        excluded={new Set(session.targets.map((target) => target.buildingId))}
        townHall={session.townHall}
        onClose={() => setBuildingPicker(false)}
        onSelect={(id) => {
          setBuildingPicker(false);
          props.mutate(() => session.addTarget(id));
        }}
      />
    </ScrollView>
  );
}

function FarmGoalMode(props: CalculatorsScreenProps & { mutate: (operation: () => void) => void }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [accountTag, setAccountTag] = useState(
    props.session.selectedAccountTag ?? props.accountPresets[0]?.tag ?? null,
  );
  const [buildingId, setBuildingId] = useState<string>();
  const [levelNumber, setLevelNumber] = useState<number>();
  const [averageLoot, setAverageLoot] = useState('1013000');
  const [accountPicker, setAccountPicker] = useState(false);
  const [buildingPicker, setBuildingPicker] = useState(false);
  const account = props.accountPresets.find((candidate) => candidate.tag === accountTag);
  const townHall = account?.townHall ?? props.session.catalog.maxTownHall;
  const allBuildings = props.session.catalog.buildingsForTownHall(townHall);
  const buildings = farmSelectableBuildings(
    allBuildings,
    props.trackerSnapshot,
    townHall,
    props.session.catalog.maxTownHall,
  );
  const building = buildings.find((candidate) => candidate.id === buildingId);
  const levels = farmTargetLevels(building, townHall, props.session.catalog.maxTownHall);
  const level = levels.find((candidate) => candidate.level === levelNumber) ?? levels.at(-1);
  const suggestions =
    props.trackerSnapshot && accountTag
      ? farmTrackerTargets({
          snapshot: props.trackerSnapshot,
          buildings: allBuildings,
          townHall,
          maxTownHall: props.session.catalog.maxTownHall,
          goldPassPercent: props.trackerGoldPassPercent,
          preferences: props.trackerPreferences,
        })
      : [];
  const suggestion = suggestions[0];
  const trackerCost = trackerCostForSelection(suggestion, building, level);
  const resource = trackerCost?.resource ?? level?.upgradeResource ?? 'Gold';
  const resourceLabel = resourceName(resource, t);
  const upgradeCost = trackerCost?.amount ?? level?.upgradeCost;
  const leagueEstimate = farmLeagueLootEstimate(account?.league, account?.townHall ?? 0, resource);
  const perfectLoot = parseFarmAmount(averageLoot) + (leagueEstimate?.loot ?? 0);
  const scenarios = farmAttackScenarios(upgradeCost, perfectLoot);
  const selectBuilding = (id: string, target?: FarmTrackerTarget) => {
    const selected = buildings.find((candidate) => candidate.id === id);
    const selectedLevels = farmTargetLevels(selected, townHall, props.session.catalog.maxTownHall);
    setBuildingId(id);
    const nextLevel =
      target?.plannedStep?.targetLevel ??
      target?.item.steps[0]?.targetLevel ??
      selectedLevels.at(-1)?.level;
    setLevelNumber(nextLevel);
    setAverageLoot(
      String(
        defaultFarmLoot(
          selectedLevels.find((candidate) => candidate.level === nextLevel)?.upgradeResource,
        ),
      ),
    );
  };
  useEffect(() => {
    const trackerSnapshot = props.trackerSnapshot;
    if (!buildingId || !trackerSnapshot) return;
    const timer = setTimeout(() => {
      const currentAllBuildings = props.session.catalog.buildingsForTownHall(townHall);
      const currentBuildings = farmSelectableBuildings(
        currentAllBuildings,
        trackerSnapshot,
        townHall,
        props.session.catalog.maxTownHall,
      );
      const selected = currentBuildings.find((candidate) => candidate.id === buildingId);
      if (!selected) {
        setBuildingId(undefined);
        setLevelNumber(undefined);
        setAverageLoot(String(defaultFarmLoot()));
        return;
      }
      const unpaid = farmUnpaidTargetLevels(
        selected,
        trackerSnapshot,
        townHall,
        props.session.catalog.maxTownHall,
      );
      if (!unpaid || levelNumber == null || unpaid.has(levelNumber)) return;
      const matchingSuggestion = (
        accountTag
          ? farmTrackerTargets({
              snapshot: trackerSnapshot,
              buildings: currentAllBuildings,
              townHall,
              maxTownHall: props.session.catalog.maxTownHall,
              goldPassPercent: props.trackerGoldPassPercent,
              preferences: props.trackerPreferences,
            })
          : []
      ).find((candidate) => normalized(candidate.item.name) === normalized(selected.name));
      const replacement =
        matchingSuggestion?.plannedStep?.targetLevel ?? [...unpaid].sort((a, b) => a - b)[0];
      if (replacement == null) return;
      setLevelNumber(replacement);
      const replacementLevel = farmTargetLevels(
        selected,
        townHall,
        props.session.catalog.maxTownHall,
      ).find((candidate) => candidate.level === replacement);
      setAverageLoot(String(defaultFarmLoot(replacementLevel?.upgradeResource)));
    }, 0);
    return () => clearTimeout(timer);
  }, [
    accountTag,
    buildingId,
    levelNumber,
    props.session.catalog.maxTownHall,
    props.session.catalog,
    props.trackerGoldPassPercent,
    props.trackerPreferences,
    props.trackerSnapshot,
    townHall,
  ]);
  const suggestionSelected =
    suggestion &&
    building &&
    level &&
    normalized(suggestion.item.name) === normalized(building.name) &&
    suggestion.plannedStep?.targetLevel === level.level;
  return (
    <ScrollView contentContainerStyle={styles.pageContent} keyboardShouldPersistTaps="handled">
      <SectionTitle>{t('farmGoalAccountTitle')}</SectionTitle>
      <AccountPanel
        accounts={props.accountPresets}
        selected={account}
        onOpen={() => setAccountPicker(true)}
        hint={t('farmGoalAccountHint')}
      />
      <Spacer />
      <SectionTitle>{t('farmGoalTargetTitle')}</SectionTitle>
      <Surface style={styles.panel}>
        {props.trackerLoading ? (
          <Skeleton height={44} radius={16} />
        ) : !suggestionSelected && suggestion ? (
          <TrackerSuggestion
            target={suggestion}
            onPress={() => {
              const found = buildings.find(
                (candidate) => normalized(candidate.name) === normalized(suggestion.item.name),
              );
              if (found) selectBuilding(found.id, suggestion);
            }}
          />
        ) : null}
        {!props.trackerLoading && account && !props.trackerSnapshot ? (
          <TrackerPrompt onPress={() => props.onOpenUpgradeTracker(accountTag)} />
        ) : null}
        {!props.trackerLoading && props.trackerSnapshot && suggestions.length === 0 ? (
          <View style={styles.noticeRow}>
            <CircleCheck color={theme.secondary} />
            <CKText muted style={styles.flex}>
              {t('farmGoalTrackerPlanComplete')}
            </CKText>
          </View>
        ) : null}
        {!building || !level ? (
          <BuildingEmpty
            title={t('farmGoalNoTargetTitle')}
            body={t('farmGoalNoTargetBody')}
            action={t('farmGoalChooseBuilding')}
            onPress={() => setBuildingPicker(true)}
          />
        ) : (
          <>
            <View style={styles.targetSummary}>
              <MobileWebImage
                imageUrl={ImageAssets.getHomeVillageBuildingImage(building.imageName, level.level)}
                contentFit="contain"
                style={styles.targetImage}
                errorFallback={<TriangleAlert color={theme.onSurfaceVariant} />}
              />
              <View style={styles.flex}>
                <CKText role="titleSmall">
                  {buildingName(building.name, t)} · {t('sideLevel', { level: level.level })}
                </CKText>
                <CKText muted>
                  {upgradeCost
                    ? `${t('farmGoalUpgradeCostLabel')}: ${formatInt(upgradeCost, locale)} ${resourceLabel}`
                    : t('farmGoalCostUnavailable')}
                </CKText>
              </View>
            </View>
            <View style={styles.controlRow}>
              <CKText muted style={styles.flex}>
                {t('farmGoalTargetLevelLabel')}
              </CKText>
              <SelectButton
                label={t('sideLevel', { level: level.level })}
                options={levels.map((candidate) => ({
                  value: String(candidate.level),
                  label: t('sideLevel', { level: candidate.level }),
                }))}
                onSelect={(value) => {
                  const next = Number(value);
                  setLevelNumber(next);
                  setAverageLoot(
                    String(
                      defaultFarmLoot(
                        levels.find((candidate) => candidate.level === next)?.upgradeResource,
                      ),
                    ),
                  );
                }}
              />
            </View>
            <ActionButton
              label={t('farmGoalChangeBuilding')}
              icon={<SlidersHorizontal size={19} color={theme.onSurface} />}
              onPress={() => setBuildingPicker(true)}
            />
          </>
        )}
      </Surface>
      <Spacer />
      <SectionTitle>{t('farmGoalLootTitle')}</SectionTitle>
      <Surface style={styles.panel}>
        <View style={styles.lootInput}>
          <MobileWebImage
            imageUrl={resourceImage(resource)}
            contentFit="contain"
            style={styles.resourceImage}
          />
          <TextInput
            accessibilityLabel={t('farmGoalAverageLootLabel')}
            keyboardType="number-pad"
            value={averageLoot}
            onChangeText={(value) => setAverageLoot(value.replace(/[^0-9]/g, ''))}
            style={[styles.textInput, { color: theme.onSurface }]}
          />
          <CKText muted>{resourceLabel}</CKText>
        </View>
        <CKText muted>{t('farmGoalPerfectLootHint')}</CKText>
        <CKText muted>
          {account?.league && leagueEstimate?.loot
            ? t('farmGoalLeagueEstimate', {
                league: account.league,
                amount: formatInt(leagueEstimate.loot, locale),
                resource: resourceLabel,
              })
            : t('farmGoalNoLeagueLoot')}
        </CKText>
        {leagueEstimate?.starBonus ? (
          <CKText muted>
            {t('farmGoalStarBonusEstimate', {
              amount: formatInt(leagueEstimate.starBonus, locale),
              resource: resourceLabel,
            })}
          </CKText>
        ) : null}
      </Surface>
      <View style={styles.resultGap} />
      {scenarios.length ? (
        <FarmResults
          scenarios={scenarios}
          upgradeCost={upgradeCost!}
          perfectLoot={perfectLoot}
          resource={resourceLabel}
        />
      ) : (
        <InlineEmpty
          text={
            !building
              ? t('farmGoalMissingTarget')
              : !upgradeCost
                ? t('farmGoalCostUnavailable')
                : t('farmGoalMissingValues')
          }
        />
      )}
      <AccountPicker
        visible={accountPicker}
        accounts={props.accountPresets}
        selectedTag={accountTag ?? undefined}
        onClose={() => setAccountPicker(false)}
        onSelect={(tag) => {
          setAccountPicker(false);
          setAccountTag(tag);
          setBuildingId(undefined);
          setLevelNumber(undefined);
          setAverageLoot('1013000');
          props.onFarmAccountChanged(tag);
        }}
      />
      <BuildingPicker
        visible={buildingPicker}
        buildings={buildings}
        excluded={new Set()}
        townHall={townHall}
        suggestions={suggestions}
        onClose={() => setBuildingPicker(false)}
        onSelect={(id, target) => {
          setBuildingPicker(false);
          selectBuilding(id, target);
        }}
      />
    </ScrollView>
  );
}

function AccountPanel({
  accounts,
  selected,
  onOpen,
  hint,
}: {
  accounts: readonly DamageAccountPreset[];
  selected?: DamageAccountPreset;
  onOpen: () => void;
  hint: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface style={styles.accountPanel}>
      {accounts.length === 0 ? (
        <View style={styles.accountRow}>
          <MobileWebImage
            imageUrl={ImageAssets.defaultProfile}
            style={styles.accountSmallImage}
            contentFit="contain"
            errorFallback={<SearchX color={theme.onSurfaceVariant} />}
          />
          <CKText muted style={styles.flex}>
            {t('damageNoAccountsAvailable')}
          </CKText>
        </View>
      ) : (
        <>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('damageChooseAccount')}
            onPress={onOpen}
            style={styles.accountSelector}
          >
            <MobileWebImage
              imageUrl={
                selected ? ImageAssets.townHall(selected.townHall) : ImageAssets.defaultProfile
              }
              contentFit="contain"
              style={styles.accountImage}
              fallbackImageUrls={[ImageAssets.defaultProfile]}
              errorFallback={<UsersRound color={theme.onSurfaceVariant} />}
            />
            <View style={styles.flex}>
              {selected ? (
                <>
                  <CKText role="bodyLarge">{selected.name}</CKText>
                  <CKText muted>
                    {selected.tag} · {t('gameTownHallShortLevel', { level: selected.townHall })}
                  </CKText>
                </>
              ) : (
                <CKText role="bodyLarge">{t('damageChooseAccount')}</CKText>
              )}
            </View>
            <UsersRound color={theme.onSurfaceVariant} />
          </Pressable>
          <CKText muted>{hint}</CKText>
        </>
      )}
    </Surface>
  );
}

function TargetCard({
  target,
  result,
  townHall,
  onLevel,
  onRemove,
}: {
  target: DamageTarget;
  result?: DamageResult;
  townHall: number;
  onLevel: (level: number) => void;
  onRemove: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const levels = target.building.levelsForTownHall(townHall);
  return (
    <Surface style={styles.targetCard}>
      <View style={styles.targetTop}>
        <MobileWebImage
          imageUrl={ImageAssets.getHomeVillageBuildingImage(
            target.building.imageName,
            target.level.level,
          )}
          contentFit="contain"
          style={styles.targetImage}
          errorFallback={<TriangleAlert color={theme.onSurfaceVariant} />}
        />
        <View style={styles.flex}>
          <CKText role="titleMedium">{buildingName(target.building.name, t)}</CKText>
          <CKText muted>
            {t('damageHitpoints', { hitpoints: formatInt(target.hitpoints, locale) })}
          </CKText>
        </View>
        <Pressable accessibilityLabel={t('damageRemoveBuilding')} onPress={onRemove}>
          <X color={theme.onSurfaceVariant} />
        </Pressable>
      </View>
      <View style={styles.controlRow}>
        <CKText muted style={styles.flex}>
          {t('damageTargetLevelLabel')}
        </CKText>
        <SelectButton
          label={t('sideLevel', { level: target.level.level })}
          options={levels.map((level) => ({
            value: String(level.level),
            label: t('sideLevel', { level: level.level }),
          }))}
          onSelect={(value) => onLevel(Number(value))}
        />
      </View>
      {result ? <ResultSummary result={result} /> : null}
    </Surface>
  );
}

function ResultSummary({ result }: { result: DamageResult }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const accent = result.destroyed ? '#35A853' : theme.primary;
  return (
    <View style={styles.resultSummary}>
      <View style={styles.between}>
        <CKText muted>{t('damageResults')}</CKText>
        <PillSurface style={{ backgroundColor: colorWithAlpha(accent, 0.14) }}>
          <View style={styles.statusPill}>
            <MobileWebImage
              imageUrl={result.destroyed ? ImageAssets.iconTick : ImageAssets.iconCross}
              contentFit="contain"
              style={styles.statusImage}
              errorFallback={
                result.destroyed ? (
                  <CircleCheck color={accent} size={16} />
                ) : (
                  <TriangleAlert color={accent} size={16} />
                )
              }
            />
            <CKText role="labelLarge" style={{ color: accent }}>
              {t(result.destroyed ? 'damageDestroyed' : 'damageSurvives')}
            </CKText>
          </View>
        </PillSurface>
      </View>
      <View style={[styles.progressTrack, { backgroundColor: theme.surfaceContainerHighest }]}>
        <View
          style={[
            styles.progressFill,
            { backgroundColor: accent, width: `${result.percentDestroyed}%` },
          ]}
        />
      </View>
      <CKText muted>
        {t('damageResultSummary', {
          damage: formatInt(Math.round(result.totalDamage), locale),
          remaining: formatInt(Math.ceil(result.remainingHitpoints), locale),
        })}
      </CKText>
    </View>
  );
}

function SourceRow({
  source,
  selection,
  townHall,
  onLevel,
  onCount,
}: {
  source: DamageSourceDefinition;
  selection: SelectedDamageSource;
  townHall: number;
  onLevel: (level: number) => void;
  onCount: (count: number) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const levels = source.levelsForTownHall(townHall);
  const damage = source.level(selection.level)!;
  const detail =
    source.kind === DamageSourceKind.Earthquake
      ? t('damageEarthquakePercent', { percent: formatNumber(damage.earthquakePercent ?? 0) })
      : t('damagePerUse', { damage: formatInt(Math.round(damage.damage ?? 0), locale) });
  return (
    <Surface
      style={[
        styles.sourceRow,
        selection.count > 0 && { borderColor: colorWithAlpha(theme.secondary, 0.55) },
      ]}
    >
      <MobileWebImage
        imageUrl={source.imageUrl}
        contentFit="contain"
        style={styles.sourceImage}
        errorFallback={<Bolt color={theme.secondary} />}
      />
      <View style={styles.flex}>
        <CKText role="titleSmall" numberOfLines={1}>
          {sourceName(source, t)}
        </CKText>
        <CKText muted numberOfLines={1}>
          {detail}
        </CKText>
      </View>
      <View style={styles.sourceControls}>
        <SelectButton
          compact
          label={t('sideLevel', { level: selection.level })}
          options={levels.map((level) => ({
            value: String(level.level),
            label: t('sideLevel', { level: level.level }),
          }))}
          onSelect={(value) => onLevel(Number(value))}
        />
        <Stepper value={selection.count} compact onChange={onCount} />
      </View>
    </Surface>
  );
}

function ZapQuakePanel({
  session,
  targets,
  mutate,
}: {
  session: DamageCalculatorSession;
  targets: readonly DamageTarget[];
  mutate: (operation: () => void) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const lightningSource = session.catalog.source(DamageSourceKind.Lightning);
  const earthquakeSource = session.catalog.source(DamageSourceKind.Earthquake);
  const lightningSelection = session.sources.get(DamageSourceKind.Lightning);
  const earthquakeSelection = session.sources.get(DamageSourceKind.Earthquake);
  if (!lightningSource || !earthquakeSource || !lightningSelection || !earthquakeSelection)
    return <InlineEmpty text={t('damageZapQuakeUnavailable')} />;
  const lightning = lightningSource.level(lightningSelection.level)!;
  const earthquake = earthquakeSource.level(earthquakeSelection.level)!;
  return (
    <Surface style={styles.panel}>
      <View style={styles.controlRow}>
        <MobileWebImage
          imageUrl={lightningSource.imageUrl}
          contentFit="contain"
          style={styles.smallImage}
          errorFallback={<Bolt size={18} color={theme.secondary} />}
        />
        <CKText role="bodyLarge" style={styles.flex}>
          {t('damageSpellCapacity')}
        </CKText>
        <Stepper
          value={session.spellCapacity}
          minimum={1}
          onChange={(value) => mutate(() => session.setSpellCapacity(value))}
        />
      </View>
      <CKText muted>
        {t('damageZapQuakeUsesSelectedLevels', {
          lightningLevel: lightning.level,
          earthquakeLevel: earthquake.level,
        })}
      </CKText>
      {targets.length === 0 ? <CKText>{t('damageNoTargetsBody')}</CKText> : null}
      {targets.map((target) => {
        const combinations = engine.validZapQuakeCombinations({
          target,
          lightning,
          earthquake,
          capacity: session.spellCapacity,
        });
        return (
          <View key={target.id} style={styles.optimizerTarget}>
            <CKText role="titleSmall">
              {target.building.name} · {t('sideLevel', { level: target.level.level })}
            </CKText>
            <View style={styles.chips}>
              {!target.building.zapQuakeEligible ? (
                <CKText>{t('damageZapQuakeIneligible')}</CKText>
              ) : combinations.length === 0 ? (
                <CKText>{t('damageNoValidZapQuake')}</CKText>
              ) : (
                combinations.map((combo) => (
                  <PillSurface key={`${combo.lightningCount}-${combo.earthquakeCount}`}>
                    <View style={styles.statusPill}>
                      <Bolt size={16} color={theme.secondary} />
                      <CKText>
                        {t('damageZapQuakeCombination', {
                          lightning: combo.lightningCount,
                          earthquake: combo.earthquakeCount,
                          capacity: combo.capacityUsed,
                        })}
                      </CKText>
                    </View>
                  </PillSurface>
                ))
              )}
            </View>
          </View>
        );
      })}
    </Surface>
  );
}

function FarmResults({
  scenarios,
  upgradeCost,
  perfectLoot,
  resource,
}: {
  scenarios: ReturnType<typeof farmAttackScenarios>;
  upgradeCost: number;
  perfectLoot: number;
  resource: string;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface style={styles.panel}>
      <View style={styles.resultHeader}>
        <MobileWebImage
          imageUrl={ImageAssets.sword}
          contentFit="contain"
          style={styles.resultIcon}
          errorFallback={<Rocket size={28} color={theme.onSurfaceVariant} />}
        />
        <View style={styles.flex}>
          <CKText role="titleSmall">{t('farmGoalResultTitle')}</CKText>
          <CKText muted>
            {t('farmGoalResultSummary', {
              target: formatInt(upgradeCost, locale),
              resource,
              average: formatInt(perfectLoot, locale),
            })}
          </CKText>
        </View>
      </View>
      {scenarios.map((scenario) => (
        <View key={scenario.destructionPercent} style={styles.scenario}>
          <View style={styles.flex}>
            <CKText role="bodyLarge">
              {scenario.destructionPercent === 100
                ? t('farmGoalScenarioPerfect')
                : t('farmGoalScenarioAtPercent', { percent: scenario.destructionPercent })}
            </CKText>
            <CKText muted>
              {formatInt(scenario.lootPerAttack, locale)} {resource} / {t('farmGoalAttackShort')}
            </CKText>
          </View>
          <View style={styles.alignEnd}>
            <CKText role="titleLarge">{scenario.attacks}</CKText>
            <CKText muted>{t('farmGoalAttacks')}</CKText>
          </View>
        </View>
      ))}
      <CKText muted>{t('farmGoalScenarioHint')}</CKText>
    </Surface>
  );
}

function TrackerSuggestion({
  target,
  onPress,
}: {
  target: FarmTrackerTarget;
  onPress: () => void;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const level = target.plannedStep?.targetLevel ?? target.item.steps[0]?.targetLevel ?? 1;
  return (
    <View style={styles.trackerBlock}>
      <CKText muted role="bodySmall">
        {t('farmGoalTrackerNextTitle')}
      </CKText>
      <Pressable onPress={onPress} style={styles.trackerRow}>
        <MobileWebImage
          imageUrl={ImageAssets.getHomeVillageBuildingImage(target.item.name, level)}
          contentFit="contain"
          style={styles.trackerImage}
          errorFallback={<TriangleAlert size={28} color={theme.onSurfaceVariant} />}
        />
        <View style={styles.flex}>
          <CKText role="bodyLarge">{buildingName(target.item.name, t)}</CKText>
          <CKText muted>
            {t('sideLevel', { level: target.item.currentLevel })} → {t('sideLevel', { level })}
            {(target.plannedCosts ?? target.plannedStep?.costs)
              ?.map(
                (cost) => ` · ${formatInt(cost.amount, locale)} ${resourceName(cost.resource, t)}`,
              )
              .join('')}
          </CKText>
        </View>
        {isRtl ? (
          <ArrowLeft color={theme.onSurfaceVariant} />
        ) : (
          <ArrowRight color={theme.onSurfaceVariant} />
        )}
      </Pressable>
    </View>
  );
}

function TrackerPrompt({ onPress }: { onPress: () => void }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={[styles.trackerPrompt, { backgroundColor: theme.surfaceContainerHighest }]}>
      <View style={styles.noticeRow}>
        <TriangleAlert color={theme.secondary} />
        <View style={styles.flex}>
          <CKText role="bodyLarge">{t('farmGoalTrackerMissingTitle')}</CKText>
          <CKText muted>{t('farmGoalTrackerMissingBody')}</CKText>
        </View>
      </View>
      <Pressable style={styles.promptAction} onPress={onPress}>
        <Upload size={18} color={theme.onSurface} />
        <CKText role="labelLarge">{t('farmGoalOpenUpgradeTracker')}</CKText>
      </Pressable>
    </View>
  );
}

function EmptyTarget({ onChoose }: { onChoose: () => void }) {
  const { t } = useI18n();
  return (
    <Surface style={styles.panel}>
      <BuildingEmpty
        title={t('damageNoTargetTitle')}
        body={t('damageNoTargetBody')}
        action={t('damageChooseTarget')}
        onPress={onChoose}
      />
    </Surface>
  );
}
function BuildingEmpty({
  title,
  body,
  action,
  onPress,
}: {
  title: string;
  body: string;
  action: string;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <>
      <View style={styles.noticeRow}>
        <MobileWebImage
          imageUrl={ImageAssets.townHall(1)}
          contentFit="contain"
          style={styles.buildingEmptyImage}
          errorFallback={<TriangleAlert color={theme.onSurfaceVariant} />}
        />
        <View style={styles.flex}>
          <CKText role="titleSmall">{title}</CKText>
          <CKText muted>{body}</CKText>
        </View>
      </View>
      <ActionButton
        label={action}
        icon={<Plus size={19} color={theme.onPrimary} />}
        filled
        onPress={onPress}
      />
    </>
  );
}

function AccountPicker({
  visible,
  accounts,
  selectedTag,
  onClose,
  onSelect,
}: {
  visible: boolean;
  accounts: readonly DamageAccountPreset[];
  selectedTag?: string;
  onClose: () => void;
  onSelect: (tag: string | null) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useState('');
  const filtered = accounts.filter((account) =>
    `${account.name} ${account.tag}`.toLowerCase().includes(query.trim().toLowerCase()),
  );
  return (
    <Modal transparent animationType="slide" visible={visible} onRequestClose={onClose}>
      <View style={styles.sheetBackdrop}>
        <SafeAreaView style={[styles.sheet, { backgroundColor: theme.surface }]}>
          <View style={styles.sheetHeader}>
            <CKText role="titleLarge" style={styles.flex}>
              {t('damageAccountPresetShort')}
            </CKText>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={materialCloseLabel(locale)}
              onPress={onClose}
            >
              <X color={theme.onSurfaceVariant} />
            </Pressable>
          </View>
          <SearchInput value={query} onChange={setQuery} placeholder={t('damageChooseAccount')} />
          <ScrollView contentContainerStyle={styles.sheetList}>
            <PickerRow
              selected={!selectedTag}
              image={ImageAssets.defaultProfile}
              leading={<SlidersHorizontal color={theme.onSurfaceVariant} />}
              title={t('damageQuickSetupCustom')}
              subtitle={t('damageAccountSelectorHint')}
              onPress={() => onSelect(null)}
            />
            {filtered.map((account) => (
              <PickerRow
                key={account.tag}
                selected={account.tag === selectedTag}
                image={ImageAssets.townHall(account.townHall)}
                title={`${account.name} · ${t('gameTownHallShortLevel', { level: account.townHall })}`}
                subtitle={[account.tag, account.league].filter(Boolean).join(' · ')}
                onPress={() => onSelect(account.tag)}
              />
            ))}
          </ScrollView>
        </SafeAreaView>
      </View>
    </Modal>
  );
}

function BuildingPicker({
  visible,
  buildings,
  excluded,
  townHall,
  suggestions = [],
  onClose,
  onSelect,
}: {
  visible: boolean;
  buildings: readonly BuildingDefinition[];
  excluded: ReadonlySet<string>;
  townHall: number;
  suggestions?: readonly FarmTrackerTarget[];
  onClose: () => void;
  onSelect: (id: string, target?: FarmTrackerTarget) => void;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useState('');
  const normalizedQuery = query.trim().toLowerCase();
  const hasQuery = normalizedQuery.length > 0;
  const filtered = hasQuery
    ? buildings.filter((building) => building.name.toLowerCase().includes(normalizedQuery))
    : buildings;
  const trackerChoices = hasQuery
    ? []
    : suggestions.flatMap((target) => {
        const building = buildings.find(
          (candidate) => normalized(candidate.name) === normalized(target.item.name),
        );
        return building ? [{ building, target }] : [];
      });
  const trackerIds = new Set(trackerChoices.map((choice) => choice.building.id));
  const byName = new Map(buildings.map((building) => [building.name, building]));
  const common = hasQuery
    ? []
    : ['Town Hall', 'Inferno Tower', 'Eagle Artillery', 'Scattershot', 'X-Bow', 'Air Defense']
        .map((name) => byName.get(name))
        .filter(
          (building): building is BuildingDefinition =>
            Boolean(building) && !trackerIds.has(building!.id),
        );
  const commonIds = new Set(common.map((building) => building.id));
  const others = hasQuery
    ? filtered
    : buildings.filter((building) => !commonIds.has(building.id) && !trackerIds.has(building.id));
  const row = (building: BuildingDefinition, target?: FarmTrackerTarget) => (
    <PickerRow
      key={`${target ? 'suggestion-' : ''}${building.id}`}
      image={
        target?.item.imageUrl ||
        ImageAssets.getHomeVillageBuildingImage(
          building.imageName,
          target?.plannedStep?.targetLevel ??
            target?.item.steps[0]?.targetLevel ??
            building.levelsForTownHall(townHall).at(-1)?.level ??
            1,
        )
      }
      title={target ? buildingName(building.name, t) : building.name}
      subtitle={
        target
          ? [
              `${t('sideLevel', { level: target.item.currentLevel })} → ${t('sideLevel', {
                level: target.plannedStep?.targetLevel ?? target.item.steps[0]?.targetLevel ?? 1,
              })}`,
              ...(target.plannedCosts ?? target.plannedStep?.costs ?? []).map(
                (cost) =>
                  `${formatInt(Math.round(cost.amount), locale)} ${resourceName(cost.resource, t)}`,
              ),
            ].join(' · ')
          : (() => {
              const level = building.levelsForTownHall(townHall).at(-1);
              return `${t('sideLevel', { level: level?.level ?? 1 })} · ${t('damageHitpoints', {
                hitpoints: formatInt(level?.hitpoints ?? 0, locale),
              })}`;
            })()
      }
      selected={excluded.has(building.id)}
      disabled={excluded.has(building.id)}
      trailing={
        target ? (
          isRtl ? (
            <ArrowLeft color={theme.onSurfaceVariant} />
          ) : (
            <ArrowRight color={theme.onSurfaceVariant} />
          )
        ) : excluded.has(building.id) ? (
          <Check color={theme.primary} />
        ) : (
          <Plus color={theme.onSurfaceVariant} />
        )
      }
      onPress={() => onSelect(building.id, target)}
    />
  );
  return (
    <Modal transparent animationType="slide" visible={visible} onRequestClose={onClose}>
      <View style={styles.sheetBackdrop}>
        <SafeAreaView style={[styles.sheet, { backgroundColor: theme.surface }]}>
          <View style={styles.sheetHeader}>
            <CKText role="titleLarge" style={styles.flex}>
              {t('damageChooseTarget')}
            </CKText>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={materialCloseLabel(locale)}
              onPress={onClose}
            >
              <X color={theme.onSurfaceVariant} />
            </Pressable>
          </View>
          <SearchInput value={query} onChange={setQuery} placeholder={t('damageSearchBuildings')} />
          <ScrollView contentContainerStyle={styles.sheetList}>
            {trackerChoices.length ? (
              <>
                <InlineLabel>{t('farmGoalTrackerNextTitle')}</InlineLabel>
                {trackerChoices.map((choice) => row(choice.building, choice.target))}
              </>
            ) : null}
            {common.length ? (
              <>
                <InlineLabel>{t('damageCommonBuildings')}</InlineLabel>
                {common.map((building) => row(building))}
              </>
            ) : null}
            {others.length && !hasQuery ? (
              <>
                <InlineLabel>{t('damageAllBuildings')}</InlineLabel>
                {others.map((building) => row(building))}
              </>
            ) : null}
            {hasQuery ? others.map((building) => row(building)) : null}
            {filtered.length === 0 && trackerChoices.length === 0 ? (
              <EmptyState
                icon={<SearchX color={theme.onSurfaceVariant} />}
                title={t('damageNoBuildingsFound')}
                body={t('damageTryAnotherSearch')}
              />
            ) : null}
          </ScrollView>
        </SafeAreaView>
      </View>
    </Modal>
  );
}

function PickerRow({
  selected,
  disabled,
  image,
  leading,
  trailing,
  title,
  subtitle,
  onPress,
}: {
  selected?: boolean;
  disabled?: boolean;
  image: string;
  leading?: ReactNode;
  trailing?: ReactNode;
  title: string;
  subtitle: string;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      disabled={disabled}
      onPress={onPress}
      style={[
        styles.pickerRow,
        selected && { backgroundColor: theme.surfaceContainerHighest },
        disabled && { opacity: 0.58 },
      ]}
    >
      {leading ? (
        <View style={styles.pickerImage}>{leading}</View>
      ) : (
        <MobileWebImage
          imageUrl={image}
          contentFit="contain"
          style={styles.pickerImage}
          errorFallback={<TriangleAlert color={theme.onSurfaceVariant} />}
        />
      )}
      <View style={styles.flex}>
        <CKText role="bodyLarge" numberOfLines={1}>
          {title}
        </CKText>
        <CKText muted numberOfLines={1}>
          {subtitle}
        </CKText>
      </View>
      {trailing ?? (selected ? <Check color={theme.primary} /> : null)}
    </Pressable>
  );
}
function SearchInput({
  value,
  onChange,
  placeholder,
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={[styles.search, { borderColor: theme.outlineVariant }]}>
      <Search color={theme.onSurfaceVariant} />
      <TextInput
        accessibilityLabel={placeholder}
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        placeholderTextColor={theme.onSurfaceVariant}
        style={[styles.searchText, { color: theme.onSurface }]}
      />
      {value ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('generalClearSearch')}
          onPress={() => onChange('')}
        >
          <X color={theme.onSurfaceVariant} />
        </Pressable>
      ) : null}
    </View>
  );
}

function SetupChip({
  id,
  selected,
  image,
  onPress,
}: {
  id: string;
  selected: boolean;
  image?: string;
  onPress: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const icon =
    id === calculatorSetupIds.custom ? (
      <SlidersHorizontal size={18} color={selected ? theme.primary : theme.onSurfaceVariant} />
    ) : image ? (
      <MobileWebImage imageUrl={image} style={styles.chipImage} contentFit="contain" />
    ) : id === calculatorSetupIds.zapQuake ? (
      <Bolt size={18} color={selected ? theme.primary : theme.onSurfaceVariant} />
    ) : id === calculatorSetupIds.fireballQuake ? (
      <Flame size={18} color={selected ? theme.primary : theme.onSurfaceVariant} />
    ) : id === calculatorSetupIds.giantArrow ? (
      <ArrowRight size={18} color={selected ? theme.primary : theme.onSurfaceVariant} />
    ) : (
      <Rocket size={18} color={selected ? theme.primary : theme.onSurfaceVariant} />
    );
  return (
    <Pressable onPress={onPress}>
      <PillSurface
        style={[
          styles.setupChip,
          selected && {
            backgroundColor: colorWithAlpha(theme.primary, 0.18),
            borderColor: theme.primary,
          },
        ]}
      >
        {icon}
        <CKText role="labelLarge">{setupLabel(id, t)}</CKText>
      </PillSurface>
    </Pressable>
  );
}
function SelectButton({
  label,
  options,
  onSelect,
  compact,
}: {
  label: string;
  options: readonly { value: string; label: string }[];
  onSelect: (value: string) => void;
  compact?: boolean;
}) {
  const theme = useCKTheme();
  const [visible, setVisible] = useState(false);
  return (
    <>
      <Pressable
        onPress={() => setVisible(true)}
        style={[
          styles.selectButton,
          compact && styles.selectCompact,
          { borderColor: theme.outlineVariant },
        ]}
      >
        <CKText numberOfLines={1}>{label}</CKText>
        <ChevronDown size={16} color={theme.onSurfaceVariant} />
      </Pressable>
      <Modal
        transparent
        visible={visible}
        animationType="fade"
        onRequestClose={() => setVisible(false)}
      >
        <Pressable style={styles.centerBackdrop} onPress={() => setVisible(false)}>
          <Surface style={styles.optionSheet}>
            {options.map((option) => (
              <Pressable
                key={option.value}
                style={styles.optionRow}
                onPress={() => {
                  setVisible(false);
                  onSelect(option.value);
                }}
              >
                <CKText>{option.label}</CKText>
              </Pressable>
            ))}
          </Surface>
        </Pressable>
      </Modal>
    </>
  );
}
function Stepper({
  value,
  onChange,
  minimum = 0,
  maximum = Number.MAX_SAFE_INTEGER,
  compact,
}: {
  value: number;
  onChange: (value: number) => void;
  minimum?: number;
  maximum?: number;
  compact?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <View
      style={[
        styles.stepper,
        compact && styles.stepperCompact,
        { borderColor: theme.outlineVariant },
      ]}
    >
      <Pressable disabled={value <= minimum} onPress={() => onChange(value - 1)}>
        <Minus
          size={compact ? 16 : 19}
          color={value <= minimum ? theme.outlineVariant : theme.onSurface}
        />
      </Pressable>
      <CKText role="labelLarge">{value}</CKText>
      <Pressable disabled={value >= maximum} onPress={() => onChange(value + 1)}>
        <Plus
          size={compact ? 16 : 19}
          color={value >= maximum ? theme.outlineVariant : theme.onSurface}
        />
      </Pressable>
    </View>
  );
}
function ActionButton({
  label,
  icon,
  filled,
  tonal,
  disabled,
  onPress,
}: {
  label: string;
  icon: ReactNode;
  filled?: boolean;
  tonal?: boolean;
  disabled?: boolean;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      disabled={disabled}
      onPress={onPress}
      style={[
        styles.action,
        {
          backgroundColor: filled
            ? theme.primary
            : tonal
              ? colorWithAlpha(theme.primary, 0.14)
              : 'transparent',
          borderColor: filled || tonal ? 'transparent' : theme.outlineVariant,
          opacity: disabled ? 0.45 : 1,
        },
      ]}
    >
      {icon}
      <CKText role="labelLarge" style={filled ? { color: theme.onPrimary } : undefined}>
        {label}
      </CKText>
    </Pressable>
  );
}
function SectionTitle({ children }: { children: ReactNode }) {
  return (
    <CKText role="sectionTitle" style={styles.sectionTitle}>
      {children}
    </CKText>
  );
}
function InlineLabel({ children }: { children: ReactNode }) {
  return (
    <CKText muted role="labelLarge" style={styles.inlineLabel}>
      {children}
    </CKText>
  );
}
function InlineEmpty({ text }: { text: string }) {
  const theme = useCKTheme();
  return (
    <Surface style={styles.inlineEmpty}>
      <Info color={theme.onSurfaceVariant} />
      <CKText muted>{text}</CKText>
    </Surface>
  );
}
function Spacer() {
  return <View style={{ height: 22 }} />;
}

type Translator = ReturnType<typeof useI18n>['t'];
function setupLabel(id: string, t: Translator) {
  const key: MessageKey =
    id === calculatorSetupIds.zapQuake
      ? 'damageQuickSetupZapQuake'
      : id === calculatorSetupIds.fireballQuake
        ? 'damageQuickSetupFireballQuake'
        : id === calculatorSetupIds.giantArrow
          ? 'damageQuickSetupGiantArrow'
          : id === calculatorSetupIds.flameFlinger
            ? 'damageQuickSetupFlameFlinger'
            : 'damageQuickSetupCustom';
  const fallback = t(key);
  return id === calculatorSetupIds.giantArrow
    ? (translationForTid('TID_GEAR_PIERCING_ARROW') ?? fallback)
    : id === calculatorSetupIds.flameFlinger
      ? (translationForTid('TID_CHARACTER_SIEGE_MACHINE_CATAPULT') ?? fallback)
      : fallback;
}
function sourceName(source: DamageSourceDefinition, t: Translator) {
  const keys: Record<DamageSourceKind, MessageKey> = {
    [DamageSourceKind.Lightning]: 'damageSourceLightning',
    [DamageSourceKind.Earthquake]: 'damageSourceEarthquake',
    [DamageSourceKind.GiantArrow]: 'damageSourceGiantArrow',
    [DamageSourceKind.Fireball]: 'damageSourceFireball',
    [DamageSourceKind.FlameFlinger]: 'damageSourceFlameFlinger',
    [DamageSourceKind.BalloonDeath]: 'damageSourceBalloonDeath',
    [DamageSourceKind.RocketBalloonDeath]: 'damageSourceRocketBalloonDeath',
  };
  const fallback = t(keys[source.kind]);
  return source.kind === DamageSourceKind.GiantArrow
    ? (translationForTid('TID_GEAR_PIERCING_ARROW') ?? fallback)
    : source.kind === DamageSourceKind.Fireball
      ? (translationForTid('TID_GEAR_FIRE_IN_A_CAN') ?? fallback)
      : fallback;
}
function buildingName(name: string, t: Translator) {
  return name === 'Town Hall' ? t('damageTownHall') : name;
}
function resourceName(resource: string | undefined, t: Translator) {
  const key = normalized(resource);
  return key === 'gold'
    ? (translationForTid('TID_GOLD') ?? t('resourceGold'))
    : key === 'elixir'
      ? (translationForTid('TID_ELIXIR') ?? t('resourceElixir'))
      : key === 'dark elixir' || key === 'dark_elixir'
        ? (translationForTid('TID_DARK_ELIXIR') ?? t('resourceDarkElixir'))
        : (resource ?? '');
}
function resourceImage(resource?: string) {
  return `${ImageAssets.baseUrl}/resources/${normalized(resource).replace(' ', '_') || 'gold'}.webp`;
}
function quickSetupImage(session: DamageCalculatorSession, id: string) {
  for (const kind of calculatorSetupCounts[id]?.keys() ?? []) {
    const url = session.catalog.source(kind)?.imageUrl.trim();
    if (url) return url;
  }
  return undefined;
}
function normalized(value?: string) {
  return value?.trim().toLowerCase() ?? '';
}
function formatInt(value: number, locale: string) {
  return new Intl.NumberFormat(toIntlLocale(locale)).format(value);
}
function formatNumber(value: number) {
  return Number.isInteger(value) ? String(value) : value.toFixed(1);
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  hero: { width: '100%' },
  heroSafe: { flex: 1, paddingBottom: 14 },
  heroIdentity: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16,
    maxWidth: 1120,
    width: '100%',
    alignSelf: 'center',
  },
  heroHorizontal: { flexDirection: 'row', gap: 32 },
  heroCopy: { gap: 8 },
  heroTitle: { color: '#fff', fontWeight: '800' },
  heroSubtitle: { color: '#FFFFFFD1' },
  tabs: { height: 58, flexDirection: 'row' },
  tab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    borderBottomWidth: 3,
    borderBottomColor: 'transparent',
  },
  tabImage: { width: 28, height: 28 },
  pageContent: {
    width: '100%',
    maxWidth: 1120,
    alignSelf: 'center',
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 32,
  },
  emptyPage: { flex: 1, padding: 16 },
  sectionTitle: { marginBottom: 10 },
  panel: { padding: 16, gap: 12 },
  accountPanel: { padding: 14, gap: 8 },
  accountRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  accountSelector: {
    minHeight: 60,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  accountImage: { width: 44, height: 44 },
  accountSmallImage: { width: 34, height: 34 },
  flex: { flex: 1, minWidth: 0 },
  targetCard: { padding: 14, gap: 12, marginBottom: 10 },
  targetTop: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  targetImage: { width: 56, height: 56 },
  controlRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  setupChip: {
    minHeight: 38,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    paddingHorizontal: 11,
    borderWidth: StyleSheet.hairlineWidth,
  },
  chipImage: { width: 20, height: 20 },
  sourceList: { gap: 10, marginTop: 14 },
  sourceRow: {
    minHeight: 76,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderWidth: StyleSheet.hairlineWidth,
  },
  sourceImage: { width: 42, height: 42 },
  sourceControls: { alignItems: 'flex-end', gap: 6 },
  selectButton: {
    minWidth: 132,
    maxWidth: 160,
    height: 44,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
    paddingHorizontal: 12,
  },
  selectCompact: { minWidth: 108, height: 34 },
  stepper: {
    height: 38,
    minWidth: 116,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 999,
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 8,
  },
  stepperCompact: { height: 32, minWidth: 108 },
  resultSummary: { gap: 8, marginTop: 2 },
  between: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  statusPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  progressTrack: { height: 8, borderRadius: 999, overflow: 'hidden' },
  progressFill: { height: 8, borderRadius: 999 },
  action: {
    width: '100%',
    minHeight: 44,
    borderRadius: 14,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingHorizontal: 14,
    marginTop: 12,
  },
  textAction: {
    alignSelf: 'flex-start',
    minHeight: 40,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 8,
  },
  inlineLabel: { marginTop: 14, marginBottom: -6 },
  inlineEmpty: { padding: 14, flexDirection: 'row', alignItems: 'center', gap: 10 },
  statusImage: { width: 18, height: 18 },
  smallImage: { width: 28, height: 28 },
  optimizerTarget: { gap: 8, marginTop: 4 },
  targetSummary: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  lootInput: {
    minHeight: 56,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#7777',
    borderRadius: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 12,
  },
  resourceImage: { width: 24, height: 24 },
  textInput: { flex: 1, fontFamily: 'ClashKing', fontSize: 16 },
  resultGap: { height: 16 },
  resultHeader: { flexDirection: 'row', alignItems: 'flex-start', gap: 12, paddingBottom: 8 },
  resultIcon: { width: 32, height: 32 },
  scenario: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#7775',
  },
  alignEnd: { alignItems: 'flex-end' },
  trackerBlock: { gap: 6, paddingBottom: 12 },
  trackerRow: { minHeight: 52, flexDirection: 'row', alignItems: 'center', gap: 10 },
  trackerImage: { width: 36, height: 36 },
  trackerPrompt: { borderRadius: 16, padding: 12, gap: 6, marginBottom: 12 },
  noticeRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 10 },
  promptAction: {
    alignSelf: 'flex-end',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    padding: 8,
  },
  buildingEmptyImage: { width: 42, height: 42 },
  sheetBackdrop: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#0008' },
  sheet: { height: '82%', borderTopLeftRadius: 24, borderTopRightRadius: 24 },
  sheetHeader: {
    minHeight: 64,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    gap: 12,
  },
  search: {
    marginHorizontal: 16,
    minHeight: 52,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
  },
  searchText: { flex: 1, fontFamily: 'ClashKing', fontSize: 15 },
  sheetList: { padding: 8, paddingBottom: 24 },
  pickerRow: {
    minHeight: 64,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 12,
    borderRadius: 16,
  },
  pickerImage: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  centerBackdrop: { flex: 1, justifyContent: 'center', padding: 24, backgroundColor: '#0008' },
  optionSheet: { maxHeight: '70%', padding: 8 },
  optionRow: { minHeight: 48, justifyContent: 'center', paddingHorizontal: 12 },
  trackerImageRow: { flexDirection: 'row' },
  buildingGrid: { flexDirection: 'row' },
});
