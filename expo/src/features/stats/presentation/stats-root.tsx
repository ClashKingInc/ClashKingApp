import { useCallback, useEffect, useMemo, useState, useSyncExternalStore } from 'react';
import { ScrollView, View, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ArrowLeft } from 'lucide-react-native';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { StatsProvider, StatsRepository } from '../data';
import { StatsScreen, sectionImage, sectionLabel } from './stats-screen';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';
import { StatsAudience, StatsDateFilter, StatsSection, statsSections } from '../models';
import { battleStatsLinkSections, worldStatsLinkSections } from './stats-link-sections';
import { CKText, ckColors, useCKTheme } from '../../../ui';
import { HeaderIconButton } from '../../../ui/header';
import { DestinationGrid } from '../../../ui/destination-grid';
import { DestinationStack } from '../../../ui/destination-stack';
import { materialBackLabel, useI18n } from '../../../i18n';

export interface StatsRootProps {
  readonly onBack: () => void;
}

export function StatsRoot({ onBack }: StatsRootProps) {
  'use no memo';
  const runtime = useAppRuntime();
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const { width } = useWindowDimensions();
  const { audience, section, start, end } = useLinkParameters();
  const hasLinkedSection = statsSections.includes(section as (typeof statsSections)[number]);
  const provider = useMemo(() => {
    const value = new StatsProvider(new StatsRepository(runtime.contractApi));
    value.audience = linkChoice(audience, ['battle', 'world'], 'battle');
    const sections = value.audience === 'battle' ? battleStatsLinkSections : worldStatsLinkSections;
    value.section = linkChoice(section, statsSections, sections[0]!);
    value.audience =
      value.section === StatsSection.players || value.section === StatsSection.clans
        ? StatsAudience.world
        : StatsAudience.battle;
    if (start && end) {
      const dates = new StatsDateFilter(new Date(`${start}T00:00:00`), new Date(`${end}T00:00:00`));
      if (
        Number.isFinite(dates.inclusiveDays) &&
        dates.inclusiveDays >= 1 &&
        dates.inclusiveDays <= (value.section === StatsSection.war ? 20000 : 90)
      ) {
        if (value.section === StatsSection.war) value.warDates = dates;
        else value.dates = dates;
      }
    }
    return value;
  }, [runtime.contractApi, audience, section, start, end]);
  const [selection, setSelection] = useState({ provider, focused: hasLinkedSection });
  const focused = selection.provider === provider ? selection.focused : hasLinkedSection;
  const subscribe = useCallback((listener: () => void) => provider.subscribe(listener), [provider]);
  const revision = useSyncExternalStore(subscribe, provider.getSnapshot, provider.getSnapshot);
  const closeFocused = useCallback(() => {
    setSelection({ provider, focused: false });
  }, [provider]);
  useEffect(() => {
    if (focused) provider.ensureLoaded();
  }, [focused, provider]);
  useEffect(() => {
    return () => {
      provider.dispose();
    };
  }, [provider]);
  const grid = (
    <SafeAreaView style={{ flex: 1, backgroundColor: theme.background }}>
      <ScrollView
        contentContainerStyle={{
          paddingHorizontal: Math.max(16, (width - 1120) / 2),
          paddingBottom: 24,
          gap: 12,
        }}
      >
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, minHeight: 56 }}>
          <HeaderIconButton
            glass={false}
            label={materialBackLabel(locale)}
            onPress={onBack}
            icon={<ArrowLeft color={theme.onSurface} />}
          />
          <CKText role="screenTitle">{t('sideStatsTitle')}</CKText>
        </View>
        <View testID="destination-grid-stats">
          <DestinationGrid
            initialWidth={width - 2 * Math.max(16, (width - 1120) / 2)}
            groups={[
              {
                key: 'battles',
                title: t('statsBattle'),
                choices: [StatsSection.war, StatsSection.ranked, StatsSection.cwl],
              },
              {
                key: 'army',
                title: t('statsBattlelogsGroup'),
                choices: [StatsSection.armies, StatsSection.items],
              },
              {
                key: 'world',
                title: t('statsGlobalStatsGroup'),
                choices: [StatsSection.players, StatsSection.clans],
              },
            ].map(({ key, title, choices }) => ({
              key,
              title,
              fillLastRow: true,
              items: choices.map((choice) => ({
                key: choice,
                label: sectionLabel(choice, t),
                imageUrl: sectionImage(choice),
                accentColor: {
                  war: ckColors.warGold,
                  armies: ckColors.legendBlue,
                  items: ckColors.upgradePets,
                  ranked: ckColors.capitalOrange,
                  cwl: ckColors.warGold,
                  players: ckColors.builderBlue,
                  clans: ckColors.donationGreen,
                }[choice],
                onPress: () => {
                  provider.selectSection(choice);
                  setSelection({ provider, focused: true });
                },
              })),
            }))}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
  return (
    <DestinationStack
      focused={focused}
      onCloseDetail={closeFocused}
      grid={grid}
      detail={
        <StatsScreen
          provider={provider}
          revision={revision}
          onBack={closeFocused}
          api={runtime.contractApi}
        />
      }
    />
  );
}
