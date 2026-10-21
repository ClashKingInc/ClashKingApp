import { View } from 'react-native';
import Svg, { Line, Polyline, Text as SvgText } from 'react-native-svg';
import { CKText, Surface, useCKTheme } from '../../../ui';
import { ckColors } from '../../../ui/tokens';
import { useI18n } from '../../../i18n';
import type { buildWarReplay } from '../models/war-replay';

/** Attack order is the only known axis. Never invent timestamps or rewind live data. */
export function WarHistoryPanel({
  history,
  teamSize,
}: {
  history: ReturnType<typeof buildWarReplay>;
  teamSize: number;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const total = history.events.length;
  const y = (stars: number) => 136 - (stars / Math.max(3, teamSize * 3)) * 120;
  const toLine = (side: 'clanStars' | 'opponentStars') =>
    history.points
      .map((point, index) => `${32 + (index / Math.max(1, total)) * 276},${y(point[side])}`)
      .join(' ');
  return (
    <Surface testID="war-history" style={{ padding: 16, borderWidth: 0, gap: 10 }}>
      <CKText role="rowTitle">{t('warReplayTitle')}</CKText>
      {!history.complete ? (
        <CKText role="metadata" muted>
          {total ? t('homeActivityRecorded') : t('generalNoDataAvailable')}
        </CKText>
      ) : (
        <>
          <View
            testID="war-history-graph"
            accessible
            accessibilityLabel={`${t('warReplayTitle')}: ${history.clanName} ${history.points.at(-1)?.clanStars}, ${history.opponentName} ${history.points.at(-1)?.opponentStars}`}
          >
            <Svg width="100%" height={174} viewBox="0 0 320 174">
              {[0, teamSize * 1.5, teamSize * 3].map((value) => (
                <Line
                  key={value}
                  x1={32}
                  x2={308}
                  y1={y(value)}
                  y2={y(value)}
                  stroke={theme.outlineVariant}
                  strokeOpacity={0.3}
                />
              ))}
              <SvgText x={25} y={20} fill={theme.onSurfaceVariant} fontSize={11} textAnchor="end">
                {teamSize * 3}
              </SvgText>
              <SvgText x={25} y={140} fill={theme.onSurfaceVariant} fontSize={11} textAnchor="end">
                0
              </SvgText>
              <SvgText x={32} y={159} fill={theme.onSurfaceVariant} fontSize={11}>
                0
              </SvgText>
              <SvgText x={308} y={159} fill={theme.onSurfaceVariant} fontSize={11} textAnchor="end">
                {total}
              </SvgText>
              <Polyline
                points={toLine('clanStars')}
                fill="none"
            stroke={ckColors.donationGreen}
                strokeWidth={3}
                strokeLinejoin="round"
              />
              <Polyline
                points={toLine('opponentStars')}
                fill="none"
            stroke={ckColors.primaryRed}
                strokeWidth={3}
                strokeLinejoin="round"
              />
            </Svg>
          </View>
          <CKText role="metadata" muted style={{ textAlign: 'center' }}>
            {t('warAttacksDetailsAttackOrder')}
          </CKText>
          <View
            style={{ flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 14 }}
          >
          <CKText role="metadata" style={{ color: ckColors.donationGreen }}>
              {history.clanName}
            </CKText>
          <CKText role="metadata" style={{ color: ckColors.primaryRed }}>
              {history.opponentName}
            </CKText>
          </View>
        </>
      )}
    </Surface>
  );
}
