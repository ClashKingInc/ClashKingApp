import { useEffect, useState } from 'react';
import { View } from 'react-native';
import { SvgXml } from 'react-native-svg';
import { ImageAssets } from '../../../core/assets/image-assets';
import {
  loadLegendPosterArtwork,
  optionalLegendPosterImage,
} from '../../../core/graphics/legend-poster-artwork';
import { rankedPosterSvg, type RankedPosterHit } from '../../../core/graphics/ranked-poster-layout';
import { CKText, HorizontalImageShareModal, horizontalImageFilename } from '../../../ui';
import { useI18n } from '../../../i18n';
import type { Player, RankedLeagueBattle } from '../../player/models';
import { playerProfileClanIdentity } from '../../player/presentation/player-clan-identity';
import type { RankedPeriod } from '../data';

export function RankedShareModal({
  player,
  period,
  visible,
  onClose,
}: {
  player: Player;
  period: RankedPeriod;
  visible: boolean;
  onClose: () => void;
}) {
  const { t } = useI18n();
  const [poster, setPoster] = useState<{
    period: RankedPeriod;
    xml: string | null;
    failed?: boolean;
  }>();
  useEffect(() => {
    if (!visible) return;
    let active = true;
    void (async () => {
      const clan = playerProfileClanIdentity(player);
      const [art, badge, clanImage] = await Promise.all([
        loadLegendPosterArtwork(player.townHallLevel),
        optionalLegendPosterImage(period.tier?.iconUrl ?? ImageAssets.defaultImage),
        optionalLegendPosterImage(clan.tag ? clan.badgeUrl : undefined),
      ]);
      // Automatic/unobserved hits have no star result or timestamp. Do not
      // turn them into fabricated zero-star attacks in the bot composition.
      const hits = (rows: readonly RankedLeagueBattle[]): RankedPosterHit[] =>
        rows.flatMap((hit) =>
          hit.stars !== null && hit.destructionPercentage !== null && hit.creationTime
            ? [
                {
                  stars: hit.stars,
                  destructionPercentage: hit.destructionPercentage,
                  trophies: hit.trophies,
                  creationTime: hit.creationTime.toISOString(),
                },
              ]
            : [],
        );
      const members =
        period.group?.members.map((member, index) => ({
          name: member.playerName,
          tag: member.playerTag,
          trophies: member.leagueTrophies,
          attacks: member.attackWinCount + member.attackLoseCount,
          wins: member.attackWinCount,
          losses: member.attackLoseCount,
          placement: index + 1,
        })) ?? [];
      const xml = rankedPosterSvg(
        {
          player: {
            name: player.name,
            tag: player.tag,
            townHallLevel: player.townHallLevel,
            ...(clan.name ? { clan: { name: clan.name } } : {}),
          },
          league: period.tier?.name ?? t('rankedLeagueTitle'),
          season: String(period.seasonId),
          member: {
            name: player.name,
            tag: player.tag,
            trophies: period.trophies,
            attacks: period.attackCount,
            wins: period.attackWins,
            losses: period.attackLosses,
            placement: period.placement,
          },
          members,
          attacks: hits(period.attacks),
          defenses: hits(period.defenses),
        },
        { ...art, hall: art.hallImage, badge, clan: clanImage },
      );
      if (active) setPoster({ period, xml });
    })().catch(() => {
      if (active) setPoster({ period, xml: null, failed: true });
    });
    return () => {
      active = false;
    };
  }, [period, player, visible, t]);
  const current = poster?.period === period ? poster : undefined;
  return (
    <HorizontalImageShareModal
      visible={visible}
      onClose={onClose}
      title={t('generalExport')}
      fileName={horizontalImageFilename('ranked', player.name, String(period.seasonId))}
      message={player.name}
      canvasSize={{ width: 1600, height: 1100 }}
      exportSize={{ width: 1600, height: 1100 }}
      ready={!!current?.xml}
    >
      {current?.xml ? (
        <SvgXml testID="ranked-bot-poster" xml={current.xml} width={1600} height={1100} />
      ) : (
        <View
          style={{
            flex: 1,
            backgroundColor: '#000',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <CKText style={{ color: '#fff', fontSize: 32 }}>
            {t(current?.failed ? 'generalError' : 'generalLoading')}
          </CKText>
        </View>
      )}
    </HorizontalImageShareModal>
  );
}
