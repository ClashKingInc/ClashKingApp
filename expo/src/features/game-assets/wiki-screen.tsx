import { formatWikiDuration } from './wiki-duration';
import { WikiUpgradeCost } from './wiki-upgrade-cost';
import { SceneryPlayer } from '../upgrade-tracker/presentation/scenery-player';
import { WikiItemsReference } from './wiki-items-reference';
import { WikiCosmetics } from './wiki-cosmetics';
import { WikiScrollView } from './wiki-scroll-view';
import { useWikiNavigation } from './wiki-navigation';
import { WikiEntryLink } from './wiki-entry-link';
import { wikiIsSuperTroop } from './wiki-stat-visibility';
import { useState } from 'react';
import {
  FlatList,
  RefreshControl,
  Pressable,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import { BookOpen, ChevronRight, Search } from '@/ui/icons';
import {
  CKText,
  EmptyState,
  ErrorState,
  MobileWebImage,
  SearchField,
  Surface,
  useCKTheme,
} from '../../ui';
import { isRecord, type JsonRecord } from '../../core/game-data/game-data-state';
import {
  localizedInfoForItem,
  localizedNameForItem,
} from '../../core/game-data/game-data-localization';
import { useLinkParameters } from '../../core/deep-links/link-parameters';
import { toIntlLocale, useI18n, type MessageKey } from '../../i18n';
import { WikiTable } from './wiki-table';
import { LevelSlider } from '../../ui/level-slider';
import { UpgradeItemDetailContent } from '../upgrade-tracker/presentation/upgrade-tracker-breakdowns';
import {
  WikiCatalogueContext,
  wikiCatalogue,
  wikiSections,
  type WikiEntry,
} from './wiki-catalogue';
import { ImageAssets } from '../../core/assets/image-assets';
import { WikiHeader, WikiTitle, WikiHomeHeader, WikiHomeIntro, WikiTheme } from './wiki-layout';
import { WikiComparisons, comparisonSections } from './wiki-comparisons';
import type { GameAssetsScreenProps } from './game-assets-screen';

const threeColumnSections = new Set([
  'troops',
  'spells',
  'pets',
  'heroes',
  'buildings',
  'traps',
  'equipment',
  'squads',
]);

export function WikiScreen(props: GameAssetsScreenProps & { catalogue: readonly WikiEntry[] }) {
  return (
    <WikiCatalogueContext.Provider value={props.catalogue}>
      <WikiTheme>
        <WikiScreenContent {...props} />
      </WikiTheme>
    </WikiCatalogueContext.Provider>
  );
}

function WikiScreenContent({
  manifest,
  onBack,
  onRefresh,
  loading,
  actions,
  error,
  catalogue: entries,
}: GameAssetsScreenProps & { catalogue: readonly WikiEntry[] }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { isTablet } = useAdaptiveLayout();
  const dimensions = useWindowDimensions();
  const { width } = dimensions;
  const [contentWidth, setContentWidth] = useState(width);
  const link = useLinkParameters();
  const wiki = useWikiNavigation();
  const [query, setQuery] = useState(link.q ?? '');
  const [section, setSection] = useState<string | null>(
    wikiSections.some((section) => section.id === link.category) ||
      ['squads'].includes(link.category ?? '')
      ? link.category!
      : null,
  );
  const [selected, setSelected] = useState<string | null>(link.asset ?? null);
  const entry = entries.find((item) => item.key === selected);
  const compactCards = section !== null && threeColumnSections.has(section);
  const columns = compactCards
    ? 3
    : contentWidth < 340
      ? 1
      : contentWidth >= 900
        ? 4
        : contentWidth >= 600
          ? 3
          : 2;
  const sections = wikiSections.filter((item) =>
    entries.some((entry) => entry.section === item.id),
  );
  const sectionDefinition = wikiSections.find((item) => item.id === section);
  const title = sectionDefinition
    ? t(sectionDefinition.label)
    : section === 'squads'
      ? t('wikiSquads')
      : t('sideGameAssetsTitle');
  const destination = entry?.section ?? section;
  if (destination && ['magic_items', 'magic_snacks', 'battle_modifiers'].includes(destination))
    return (
      <WikiItemsReference
        entries={entries}
        modes={destination === 'battle_modifiers'}
        onBack={onBack}
      />
    );
  if (!entry && destination && ['sceneries', 'decorations', 'obstacles'].includes(destination))
    return (
      <WikiCosmetics
        entries={entries.filter((e) => e.section === destination)}
        section={destination}
        title={t(wikiSections.find((s) => s.id === destination)!.label)}
        onBack={onBack}
      />
    );
  if (entry && comparisonSections.has(entry.section))
    return (
      <WikiComparisons
        key={entry.section}
        section={entry.section}
        title={t(wikiSections.find((s) => s.id === entry.section)!.label)}
        entries={entries.filter((e) => e.section === entry.section)}
        onBack={onBack}
      />
    );
  if (entry?.tracker)
    return (
      <UpgradeItemDetailContent
        key={entry.key}
        item={entry.tracker}
        page
        embedded
        wikiSection={entry.section}
        onClose={() => (link.asset ? onBack() : setSelected(null))}
      />
    );
  if (entry)
    return (
      <WikiReferencePage
        key={entry.key}
        entry={entry}
        onBack={() => (link.asset ? onBack() : setSelected(null))}
      />
    );
  if (section && comparisonSections.has(section))
    return (
      <WikiComparisons
        key={section}
        section={section}
        title={title}
        entries={entries.filter((e) => e.section === section)}
        onBack={() => (link.category ? onBack() : setSection(null))}
      />
    );
  const visible = entries.filter(
    (item) =>
      // League rows belong to their comparison pages, not the global item search.
      (section !== null ||
        (!item.section.endsWith('_leagues') && item.section !== 'league_tiers')) &&
      (!section ||
        (section === 'squads'
          ? isRecord(item.meta.squad)
          : item.section === section && !isRecord(item.meta.squad))) &&
      `${item.name} ${item.meta.name ?? ''}`
        .toLocaleLowerCase()
        .includes(query.trim().toLocaleLowerCase()),
  );
  const go = (id: string) => {
    if (wiki?.openSection) {
      wiki.openSection(id, entries);
      return;
    }
    setQuery('');
    setSection(id);
  };
  const representative = (id: string) =>
    entries.find((e) => e.section === id && /Barbarian|Archer Queen/.test(String(e.meta.name))) ??
    entries.find((e) => e.section === id);
  const sectionImage = (id: string) => {
    const item = representative(id),
      name = String(item?.meta.name ?? '');
    return id === 'capital_leagues'
      ? `${ImageAssets.baseUrl}/capital-base/capital-hall-pics/Building_CC_District_Hall_level_5.png`
      : id === 'sceneries'
        ? `${ImageAssets.baseUrl}/sceneries/pixel_scenery/icon.webp`
        : id === 'decorations'
          ? ImageAssets.getHomeVillageDecorationImage('Mighty Statue')
          : id === 'obstacles'
            ? `${ImageAssets.baseUrl}/obstacles/home-village/tree.webp`
            : id === 'battle_modifiers'
              ? ImageAssets.sword
              : id === 'squads'
                ? ImageAssets.getTroopImage('Barch Squad')
                : id === 'buildings'
                  ? ImageAssets.townHall(19)
                  : id === 'traps'
                    ? ImageAssets.getHomeVillageTrapImage('Bomb', 1)
                    : id === 'helpers'
                      ? ImageAssets.getHelperImage("Builder's Apprentice")
                      : id === 'guardians'
                        ? ImageAssets.getGuardianImage(name)
                        : id === 'star_bonus'
                          ? ImageAssets.attackStar
                          : id === 'war_leagues'
                            ? `${ImageAssets.baseUrl}/resources/league_medals.webp`
                            : id === 'troops'
                              ? ImageAssets.getTroopImage('Barbarian')
                              : id === 'heroes'
                                ? ImageAssets.getHeroImage('Archer Queen')
                                : id === 'spells'
                                  ? ImageAssets.getSpellImage(name || 'Rage Spell')
                                  : id === 'pets'
                                    ? ImageAssets.getPetImage(name || 'Electro Owl')
                                    : id === 'equipment'
                                      ? ImageAssets.getGearImage(name)
                                      : item?.image;
  };
  const heroImage = `${ImageAssets.baseUrl}/troops/barbarian/portrait.webp`;
  const header = !section ? (
    <WikiHomeHeader onBack={onBack} />
  ) : (
    <WikiHeader
      title={title}
      image={section ? sectionImage(section) : heroImage}
      onBack={() => (section && !link.category ? setSection(null) : onBack())}
      shareParams={{ category: section! }}
    />
  );
  const search = (
    <View style={styles.search}>
      <SearchField
        style={{ flex: 0, height: 52, borderRadius: 16 }}
        value={query}
        onChangeText={setQuery}
        placeholder={t('calcSearch')}
        searchIcon={<Search size={20} />}
      />
    </View>
  );
  const homeGroup = (label: MessageKey, ids: string[], tiles = false) => (
    <View style={[styles.homeSection, { borderBottomColor: theme.outlineVariant + '45' }]}>
      <WikiTitle size={17}>{t(label)}</WikiTitle>
      <View style={tiles ? styles.homeUnits : styles.homeRows}>
        {ids
          .filter((id) => id === 'squads' || sections.some((s) => s.id === id))
          .map((id) => {
            const label =
              id === 'squads' ? t('wikiSquads') : t(wikiSections.find((s) => s.id === id)!.label);
            return (
              <Pressable
                key={id}
                accessibilityRole="button"
                accessibilityLabel={label}
                onPress={() => go(id)}
                style={tiles ? styles.homeUnit : styles.homeRow}
              >
                <View
                  style={
                    tiles
                      ? [
                          styles.homeCircle,
                          isTablet && styles.tabletHomeCircle,
                          { backgroundColor: theme.card, borderColor: theme.outlineVariant + '40' },
                        ]
                      : styles.homeRowArt
                  }
                >
                  {sectionImage(id) ? (
                    <MobileWebImage
                      imageUrl={sectionImage(id)!}
                      contentFit="contain"
                      style={tiles ? styles.homeUnitArt : styles.homeRowArt}
                    />
                  ) : (
                    <BookOpen size={26} color={theme.secondary} />
                  )}
                </View>
                <View style={tiles ? { alignSelf: 'stretch' } : { flex: 1, gap: 3 }}>
                  <CKText
                    role="bodySmall"
                    style={tiles ? styles.homeUnitLabel : styles.homeRowTitle}
                  >
                    {label}
                  </CKText>
                </View>
                {!tiles ? <ChevronRight size={18} color={theme.onSurfaceVariant} /> : null}
              </Pressable>
            );
          })}
      </View>
    </View>
  );
  const home = !section && !query.trim();
  type GridRow = { key: string; heading?: string; entries: WikiEntry[] };
  const gridRows: GridRow[] = [];
  const grouped = section && ['buildings', 'traps', 'troops'].includes(section);
  const builderEntry = (entry: WikiEntry) =>
    ['builder', 'builderBase'].includes(String(entry.meta.village));
  const troopGroup = (entry: WikiEntry) =>
    builderEntry(entry)
      ? 'builder'
      : entry.meta.is_seasonal === true
        ? 'seasonal'
        : wikiIsSuperTroop(entry.meta)
          ? 'super'
          : entry.meta.production_building === 'Siege Workshop' ||
              entry.meta.production_building === 'Workshop'
            ? 'siege'
            : 'troops';
  const groups =
    section === 'troops'
      ? (
          [
            ['troops', t('gameTroops')],
            ['super', t('wikiSuperTroops')],
            ['siege', t('gameSiegeMachines')],
            ['seasonal', t('wikiSeasonalTroops')],
            ['builder', t('gameBaseBuilder')],
          ] as const
        ).map(([key, heading]) => ({
          key,
          heading,
          entries: visible.filter((entry) => troopGroup(entry) === key),
        }))
      : section === 'spells'
        ? (
            [
              ['elixir', t('wikiElixirSpells')],
              ['dark', t('wikiDarkSpells')],
              ['seasonal', t('wikiSeasonalSpells')],
            ] as const
          ).map(([key, heading]) => ({
            key,
            heading,
            entries: visible.filter(
              (entry) =>
                (entry.meta.is_seasonal === true
                  ? 'seasonal'
                  : entry.meta.production_building === 'Dark Spell Factory'
                    ? 'dark'
                    : 'elixir') === key,
            ),
          }))
        : grouped
          ? [
              {
                key: 'home',
                heading: t('upgradeTrackerHomeVillage'),
                entries: visible.filter((entry) => !builderEntry(entry)),
              },
              {
                key: 'builder',
                heading: t('gameBaseBuilder'),
                entries: visible.filter(builderEntry),
              },
            ]
          : [{ key: 'all', heading: undefined, entries: visible }];
  for (const group of groups) {
    if (group.heading && group.entries.length)
      gridRows.push({ key: `${group.key}:title`, heading: group.heading, entries: [] });
    for (let i = 0; i < group.entries.length; i += columns)
      gridRows.push({
        key: `${group.key}:${group.entries[i]!.key}`,
        entries: group.entries.slice(i, i + columns),
      });
  }
  if (!entries.length && error)
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: theme.background }}>
        {header}
        <ErrorState
          title={t('gameAssetsLoadError')}
          body={t('generalTryAgain')}
          actionLabel={t('generalRetry')}
          onAction={onRefresh}
        />
      </SafeAreaView>
    );

  // Keep the search input in one list host while the query changes. Swapping
  // ScrollView for FlatList on the first character drops keyboard focus.
  return (
    <SafeAreaView
      onLayout={(event) => setContentWidth(event.nativeEvent.layout.width)}
      style={{ flex: 1, backgroundColor: theme.background }}
    >
      <FlatList<GridRow>
        key={columns}
        data={home ? [] : gridRows}
        keyExtractor={(item) => item.key}
        contentContainerStyle={{ ...styles.list, paddingTop: 0, paddingHorizontal: home ? 0 : 20 }}
        keyboardShouldPersistTaps="handled"
        ListHeaderComponent={
          <View style={{ marginHorizontal: home ? 0 : -20 }}>
            {header}
            {search}
            {home ? (
              <>
                <WikiHomeIntro image={heroImage} />
                {homeGroup(
                  'wikiArmyVillage',
                  [
                    'troops',
                    'heroes',
                    'spells',
                    'pets',
                    'equipment',
                    'buildings',
                    'squads',
                    'guardians',
                    'traps',
                    'helpers',
                  ],
                  true,
                )}
                {homeGroup('wikiLeaguesRewards', [
                  'league_tiers',
                  'war_leagues',
                  'star_bonus',
                  'builder_leagues',
                  'capital_leagues',
                ])}
                {homeGroup('wikiItemsModes', ['magic_items', 'battle_modifiers'])}
                {homeGroup('wikiCosmetics', ['sceneries', 'decorations', 'obstacles'], true)}
              </>
            ) : null}
          </View>
        }
        refreshControl={
          <RefreshControl refreshing={loading} onRefresh={onRefresh} tintColor={theme.onSurface} />
        }
        ListEmptyComponent={
          home ? undefined : (
            <EmptyState
              title={entries.length ? t('searchNoResult') : t('damageNoStaticDataTitle')}
              body={
                entries.length ? t('todoTryAnotherSearchOrFilter') : t('damageNoStaticDataBody')
              }
            />
          )
        }
        renderItem={({ item: row }) =>
          row.heading ? (
            <WikiTitle size={19} style={{ paddingTop: 10, paddingBottom: 8 }}>
              {row.heading}
            </WikiTitle>
          ) : (
            <View style={styles.row}>
              {row.entries.map((item) => (
                <WikiEntryLink
                  key={item.key}
                  entryKey={item.key}
                  label={item.name}
                  onFallback={() => {
                    if (comparisonSections.has(item.section)) {
                      go(item.section);
                      return;
                    }
                    if (wiki) wiki.openEntry(item.key);
                    else setSelected(item.key);
                  }}
                  style={styles.cell}
                >
                  <Surface radius={18} style={[styles.card, compactCards && styles.compactCard]}>
                    {item.image ? (
                      <MobileWebImage
                        imageUrl={item.image}
                        contentFit="contain"
                        cachePolicy="memory-disk"
                        style={styles.art}
                      />
                    ) : (
                      <View style={styles.art}>
                        <BookOpen size={38} color={theme.onSurfaceVariant} />
                      </View>
                    )}
                    <CKText role="bodySmall" style={styles.cardTitle}>
                      {item.name}
                    </CKText>
                  </Surface>
                </WikiEntryLink>
              ))}
              {Array.from({ length: columns - row.entries.length }, (_, index) => (
                <View key={`empty:${index}`} style={{ flex: 1 }} />
              ))}
            </View>
          )
        }
      />
    </SafeAreaView>
  );
}

const fields: Readonly<Record<string, MessageKey>> = {
  gold: 'resourceGold',
  elixir: 'resourceElixir',
  dark_elixir: 'resourceDarkElixir',
  shiny_ore: 'resourceShinyOre',
  glowy_ore: 'resourceGlowyOre',
  starry_ore: 'resourceStarryOre',
  first_place: 'cwlFirstPlace',
  position_medal_diff: 'wikiPositionDifference',
  bonus_reward: 'wikiBonusMedals',
  minimum_bonus_amount: 'wikiMinimumBonuses',
  promote_percentage: 'cwlPromotionZone',
  demote_percentage: 'cwlDemotionZone',
  promotions: 'cwlPromotionZone',
  demotions: 'cwlDemotionZone',
  group_size: 'wikiGroupSize',
  battle_count: 'rankedLeagueBattles',
  trophy_start: 'gameTrophies',
  townhall_cap: 'gameTownHallLevel',
  boost_time_seconds: 'warAttacksDetailsDuration',
  boost_multiplier: 'wikiBoost',
  upgrade_cost: 'gameItemUpgradeCost',
  required_townhall: 'gameTownHallLevel',
  duration: 'warAttacksDetailsDuration',
  clan_xp: 'gameExpLevel',
};
export function WikiReferencePage({ entry, onBack }: { entry: WikiEntry; onBack: () => void }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [selectedLevel, setLevel] = useState(1);
  const [hall, setHall] = useState(19);
  const levels = Array.isArray(entry.meta.levels) ? entry.meta.levels.filter(isRecord) : [];
  const maximum = Math.max(1, ...levels.map((level) => Number(level.level) || 1));
  const level = levels.find((row) => row.level === selectedLevel);
  const rewards = Array.isArray(entry.meta.rewards) ? entry.meta.rewards.filter(isRecord) : [];
  const selectedReward = rewards.find((reward) => reward.townhall_level === hall);
  const number = new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 2 });
  const medalData = isRecord(entry.meta.ranked_medals) ? entry.meta.ranked_medals : null;
  const renderFields = (record: JsonRecord) =>
    Object.entries(record).flatMap(([key, value]) =>
      key !== 'upgrade_cost' && key !== 'build_cost' && fields[key] && typeof value === 'number'
        ? [
            <View key={key} style={styles.stat}>
              <CKText muted style={styles.statLabel}>
                {t(fields[key]!)}
              </CKText>
              <CKText>
                {key.endsWith('_seconds') || key === 'duration'
                  ? formatWikiDuration(value)
                  : number.format(value)}
                {key.endsWith('_percentage') ? '%' : key === 'boost_multiplier' ? '×' : ''}
              </CKText>
            </View>,
          ]
        : [],
    );
  const modifier =
    typeof entry.meta.battle_modifier === 'string'
      ? wikiCatalogue(null).find(
          (item) =>
            item.section === 'battle_modifiers' && item.meta.name === entry.meta.battle_modifier,
        )
      : null;
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: theme.background }}>
      <WikiScrollView contentContainerStyle={{ ...styles.article, paddingTop: 0 }}>
        <View style={{ marginHorizontal: -20 }}>
          <WikiHeader
            title={entry.name || `${t('gameTownHallLevel')} ${String(entry.meta.townhall_level)}`}
            image={entry.image}
            fallbackImages={typeof entry.meta.icon === 'string' ? [entry.meta.icon] : []}
            onBack={onBack}
            large
            shareParams={{ category: entry.section, asset: entry.key }}
          />
        </View>
        {typeof entry.meta.music === 'string' ? (
          <SceneryPlayer source={`${ImageAssets.baseUrl}/${entry.meta.music}`} />
        ) : null}
        {localizedInfoForItem(entry.meta) ? (
          <CKText>{localizedInfoForItem(entry.meta).replaceAll('\\n', '\n')}</CKText>
        ) : null}
        {maximum > 1 ? (
          <LevelSlider
            label={t('gameItemLevels')}
            minimum={1}
            maximum={maximum}
            value={selectedLevel}
            onChange={setLevel}
            showStepButtons
            compact
          />
        ) : null}
        <WikiUpgradeCost meta={entry.meta} level={level} />
        {renderFields(entry.meta)}
        {level ? renderFields(level) : null}
        {levels.length > 1 ? (
          <View style={{ gap: 12 }}>
            <WikiTitle size={18}>{t('wikiStatsByLevel')}</WikiTitle>
            <WikiTable
              identityLabel={t('wikiLevel')}
              identityWidth={70}
              columns={Object.keys(fields)
                .filter((key) => levels.some((row) => typeof row[key] === 'number'))
                .map((key) => ({
                  key,
                  label: t(fields[key]!),
                  width: 128,
                  image:
                    key === 'upgrade_cost'
                      ? `${ImageAssets.baseUrl}/resources/gems.webp`
                      : undefined,
                }))}
              rows={levels.map((row) => ({
                key: String(row.level),
                label: String(row.level),
                selected: row.level === selectedLevel,
                values: Object.fromEntries(
                  Object.keys(fields).map((key) => [
                    key,
                    typeof row[key] === 'number'
                      ? key.endsWith('_seconds')
                        ? formatWikiDuration(row[key])
                        : number.format(row[key]) + (key === 'boost_multiplier' ? '×' : '')
                      : '—',
                  ]),
                ),
              }))}
            />
          </View>
        ) : null}
        {['sceneries', 'decorations', 'obstacles'].includes(entry.section) ? (
          <View style={{ gap: 12 }}>
            <WikiTitle size={18}>{t('generalDetails')}</WikiTitle>
            {[
              ['character', 'gameHeroes'],
              ['tier', 'gameItemRarity'],
              ['village', 'dashboardUpgradeTrackerVillage'],
              ['type', 'dashboardUpgradeTrackerVillage'],
              ['width', 'upgradeTrackerSize'],
              ['max_count', 'generalMaximum'],
              ['build_cost', 'gameItemUpgradeCost'],
              ['clear_cost', 'emoteCostLabel'],
              ['loot_count', 'capitalRaidRewards'],
              ['pass_reward', 'upgradeTrackerPassReward'],
              ['rarity', 'gameItemRarity'],
            ].map(([key, label]) => {
              const value = entry.meta[key!];
              if (value == null) return null;
              const resource =
                key === 'build_cost'
                  ? entry.meta.build_resource
                  : key === 'clear_cost'
                    ? entry.meta.clear_resource
                    : key === 'loot_count'
                      ? entry.meta.loot_resource
                      : null;
              const display =
                typeof value === 'boolean'
                  ? value
                    ? t('generalYes')
                    : t('generalNo')
                  : key === 'width'
                    ? `${String(value)} × ${String(value)}`
                    : typeof value === 'number'
                      ? number.format(value)
                      : String(value);
              return (
                <View
                  key={key}
                  style={[
                    styles.stat,
                    { backgroundColor: theme.card, padding: 14, borderRadius: 10 },
                  ]}
                >
                  <CKText muted>{t(label as MessageKey)}</CKText>
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                    {typeof resource === 'string' ? (
                      <MobileWebImage
                        imageUrl={`${ImageAssets.baseUrl}/resources/${resource.toLowerCase().replaceAll(' ', '_')}.webp`}
                        contentFit="contain"
                        style={{ width: 22, height: 24 }}
                      />
                    ) : null}
                    <CKText>
                      {key === 'village' || key === 'type'
                        ? value === 'home'
                          ? t('upgradeTrackerHomeVillage')
                          : value === 'builder'
                            ? t('gameBaseBuilder')
                            : display
                        : display}
                    </CKText>
                  </View>
                </View>
              );
            })}
          </View>
        ) : null}

        {medalData ? (
          <View style={{ gap: 12 }}>
            <CKText role="sectionTitle">{t('wikiRankedMedals')}</CKText>
            {typeof medalData.maximum_per_week === 'number' ? (
              <View style={styles.stat}>
                <CKText muted>{t('statsWeekly')}</CKText>
                <CKText>{number.format(medalData.maximum_per_week)}</CKText>
              </View>
            ) : null}
            {Array.isArray(medalData.placement_rewards)
              ? medalData.placement_rewards.filter(isRecord).map((reward, index, rows) => (
                  <View key={index} style={styles.stat}>
                    <CKText muted>
                      {String(reward.minimum_rank)}
                      {rows[index + 1] ? `–${Number(rows[index + 1]!.minimum_rank) - 1}` : '+'}
                    </CKText>
                    <CKText>{number.format(Number(reward.medals))}</CKText>
                  </View>
                ))
              : null}
          </View>
        ) : null}
        {isRecord(entry.meta.cwl_medals) ? (
          <>
            <CKText role="sectionTitle">{t('capitalRaidRewards')}</CKText>
            {renderFields(entry.meta.cwl_medals)}
          </>
        ) : null}
        {rewards.length ? (
          <LevelSlider
            label={t('gameTownHallLevel')}
            minimum={Math.min(...rewards.map((row) => Number(row.townhall_level)))}
            maximum={Math.max(...rewards.map((row) => Number(row.townhall_level)))}
            value={hall}
            onChange={setHall}
            showStepButtons
            compact
          />
        ) : null}
        {isRecord(entry.meta.resources) || isRecord(selectedReward?.resources) ? (
          <>
            <CKText role="sectionTitle">{t('capitalRaidRewards')}</CKText>
            {renderFields((selectedReward?.resources ?? entry.meta.resources) as JsonRecord)}
          </>
        ) : null}
        {modifier ? (
          <View style={styles.stat}>
            <CKText muted>{t('calcBattleModifier')}</CKText>
            <CKText>{localizedNameForItem(modifier.meta)}</CKText>
          </View>
        ) : null}
        {Array.isArray(entry.meta.modifiers)
          ? entry.meta.modifiers.filter(isRecord).map((rule, index) => (
              <Surface key={index} radius={16} style={{ padding: 16, gap: 10 }}>
                <CKText role="titleMedium">
                  {t(rule.attacker ? 'warAttacksDetailsAttacker' : 'warAttacksDetailsDefender')} ·{' '}
                  {t(
                    wikiSections.find((section) => section.id === rule.type)?.label ??
                      (rule.type === 'common_equipment' || rule.type === 'epic_equipment'
                        ? 'gameAssetsCategoryEquipment'
                        : 'generalStats'),
                  )}
                </CKText>
                {['damage_multiplier', 'hp_multiplier', 'minus_levels'].map((key) =>
                  typeof rule[key] === 'number' ? (
                    <View key={key} style={styles.stat}>
                      <CKText muted>
                        {t(
                          key === 'damage_multiplier'
                            ? 'wikiDamage'
                            : key === 'hp_multiplier'
                              ? 'gameItemHitpoints'
                              : 'gameItemLevels',
                        )}
                      </CKText>
                      <CKText>
                        {key === 'minus_levels'
                          ? `−${number.format(Number(rule[key]))}`
                          : `${number.format(Number(rule[key]))}%`}
                      </CKText>
                    </View>
                  ) : null,
                )}
              </Surface>
            ))
          : null}
      </WikiScrollView>
    </SafeAreaView>
  );
}
const styles = StyleSheet.create({
  homeSection: {
    paddingVertical: 20,
    paddingHorizontal: 18,
    gap: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  homeUnits: { flexDirection: 'row', flexWrap: 'wrap', columnGap: '4%', rowGap: 18 },
  homeUnit: { width: '22%', minWidth: 0, alignItems: 'center', gap: 8 },
  homeCircle: {
    width: '100%',
    aspectRatio: 1,
    borderRadius: 999,
    borderWidth: StyleSheet.hairlineWidth,
    alignItems: 'center',
    justifyContent: 'center',
  },
  homeUnitArt: { width: '90%', height: '92%' },
  // Tablet columns provide room for labels, not proportionally enlarged icons.
  tabletHomeCircle: { width: 96, height: 96 },
  homeUnitLabel: { fontSize: 12, lineHeight: 17, textAlign: 'center' },
  homeRows: { gap: 0 },
  homeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 13,
    paddingVertical: 10,
    minHeight: 64,
  },
  homeRowArt: { width: 39, height: 43, flexShrink: 0 },
  homeRowTitle: { fontSize: 14, lineHeight: 20 },
  homeSubtitle: { fontSize: 12, lineHeight: 17 },
  homeChips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 2 },

  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  back: { minWidth: 48, minHeight: 48, alignItems: 'center', justifyContent: 'center' },
  title: { flex: 1, textAlign: 'center' },
  search: { paddingHorizontal: 18, paddingVertical: 16 },
  list: {
    padding: 20,
    gap: 14,
    width: '100%',
    maxWidth: 1200,
    alignSelf: 'center',
    paddingBottom: 40,
  },
  // Each native row stretches its own cards only; no shared/global card height.
  row: { flexDirection: 'row', alignItems: 'stretch', gap: 14 },
  cell: { flex: 1, minWidth: 0 },
  card: { padding: 16, gap: 10, flex: 1 },
  compactCard: { padding: 10, gap: 8 },
  art: { height: 92, width: '100%', alignItems: 'center', justifyContent: 'center' },
  cardTitle: { textAlign: 'center' },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 'auto',
  },
  article: {
    padding: 20,
    gap: 18,
    width: '100%',
    maxWidth: 800,
    alignSelf: 'center',
    paddingBottom: 40,
  },
  hero: { height: 172, width: '100%' },
  stat: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 16 },
  statLabel: { flex: 1 },
});
