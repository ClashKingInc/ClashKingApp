import { MorphFilterSheet } from '../../ui/morph-filter-sheet';
import { Check } from 'lucide-react-native';
import { WikiScrollView } from './wiki-scroll-view';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { CKText, useCKTheme, ProfileTabs, SelectionPicker, MobileWebImage } from '../../ui';
import { toIntlLocale, useI18n, type MessageKey } from '../../i18n';
import { ImageAssets } from '../../core/assets/image-assets';
import { gameDataState, isRecord, type JsonRecord } from '../../core/game-data/game-data-state';

import { localizedNameForItem } from '../../core/game-data/game-data-localization';
import type { WikiEntry } from './wiki-catalogue';
import { WikiHeader } from './wiki-layout';
import { WikiTable, type WikiColumn, type WikiTableRow } from './wiki-table';

export const comparisonSections = new Set([
  'league_tiers',
  'war_leagues',
  'star_bonus',
  'builder_leagues',
  'capital_leagues',
]);
const resourceKeys = [
  'gold',
  'elixir',
  'dark_elixir',
  'shiny_ore',
  'glowy_ore',
  'starry_ore',
] as const;
const resourceLabels: Record<(typeof resourceKeys)[number], MessageKey> = {
  gold: 'resourceGold',
  elixir: 'resourceElixir',
  dark_elixir: 'resourceDarkElixir',
  shiny_ore: 'resourceShinyOre',
  glowy_ore: 'resourceGlowyOre',
  starry_ore: 'resourceStarryOre',
};
export const wikiResource = (key: string) => `${ImageAssets.baseUrl}/resources/${key}.webp`;
const record = (value: unknown): JsonRecord => (isRecord(value) ? value : {});
const numeric = (value: unknown): number | null =>
  typeof value === 'number' && Number.isFinite(value) ? value : null;

export function WikiComparisons({
  section,
  title,
  entries,
  onBack,
}: {
  section: string;
  title: string;
  entries: readonly WikiEntry[];
  onBack: () => void;
}) {
  const theme = useCKTheme(),
    { t, locale } = useI18n();
  const [metric, setMetric] = useState('medals');
  const [hall, setHall] = useState(19);
  const [hallPicker, setHallPicker] = useState(false);
  const format = new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 0 });
  const fmt = (value: unknown) => (numeric(value) === null ? '—' : format.format(value as number));
  const percent = (value: unknown) => (numeric(value) === null ? '—' : `${fmt(value)}%`);
  const icon =
    section === 'star_bonus'
      ? ImageAssets.attackStar
      : section === 'war_leagues'
        ? wikiResource('league_medals')
        : section === 'capital_leagues'
          ? `${ImageAssets.baseUrl}/capital-base/capital-hall-pics/Building_CC_District_Hall_level_5.png`
          : entries.at(-1)?.image;
  const sorted = [...entries].sort(
    (a, b) =>
      Number(b.meta.league_tier ?? b.meta.townhall_level ?? b.meta._id ?? 0) -
      Number(a.meta.league_tier ?? a.meta.townhall_level ?? a.meta._id ?? 0),
  );
  let columns: WikiColumn[] = [],
    rows: WikiTableRow[] = [];
  const identity = (e: WikiEntry) => ({
    key: e.key,
    label: e.name.replace(/ League/gi, '') || fmt(e.meta.townhall_level),
    image: e.image,
  });
  const appendResourceColumns = () =>
    resourceKeys.map((key) => ({
      key,
      label: t(resourceLabels[key]),
      image: wikiResource(key),
      width: 104,
    }));
  if (section === 'star_bonus') {
    columns = appendResourceColumns();
    rows = sorted.map((e) => ({
      ...identity(e),
      values: Object.fromEntries(
        resourceKeys.map((key) => [key, fmt(record(e.meta.resources)[key])]),
      ),
    }));
  } else if (section === 'war_leagues') {
    columns = [
      ...Array.from({ length: 8 }, (_, i) => ({
        key: `place:${i + 1}`,
        label: `${i + 1}`,
        image: wikiResource('league_medals'),
        width: 64,
      })),
      { key: 'bonus', label: t('wikiBonusMedals'), image: wikiResource('league_medals') },
      { key: 'minimum', label: t('wikiMinimumBonuses') },
      { key: 'up', label: t('cwlPromotionZone') },
      { key: 'down', label: t('cwlDemotionZone') },
      { key: 'size', label: t('wikiWarSize') },
      { key: 'mode', label: t('wikiBattleModes'), width: 150 },
    ];
    rows = sorted.map((e) => {
      const medals = record(e.meta.cwl_medals);
      return {
        ...identity(e),
        values: {
          ...Object.fromEntries(
            Array.from({ length: 8 }, (_, i) => [
              `place:${i + 1}`,
              numeric(medals.first_place) === null || numeric(medals.position_medal_diff) === null
                ? '—'
                : fmt(Number(medals.first_place) - i * Number(medals.position_medal_diff)),
            ]),
          ),
          bonus: fmt(medals.bonus_reward),
          minimum: fmt(medals.minimum_bonus_amount),
          up: fmt(e.meta.promotions),
          down: fmt(e.meta.demotions),
          size: e.meta['15v15_only'] ? '15v15' : '15v15 / 30v30',
          mode: modeName(e.meta.battle_modifier, entries, t),
        },
      };
    });
  } else if (section === 'league_tiers') {
    if (metric === 'medals') {
      columns = [
        {
          key: 'medals',
          label: t('wikiRankedMedals'),
          image: wikiResource('ranked_medals'),
          width: 150,
        },
      ];
      rows = sorted.map((e) => ({
        ...identity(e),
        values: {
          medals:
            numeric(record(e.meta.ranked_medals).maximum_per_week) === null
              ? Array.isArray(record(e.meta.ranked_medals).placement_rewards)
                ? t('wikiByPlacement')
                : '—'
              : fmt(record(e.meta.ranked_medals).maximum_per_week),
        },
      }));
    } else if (metric === 'loot') {
      columns = appendResourceColumns().slice(0, 3);
      rows = sorted
        .filter(
          (e) =>
            Array.isArray(e.meta.rewards) &&
            e.meta.rewards.some(
              (r) =>
                isRecord(r) &&
                r.townhall_level === hall &&
                Object.values(record(r.resources)).some((v) => typeof v === 'number' && v > 0),
            ),
        )
        .map((e) => {
          const reward = (
            Array.isArray(e.meta.rewards) ? e.meta.rewards.filter(isRecord) : []
          ).find((r) => r.townhall_level === hall);
          return {
            ...identity(e),
            values: Object.fromEntries(
              resourceKeys.slice(0, 3).map((key) => [key, fmt(record(reward?.resources)[key])]),
            ),
          };
        });
    } else {
      columns = [
        { key: 'battles', label: t('rankedLeagueBattles'), image: ImageAssets.sword },
        { key: 'group', label: t('wikiGroupSize') },
        { key: 'up', label: t('cwlPromotionZone') },
        { key: 'down', label: t('cwlDemotionZone') },
        { key: 'th', label: t('wikiMinimumTownHall'), width: 135 },
        { key: 'mode', label: t('wikiBattleModes'), width: 150 },
      ];
      rows = sorted.map((e) => ({
        ...identity(e),
        values: {
          battles: fmt(e.meta.battle_count),
          group: fmt(e.meta.group_size),
          up: percent(e.meta.promote_percentage),
          down: percent(e.meta.demote_percentage),
          th: fmt(
            Array.isArray(e.meta.rewards)
              ? e.meta.rewards.filter(isRecord)[0]?.townhall_level
              : undefined,
          ),
          mode: modeName(e.meta.battle_modifier, entries, t),
        },
      }));
    }
  } else {
    columns = [
      {
        key: 'trophies',
        label: t('gameTrophies'),
        image:
          section === 'capital_leagues' ? ImageAssets.capitalTrophy : ImageAssets.builderBaseTrophy,
      },
    ];
    if (section === 'capital_leagues')
      columns.push({ key: 'xp', label: t('gameExpLevel'), image: ImageAssets.xp, width: 180 });
    rows = sorted.map((e) => ({
      ...identity(e),
      values: { trophies: fmt(e.meta.trophy_start), xp: fmt(e.meta.clan_xp) },
    }));
  }
  const placementEntries =
    section === 'league_tiers' && metric === 'medals'
      ? sorted.filter((e) => Array.isArray(record(e.meta.ranked_medals).placement_rewards))
      : [];
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: theme.background }}>
      <WikiScrollView contentContainerStyle={styles.page}>
        <WikiHeader
          title={title}
          compact
          shareParams={{ category: section }}
          image={icon}
          onBack={onBack}
        />
        <View style={styles.content}>
          {section === 'league_tiers' ? (
            <ProfileTabs
              variant="underline"
              overflow="fit"
              tabs={[
                { key: 'medals', label: t('wikiRankedMedals') },
                { key: 'rules', label: t('competitiveRules') },
                { key: 'loot', label: t('wikiLeagueBonus') },
              ]}
              selectedKey={metric}
              onSelect={setMetric}
            />
          ) : null}
          {section === 'league_tiers' && metric === 'loot' ? (
            <SelectionPicker
              externallyManaged
              onOpen={() => setHallPicker(true)}
              title={t('gameTownHallLevel')}
              selectedKey={String(hall)}
              onSelect={(key) => setHall(Number(key))}
              options={[
                ...new Set(
                  sorted.flatMap((e) =>
                    Array.isArray(e.meta.rewards)
                      ? e.meta.rewards.filter(isRecord).map((r) => Number(r.townhall_level))
                      : [],
                  ),
                ),
              ]
                .sort((a, b) => b - a)
                .map((level) => ({
                  key: String(level),
                  label: t('gameTownHallLevelNumber', { level }),
                  icon: (
                    <MobileWebImage
                      imageUrl={ImageAssets.townHall(level)}
                      contentFit="contain"
                      style={{ width: 30, height: 30 }}
                    />
                  ),
                }))}
            />
          ) : null}
          {section === 'war_leagues' ? (
            <CKText muted role="bodySmall">
              {t('wikiCwlBaselineNote')}
            </CKText>
          ) : null}
          <WikiTable
            identityLabel={t(section === 'star_bonus' ? 'gameTownHallLevel' : 'gameLeague')}
            singleLineIdentity
            identityWidth={
              section === 'star_bonus'
                ? 84
                : section === 'capital_leagues' || section === 'builder_leagues'
                  ? 135
                  : 174
            }
            columns={columns}
            rows={rows}
          />
          {placementEntries.map((e) => (
            <View key={e.key} style={{ gap: 12 }}>
              <CKText role="sectionTitle">{e.name}</CKText>
              <WikiTable
                identityLabel={t('wikiPlacement')}
                columns={[
                  {
                    key: 'medals',
                    label: t('wikiRankedMedals'),
                    image: wikiResource('ranked_medals'),
                    width: 160,
                  },
                ]}
                rows={(record(e.meta.ranked_medals).placement_rewards as unknown[])
                  .filter(isRecord)
                  .map((r, i, all) => ({
                    key: String(r.minimum_rank),
                    label: `${fmt(r.minimum_rank)}${all[i + 1] ? `–${fmt(Number(all[i + 1]!.minimum_rank) - 1)}` : '+'}`,
                    values: { medals: fmt(r.medals) },
                  }))}
              />
            </View>
          ))}
        </View>
      </WikiScrollView>
      {hallPicker ? (
        <MorphFilterSheet
          title={t('gameTownHallLevel')}
          applyLabel={t('calcSearch')}
          onClose={() => setHallPicker(false)}
          onReset={() => setHall(19)}
          onApply={() => {}}
        >
          {() => (
            <>
              {[
                ...new Set(
                  sorted.flatMap((e) =>
                    Array.isArray(e.meta.rewards)
                      ? e.meta.rewards.filter(isRecord).map((r) => Number(r.townhall_level))
                      : [],
                  ),
                ),
              ]
                .sort((a, b) => b - a)
                .map((level) => (
                  <Pressable
                    key={level}
                    accessibilityRole="radio"
                    accessibilityState={{ checked: hall === level }}
                    onPress={() => {
                      setHall(level);
                      setHallPicker(false);
                    }}
                    style={{ flexDirection: 'row', alignItems: 'center', gap: 12, minHeight: 52 }}
                  >
                    <MobileWebImage
                      imageUrl={ImageAssets.townHall(level)}
                      style={{ width: 32, height: 36 }}
                      contentFit="contain"
                    />
                    <CKText style={{ flex: 1 }}>{t('gameTownHallLevelNumber', { level })}</CKText>
                    {hall === level ? <Check size={20} color={theme.primary} /> : null}
                  </Pressable>
                ))}
            </>
          )}
        </MorphFilterSheet>
      ) : null}
    </SafeAreaView>
  );
}
function modeName(value: unknown, entries: readonly WikiEntry[], t: (key: MessageKey) => string) {
  if (typeof value !== 'string' || !value) return '—';
  if (value === 'Hard Mode') return t('wikiEsportsMode');
  // CWL receives only its own section entries, so resolve mode labels from the
  // full game catalogue rather than depending on the current table's rows.
  const leagueData = gameDataState.bundleData.league_tiers;
  const league = (Array.isArray(leagueData) ? leagueData.filter(isRecord) : []).find(
    (entry) => entry.battle_modifier === value,
  );
  if (league) return localizedNameForItem(league).replace(/ League/gi, '');
  const raw = gameDataState.bundleData.battle_modifiers;
  const rows = Array.isArray(raw)
    ? raw
    : isRecord(raw) && Array.isArray(raw.items)
      ? raw.items
      : [];
  const mode = rows.filter(isRecord).find((e) => e.name === value);
  return mode
    ? localizedNameForItem(mode)
    : (entries.find((e) => e.section === 'battle_modifiers' && e.meta.name === value)?.name ??
        value);
}
const styles = StyleSheet.create({
  page: { width: '100%', maxWidth: 1000, alignSelf: 'center', paddingBottom: 32 },
  content: { paddingHorizontal: 18, paddingTop: 8, gap: 12 },
  choices: { gap: 8, paddingVertical: 2 },
});
