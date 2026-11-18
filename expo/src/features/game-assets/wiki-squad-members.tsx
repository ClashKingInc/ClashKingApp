import { View } from 'react-native';
import { CKText, MobileWebImage, Surface } from '../../ui';
import { ImageAssets } from '../../core/assets/image-assets';
import { gameDataState, isRecord, type JsonRecord } from '../../core/game-data/game-data-state';
import { localizedNameForItem } from '../../core/game-data/game-data-localization';
import { useI18n } from '../../i18n';

export function WikiSquadMembers({ squad }: { squad: JsonRecord }) {
  const { t } = useI18n();
  const troops = Array.isArray(gameDataState.bundleData.troops)
    ? gameDataState.bundleData.troops.filter(isRecord)
    : [];
  const members = Array.isArray(squad.members) ? squad.members.filter(isRecord) : [];
  return (
    <View style={{ gap: 10 }}>
      <CKText role="sectionTitle">{t('wikiSquadMembers')}</CKText>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 10 }}>
        {members.map((member) => {
          const troop = troops.find((troop) => troop._id === member.troop_id);
          if (!troop) return null;
          return (
            <Surface
              key={String(member.troop_id)}
              radius={16}
              style={{ flexDirection: 'row', alignItems: 'center', padding: 12, gap: 8 }}
            >
              <MobileWebImage
                imageUrl={ImageAssets.getTroopImage(String(troop.name))}
                contentFit="contain"
                style={{ width: 44, height: 44 }}
              />
              <CKText>
                {String(member.count)} × {localizedNameForItem(troop)}
              </CKText>
            </Surface>
          );
        })}
      </View>
    </View>
  );
}
