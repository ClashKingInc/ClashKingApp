import { type ReactNode } from 'react';
import { Image } from 'expo-image';
import { PixelRatio, Platform, StyleSheet, View } from 'react-native';

import { CKText, MobileWebImage, ckRadius, colorWithAlpha, useCKTheme } from '../../../ui';
import { manifestImage } from '../../../core/assets/asset-manifest';
import { localImageCache } from '../../../core/assets/local-asset-cache';
import { sizedAssetUrl } from '../../../ui/image-delivery';
import { useI18n } from '../../../i18n';
import { PlayerBattlelogArmyCatalog } from '../../player/models/player-battlelog';
import { legendArmyGroups, legendHeroLoadouts, type LegendArmyItem } from './legend-army';

const warmedArtwork = new Set<string>();

/** Only the first two visible setups are warmed; expansion can show many new images at once. */
export async function prefetchLegendArmyArtwork(shareCodes: readonly string[]): Promise<void> {
  const artwork = shareCodes.slice(0, 2).flatMap((shareCode) => {
    const groups = new Map(legendArmyGroups(shareCode));
    return ['Heroes', 'Troops', 'Spells', 'Clan Castle', 'Siege'].flatMap((label) =>
      (groups.get(label) ?? []).map(({ code }) => ({
      url: PlayerBattlelogArmyCatalog.resolve(code).imageUrl,
      size: code.startsWith('h_') ? 76 : code.startsWith('p_') || code.startsWith('e_') ? 30 : 40,
      })),
    );
  }).filter(({ url }) => Boolean(url)).slice(0, 24);
  const pending = artwork.filter(({ url, size }) => !warmedArtwork.has(`${url}:${size}`));
  for (const { url, size } of pending) warmedArtwork.add(`${url}:${size}`);
  while (warmedArtwork.size > 128) {
    const oldest = warmedArtwork.values().next().value;
    if (oldest) warmedArtwork.delete(oldest);
  }
  // Four downloads at a time leave bandwidth for the visible list and charts.
  for (let offset = 0; offset < pending.length; offset += 4) {
    const batch = pending.slice(offset, offset + 4);
    const results = await Promise.allSettled(batch.map(async ({ url, size }) => {
      const candidate = sizedAssetUrl(url, size, size, PixelRatio.get());
      const metadata = manifestImage(url);
      if (Platform.OS !== 'web' && metadata && url.startsWith('https://assets.clashk.ing/')) {
        await localImageCache.resolve(candidate, decodeURIComponent(new URL(url).pathname.slice(1)), metadata.sha, () => {});
      } else {
        await Image.prefetch(candidate);
      }
    }));
    results.forEach((result, index) => {
      if (result.status === 'rejected') {
        const item = batch[index];
        if (item) warmedArtwork.delete(`${item.url}:${item.size}`);
      }
    });
  }
}

export function LegendArmy({
  shareCode,
  siegeContent,
}: {
  readonly shareCode: string;
  readonly siegeContent?: ReactNode;
}) {
  const { t } = useI18n();
  const groups = new Map(legendArmyGroups(shareCode));
  const heroes = legendHeroLoadouts(shareCode);
  const clanCastle = groups.get('Clan Castle') ?? [];
  const siege = groups.get('Siege') ?? [];

  return (
    <View style={styles.army} testID="legend-army">
      {heroes.length ? (
        <View style={styles.group}>
          <CKText muted role="metadata">
            {t('gameHeroes')}
          </CKText>
          <View style={styles.heroRow}>
            {heroes.map((loadout) => (
              <HeroLoadout key={loadout.hero.code} loadout={loadout} />
            ))}
          </View>
        </View>
      ) : null}
      {(['Troops', 'Spells'] as const).map((label) => {
        const items = groups.get(label) ?? [];
        return items.length ? (
          <ArmyGroup
            key={label}
            label={t(label === 'Troops' ? 'gameTroops' : 'gameSpells')}
            items={items}
          />
        ) : null;
      })}
      {clanCastle.length || (siegeContent !== undefined ? siegeContent : siege.length) ? (
        <View style={styles.group}>
          <CKText muted role="metadata">
            {t('legendsClanCastle')}
          </CKText>
          {clanCastle.length ? <ArmyItems items={clanCastle} /> : null}
          {siegeContent !== undefined ? (
            siegeContent
          ) : siege.length ? (
            <View style={styles.siegeRow}>
              <CKText muted role="metadata">
                {t('gameSiegeMachines')}
              </CKText>
              <ArmyItems items={siege} />
            </View>
          ) : null}
        </View>
      ) : null}
    </View>
  );
}

function HeroLoadout({
  loadout,
}: {
  readonly loadout: ReturnType<typeof legendHeroLoadouts>[number];
}) {
  const theme = useCKTheme();
  const hero = PlayerBattlelogArmyCatalog.resolve(loadout.hero.code);
  const pet = loadout.pet ? PlayerBattlelogArmyCatalog.resolve(loadout.pet.code) : null;
  return (
    <View
      accessibilityLabel={[
        hero.name,
        pet?.name,
        ...loadout.equipment.map((value) => PlayerBattlelogArmyCatalog.resolve(value.code).name),
      ]
        .filter(Boolean)
        .join(', ')}
      style={styles.heroLoadout}
    >
      <View
        style={[
          styles.heroPortrait,
          { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.58) },
        ]}
      >
        <MobileWebImage imageUrl={hero.imageUrl} style={styles.heroImage} />
        {pet ? (
          <View style={[styles.petBadge, { backgroundColor: theme.surface }]}>
            <MobileWebImage imageUrl={pet.imageUrl} style={styles.petImage} />
          </View>
        ) : null}
      </View>
      <View style={styles.equipmentRow}>
        {loadout.equipment.map(({ code }) => {
          const item = PlayerBattlelogArmyCatalog.resolve(code);
          return (
            <MobileWebImage key={code} imageUrl={item.imageUrl} style={styles.equipmentImage} />
          );
        })}
      </View>
    </View>
  );
}

function ArmyGroup({
  label,
  items,
}: {
  readonly label: string;
  readonly items: readonly LegendArmyItem[];
}) {
  return (
    <View style={styles.group}>
      <CKText muted role="metadata">
        {label}
      </CKText>
      <ArmyItems items={items} />
    </View>
  );
}

function ArmyItems({ items }: { readonly items: readonly LegendArmyItem[] }) {
  return (
    <View style={styles.itemRow}>
      {items.map(({ code, count }) => {
        const item = PlayerBattlelogArmyCatalog.resolve(code);
        return (
          <View key={code} accessibilityLabel={`${item.name}, ${count}`} style={styles.item}>
            <MobileWebImage imageUrl={item.imageUrl} style={styles.itemImage} />
            <CKText role="metadata">×{count}</CKText>
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  army: { gap: 14, paddingTop: 10 },
  group: { gap: 7 },
  itemRow: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', gap: 8 },
  item: { flexDirection: 'row', alignItems: 'center', gap: 3 },
  itemImage: { width: 40, height: 40 },
  heroRow: { width: '100%', flexDirection: 'row', gap: 8 },
  heroLoadout: { minWidth: 0, maxWidth: 76, flex: 1, alignItems: 'center', gap: 5 },
  heroPortrait: {
    width: '100%',
    maxWidth: 76,
    aspectRatio: 1,
    borderRadius: ckRadius.control,
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroImage: { width: '92%', aspectRatio: 1 },
  petBadge: {
    position: 'absolute',
    right: -4,
    bottom: -4,
    width: '41%',
    maxWidth: 31,
    aspectRatio: 1,
    borderRadius: ckRadius.pill,
    alignItems: 'center',
    justifyContent: 'center',
  },
  petImage: { width: '87%', aspectRatio: 1 },
  equipmentRow: {
    width: '100%',
    minHeight: 30,
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 5,
  },
  equipmentImage: { width: '40%', maxWidth: 30, aspectRatio: 1, borderRadius: 7 },
  siegeRow: { gap: 5 },
});
