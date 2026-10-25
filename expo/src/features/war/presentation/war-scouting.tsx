import { useEffect, useRef, useState } from 'react';
import { Pressable, View } from 'react-native';
import { useI18n } from '../../../i18n';
import {
  CKText,
  InfoTooltip,
  MobileWebImage,
  SkeletonContent,
  Surface,
  useCKTheme,
} from '../../../ui';
import type { WarInfo } from '../models';
import type { WarPresentationActions } from './contracts';
import { formatPercent, relativeWarTime } from './presentation-utils';
import { ckColors } from '../../../ui/tokens';
import { CompactWarScoreboard } from './war-components';

export function WarScouting({
  war,
  actions,
  enabled,
}: {
  war: WarInfo;
  actions: WarPresentationActions;
  enabled: boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [results, setResults] = useState<readonly (readonly WarInfo[] | null)[]>();
  const [retry, setRetry] = useState(0);
  const started = useRef(-1);
  const mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  useEffect(() => {
    if (!enabled || started.current === retry || !actions.loadScoutingWars) return;
    started.current = retry;
    const before = war.startTime ?? war.endTime;
    if (!before || !war.clan || !war.opponent) {
      return;
    }
    const type = war.isClanWarLeague ? 'cwl' : war.warType === 'friendly' ? 'friendly' : 'random';
    // At most two requests, each bounded to ten records. Switching Players
    // never changes scouting perspective or repeats these requests.
    void Promise.allSettled(
      [war.clan, war.opponent].map((clan) => actions.loadScoutingWars!(clan.tag, before, type)),
    ).then((values) => {
      if (mounted.current)
        setResults(values.map((value) => (value.status === 'fulfilled' ? value.value : null)));
    });
  }, [actions.loadScoutingWars, enabled, retry, war]);
  if (
    !enabled ||
    !actions.loadScoutingWars ||
    !(war.startTime ?? war.endTime) ||
    !war.clan ||
    !war.opponent
  )
    return null;
  const modifier = (value: string | null) =>
    ['normal', 'none', 'default'].includes((value ?? '').toLowerCase())
      ? ''
      : (value ?? '').toLowerCase();
  return (
    <SkeletonContent loading={!results} style={{ gap: 16 }}>
      <CKText role="sectionTitle">{t('warScoutTitle')}</CKText>
      <View style={{ flexDirection: 'row', gap: 10 }}>
        {[war.clan, war.opponent].map((clan, index) => {
          if (!clan) return null;
          const tags = new Set(clan.members.map((member) => member.tag));
          const matching = (results?.[index] ?? []).filter(
            (previous) =>
              modifier(previous.battleModifier) === modifier(war.battleModifier) &&
              previous.clan?.members.some(
                (member) => tags.has(member.tag) && !!member.attacks?.length,
              ),
          );
          const hits = matching.flatMap(
            (previous) =>
              previous.clan?.members
                .filter((member) => tags.has(member.tag))
                .flatMap((member) => member.attacks ?? []) ?? [],
          );
          const triples = hits.filter((hit) => hit.stars === 3).length;
          return (
            <Surface key={clan.tag} style={{ flex: 1, padding: 14, gap: 7, borderWidth: 0 }}>
              <View
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                }}
              >
                <MobileWebImage
                  imageUrl={clan.badgeUrls.smallest}
                  style={{ width: 28, height: 32 }}
                />
                <InfoTooltip
                  label={clan.name + ': ' + t('warScoutTitle')}
                  message={t('warFiltersLastXwars', { number: matching.length })}
                />
              </View>
              <CKText role="rowTitle">{clan.name}</CKText>
              <CKText role="titleLarge">
                {hits.length ? formatPercent((triples / hits.length) * 100, 0) : '—'}
              </CKText>
              <CKText role="metadata" muted>
                {t('playerBattlelogTripleRate')}
              </CKText>
              <CKText role="metadata" muted>
                {hits.length
                  ? `${triples}/${hits.length} · ${t('esportsTriples')}`
                  : t('generalNoDataAvailable')}
              </CKText>
            </Surface>
          );
        })}
      </View>
      {results?.some((value) => value === null) ? (
        <Pressable
          accessibilityRole="button"
          onPress={() => {
            setResults(undefined);
            setRetry((value) => value + 1);
          }}
          style={{ padding: 10 }}
        >
          <CKText style={{ color: theme.primary }}>{t('generalRetry')}</CKText>
        </Pressable>
      ) : null}
      <CKText role="sectionTitle">{t('warScoutOpponent')}</CKText>
      {results?.[1]?.length || !results ? (
        (results?.[1] ?? [war, war, war]).slice(0, 3).map((previous, index) => {
          // History may arrive with either clan first. Keep the scouted clan
          // on the left, and pair each score with that clan's identity.
          const oriented = previous.reorderForClan(war.opponent!.tag);
          const own = oriented.clan;
          const opponent = oriented.opponent;
          if (!own || !opponent) return null;
          const outcome = oriented.getWarResult(own.tag);
          const resultLabel =
            outcome === 'won'
              ? t('warVictory')
              : outcome === 'lost'
                ? t('warDefeat')
                : outcome === 'tie' || outcome === 'perfectWar'
                  ? t('warDraw')
                  : null;
          const ownColor =
            outcome === 'won'
              ? ckColors.donationGreen
              : outcome === 'lost'
                ? ckColors.lossRed
                : theme.onSurface;
          const opponentColor =
            outcome === 'won'
              ? ckColors.lossRed
              : outcome === 'lost'
                ? ckColors.donationGreen
                : theme.onSurface;
          return (
            <Surface
              key={`${previous.endTime?.toISOString()}:${index}`}
              testID={'war-scout-history-' + previous.tag}
              style={{ padding: 14, borderWidth: 0, gap: 8 }}
            >
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', gap: 8 }}>
                <CKText role="metadata" muted>
                  {previous.teamSize}v{previous.teamSize} ·{' '}
                  {previous.endTime ? relativeWarTime(previous.endTime, new Date(), t) : '—'}
                </CKText>
                {resultLabel ? (
                  <CKText role="metadata" style={{ color: ownColor }}>
                    {resultLabel}
                  </CKText>
                ) : null}
              </View>
              <CompactWarScoreboard
                war={oriented}
                leftColor={ownColor}
                rightColor={opponentColor}
              />
            </Surface>
          );
        })
      ) : (
        <CKText role="metadata" muted>
          {t('generalNoDataAvailable')}
        </CKText>
      )}
    </SkeletonContent>
  );
}
