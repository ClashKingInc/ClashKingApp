import { useEffect, useState } from 'react';
import { View } from 'react-native';
import { SvgXml } from 'react-native-svg';
import { ImageAssets } from '../../../core/assets/image-assets';
import {
  loadLegendPosterArtwork,
  optionalLegendPosterImage,
} from '../../../core/graphics/legend-poster-artwork';
import { legendPosterSvg } from '../../../core/graphics/legend-poster-layout';
import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText, HorizontalImageShareModal, horizontalImageFilename } from '../../../ui';
import { currentLegendDay, type Player, type PlayerLegendLeagueData } from '../../player/models';
import { PlayerBattlelogArmyCatalog } from '../../player/models/player-battlelog';
import { playerProfileClanIdentity } from '../../player/presentation/player-clan-identity';

export interface LegendsShareSummary {
  readonly currentRank: number | null;
  readonly historicalRank: number | null;
  readonly favoriteArmy: string | null;
  readonly favoriteArmyUses: number;
  readonly battleChanges: readonly { readonly key: string; readonly change: number }[];
  readonly dailyContributions: readonly {
    readonly key: string;
    readonly change: number;
    readonly attackTrophies: number;
  }[];
  readonly graph: readonly { readonly label: string; readonly trophies: number }[];
}

export function legendsShareSummary(data: PlayerLegendLeagueData): LegendsShareSummary {
  const armyUses = new Map<string, number>();
  for (const shareCode of data.seasonArmyShareCodes) {
    armyUses.set(shareCode, (armyUses.get(shareCode) ?? 0) + 1);
  }
  const favorite = [...armyUses.entries()].sort(
    ([left, leftUses], [right, rightUses]) => rightUses - leftUses || left.localeCompare(right),
  )[0];
  const dailyContributions = [...data.recentDays]
    .sort((left, right) => left.day.localeCompare(right.day))
    .map((day) => ({
      key: day.day,
      change: day.trophyChange,
      attackTrophies: day.attackTrophies,
    }));
  const dailyChanges = dailyContributions.map(({ key, change }) => ({ key, change }));
  return {
    currentRank: data.currentRank?.globalRank ?? null,
    historicalRank: data.historicalRank?.globalRank ?? null,
    favoriteArmy: favorite?.[0] ?? null,
    favoriteArmyUses: favorite?.[1] ?? 0,
    battleChanges: dailyChanges,
    dailyContributions,
    graph: data.recentDays.flatMap((day) =>
      day.closingTrophies == null
        ? []
        : [{ label: day.day.slice(5), trophies: day.closingTrophies }],
    ),
  };
}

export function legendSeasonLabel(
  start: string | null,
  end: string | null,
  fallback = 'Current season',
  locale = 'en',
): string {
  if (!start || !end) return fallback;
  const formatter = new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'short',
    day: 'numeric',
    timeZone: 'UTC',
  });
  const startDate = new Date(start);
  const endDate = new Date(end);
  if (!Number.isFinite(startDate.getTime()) || !Number.isFinite(endDate.getTime())) return fallback;
  return `${formatter.format(startDate)} – ${formatter.format(endDate)}`;
}

export function LegendsShareModal({
  data,
  player,
  visible,
  onClose,
}: {
  readonly data: PlayerLegendLeagueData;
  readonly player: Player;
  readonly visible: boolean;
  readonly onClose: () => void;
}) {
  const { t } = useI18n();
  const [poster, setPoster] = useState<{
    data: PlayerLegendLeagueData;
    xml: string | null;
    failed?: boolean;
  } | null>(null);
  useEffect(() => {
    if (!visible) return;
    let cancelled = false;
    const season = data.posterSeason;
    if (!season) return;
    async function prepare() {
      const clan = playerProfileClanIdentity(player);
      const location = data.currentRank?.location ?? undefined;
      const prefixes = { troop: 'u', spell: 's', hero: 'h', equipment: 'e', pet: 'p', siege: 'u' };
      const [artwork, badge, flag, favorites] = await Promise.all([
        loadLegendPosterArtwork(data.townHallLevel),
        optionalLegendPosterImage(clan.tag ? clan.badgeUrl : undefined),
        optionalLegendPosterImage(
          location?.countryCode ? ImageAssets.flag(location.countryCode) : undefined,
        ),
        Promise.all(
          (season!.favorites ?? []).map(
            async (item) =>
              [
                item.id,
                await optionalLegendPosterImage(
                  PlayerBattlelogArmyCatalog.resolve(`${prefixes[item.category]}_${item.id}`)
                    .imageUrl,
                ),
              ] as const,
          ),
        ),
      ]);
      const xml = legendPosterSvg(
        {
          player: {
            name: data.playerName,
            tag: data.playerTag,
            townHallLevel: data.townHallLevel,
            trophies: data.currentRank?.trophies ?? data.trophies,
            globalRank: data.currentRank?.globalRank,
            clan: clan.name ? { name: clan.name } : undefined,
            location,
          },
          season: season!,
          days: data.recentDays.map((day) => ({
            day: day.day,
            attackTrophies: day.attackTrophies,
            defenseTrophies: day.defenseTrophies,
            trophies: day.trophyChange,
            closingTrophies: day.closingTrophies,
            attacks: day.attacks,
            defenses: day.defenses,
            recordedDefenses: day.recordedDefenses,
          })),
          selectedDay: data.selectedDay,
          today: currentLegendDay(),
        },
        { ...artwork, badge, flag, favoriteImages: Object.fromEntries(favorites) },
      );
      if (!cancelled) setPoster({ data, xml });
    }
    void prepare().catch(() => {
      if (!cancelled) setPoster({ data, xml: null, failed: true });
    });
    return () => {
      cancelled = true;
    };
  }, [visible, data, player]);
  const xml = poster?.data === data ? poster.xml : null;
  const failed = poster?.data === data && poster.failed;
  return (
    <HorizontalImageShareModal
      canvasSize={{ width: 1600, height: 1100 }}
      exportSize={{ width: 1600, height: 1100 }}
      ready={xml !== null}
      fileName={legendsImageFileName(data.playerName)}
      message={`${data.playerName} in Legend League on ClashKing`}
      onClose={onClose}
      title={t('generalExport')}
      visible={visible}
    >
      {xml ? (
        <SvgXml testID="legends-bot-poster" width={1600} height={1100} xml={xml} />
      ) : (
        <View
          style={{
            flex: 1,
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: '#000',
          }}
        >
          <CKText style={{ color: '#fff', fontSize: 32 }}>
            {t(
              failed
                ? 'generalError'
                : !data.posterSeason
                  ? 'generalNoDataAvailable'
                  : 'generalLoading',
            )}
          </CKText>
        </View>
      )}
    </HorizontalImageShareModal>
  );
}
export function legendsImageFileName(playerName: string, now = new Date()) {
  return horizontalImageFilename('legends', playerName, '', now);
}
