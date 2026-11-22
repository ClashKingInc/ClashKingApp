import { useState } from 'react';
import { View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { CKText, ProfileTabs, InfoTooltip, MobileWebImage, useCKTheme } from '../../ui';
import { useI18n } from '../../i18n';
import { gameDataState, isRecord } from '../../core/game-data/game-data-state';
import { localizedInfoForItem } from '../../core/game-data/game-data-localization';
import { WikiHeader } from './wiki-layout';
import { WikiTable } from './wiki-table';
import { WikiScrollView } from './wiki-scroll-view';
import { wikiResource } from './wiki-comparisons';
import type { WikiEntry } from './wiki-catalogue';
import { ImageAssets } from '../../core/assets/image-assets';

const kind = (entry: WikiEntry) =>
  String(
    entry.meta.type ??
      (entry.section === 'magic_snacks'
        ? 'snack'
        : (['book', 'hammer', 'potion', 'rune'].find((type) =>
            String(entry.meta.name).toLowerCase().includes(type),
          ) ?? 'other')),
  );
export function WikiItemsReference({
  entries,
  modes,
  onBack,
}: {
  entries: readonly WikiEntry[];
  modes: boolean;
  onBack: () => void;
}) {
  const { t } = useI18n(),
    theme = useCKTheme();
  const [selected, setSelected] = useState('all');
  const available = entries.filter((entry) =>
    modes
      ? entry.section === 'battle_modifiers'
      : ['magic_items', 'magic_snacks'].includes(entry.section) &&
        !['Training Potion', 'Training Treat'].includes(String(entry.meta.name)),
  );
  const kinds = [...new Set(available.map(kind))];
  const label = (value: string) =>
    t(
      (
        {
          all: 'generalAll',
          book: 'wikiBooks',
          hammer: 'wikiHammers',
          potion: 'wikiPotions',
          rune: 'wikiRunes',
          snack: 'wikiMagicSnacks',
          other: 'generalOthers',
        } as const
      )[value as 'all'] ?? 'generalOthers',
    );
  const shown = available.filter((entry) => selected === 'all' || kind(entry) === selected);
  const fmt = (value: unknown) => (typeof value === 'number' ? String(value) : '—');
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: theme.background }}>
      <WikiScrollView contentContainerStyle={{ paddingBottom: 32 }}>
        <WikiHeader
          title={t(modes ? 'wikiBattleModes' : 'wikiMagicItems')}
          image={modes ? ImageAssets.sword : available[0]?.image}
          compact
          onBack={onBack}
          shareParams={{ category: modes ? 'battle_modifiers' : 'magic_items' }}
        />
        <View style={{ padding: 18, gap: 18 }}>
          {!modes ? (
            <ProfileTabs
              variant="underline"
              overflow="scroll"
              selectedKey={selected}
              onSelect={setSelected}
              tabs={['all', ...kinds].map((key) => ({ key, label: label(key) }))}
            />
          ) : null}
          {modes ? (
            shown.map((entry) => {
              const rawLeagues = Array.isArray(gameDataState.bundleData.league_tiers)
                ? gameDataState.bundleData.league_tiers.filter(isRecord)
                : [];
              const league = rawLeagues.find(
                (league) => league.battle_modifier === entry.meta.name,
              );
              const name =
                entry.meta.name === 'Hard Mode'
                  ? t('wikiEsportsMode')
                  : league
                    ? String(league.name).replace(/ League/gi, '')
                    : entry.name;
              const art = league
                ? ImageAssets.getLeagueImage(String(league.name))
                : ImageAssets.sword;
              return (
                <View key={entry.key} style={{ gap: 10 }}>
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
                    <MobileWebImage
                      imageUrl={art}
                      contentFit="contain"
                      style={{ width: 32, height: 34 }}
                    />
                    <CKText role="sectionTitle">{name}</CKText>
                  </View>
                  <WikiTable
                    identityLabel={t('wikiType')}
                    identityWidth={140}
                    columns={[
                      { key: 'side', label: t('wikiSide'), width: 105 },
                      {
                        key: 'damage',
                        label: t('wikiDamage'),
                        image: ImageAssets.sword,
                        width: 100,
                      },
                      {
                        key: 'hp',
                        label: t('gameItemHitpoints'),
                        image: ImageAssets.hitpoints,
                        width: 95,
                      },
                      { key: 'levels', label: t('wikiLevel'), width: 85 },
                    ]}
                    rows={(Array.isArray(entry.meta.modifiers)
                      ? entry.meta.modifiers.filter(isRecord)
                      : []
                    ).map((rule, i) => ({
                      key: `${entry.key}:${i}`,
                      label: [
                        rule.type === 'common_equipment'
                          ? t('wikiCommon')
                          : rule.type === 'epic_equipment'
                            ? t('wikiEpic')
                            : '',
                        t(
                          (
                            {
                              buildings: 'gameAssetsCategoryBuildings',
                              heroes: 'gameHeroes',
                              guardians: 'gameAssetsCategoryGuardians',
                              common_equipment: 'gameAssetsCategoryEquipment',
                              epic_equipment: 'gameAssetsCategoryEquipment',
                            } as const
                          )[String(rule.type) as 'heroes'] ?? 'generalOthers',
                        ),
                      ]
                        .filter(Boolean)
                        .join(' '),
                      image:
                        rule.type === 'heroes'
                          ? ImageAssets.getHeroImage('Barbarian King')
                          : rule.type === 'guardians'
                            ? ImageAssets.getGuardianImage('Smasher')
                            : rule.type === 'buildings'
                              ? ImageAssets.townHall(19)
                              : ImageAssets.getGearImage('Barbarian Puppet'),
                      values: {
                        side: t(
                          rule.attacker ? 'warAttacksDetailsAttacker' : 'warAttacksDetailsDefender',
                        ),
                        damage:
                          rule.damage_multiplier == null ? '—' : `${fmt(rule.damage_multiplier)}%`,
                        hp: rule.hp_multiplier == null ? '—' : `${fmt(rule.hp_multiplier)}%`,
                        levels: rule.minus_levels == null ? '—' : `−${fmt(rule.minus_levels)}`,
                      },
                    }))}
                  />
                </View>
              );
            })
          ) : (
            <WikiTable
              identityLabel={t('wikiMagicItems')}
              identityWidth={190}
              identityAccessory={(row) => {
                const entry = shown.find((item) => item.key === row.key);
                const message = entry
                  ? localizedInfoForItem(entry.meta)
                      .replaceAll('\\n', '\n')
                      .replaceAll('<num>', String(entry.meta.boost_multiplier ?? '—'))
                      .replaceAll(
                        '<time>',
                        typeof entry.meta.duration === 'number'
                          ? `${entry.meta.duration / 60} min`
                          : '—',
                      )
                  : '';
                return (
                  <InfoTooltip
                    label={row.label}
                    message={message}
                    triggerStyle={{ width: 24, height: 32 }}
                  />
                );
              }}
              columns={[
                { key: 'capacity', label: t('wikiCapacity'), width: 110 },
                { key: 'sell', label: t('wikiSellGems'), image: wikiResource('gems'), width: 125 },
                { key: 'duration', label: t('warAttacksDetailsDuration') },
                { key: 'uses', label: t('wikiBattles') },
                { key: 'boost', label: t('wikiBoost') },
              ]}
              rows={shown.map((entry) => ({
                key: entry.key,
                label: entry.name,
                image: entry.image,
                values: {
                  capacity: fmt(entry.meta.max_inventory),
                  uses: fmt(entry.meta.battle_uses),
                  boost:
                    typeof entry.meta.boost_multiplier === 'number'
                      ? `${entry.meta.boost_multiplier}×`
                      : '—',
                  sell: fmt(entry.meta.gem_value),
                  duration:
                    typeof entry.meta.duration === 'number' && entry.meta.duration > 0
                      ? `${entry.meta.duration / 60} min`
                      : '—',
                },
              }))}
            />
          )}
          {!shown.length ? <CKText muted>{t('searchNoResult')}</CKText> : null}
        </View>
      </WikiScrollView>
    </SafeAreaView>
  );
}
