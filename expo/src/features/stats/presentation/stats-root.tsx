import { useCallback, useEffect, useMemo, useState, useSyncExternalStore } from 'react';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { StatsProvider, StatsRepository } from '../data';
import { StatsScreen, sectionImage, sectionLabel, sectionBackdrop } from './stats-screen';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';
import {
  StatsAudience,
  StatsDateFilter,
  StatsSection,
  statsSections,
  type StatsSectionValue,
} from '../models';
import { battleStatsLinkSections, worldStatsLinkSections } from './stats-link-sections';
import { ckColors } from '../../../ui';
import { DestinationHub } from '../../../ui/destination-hub';
import { DestinationStack } from '../../../ui/destination-stack';
import { useI18n } from '../../../i18n';

export interface StatsRootProps {
  readonly onBack: () => void;
  readonly initialSection?: StatsSectionValue;
}

export function StatsRoot({ onBack, initialSection }: StatsRootProps) {
  'use no memo';
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const { audience, section: linkedSection, start, end } = useLinkParameters();
  const section = initialSection ?? linkedSection;
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
  const [selectionRequest, setSelectionRequest] = useState(0);
  const focused = selection.provider === provider ? selection.focused : hasLinkedSection;
  const subscribe = useCallback((listener: () => void) => provider.subscribe(listener), [provider]);
  const revision = useSyncExternalStore(subscribe, provider.getSnapshot, provider.getSnapshot);
  const closeFocused = useCallback(() => {
    if (initialSection) onBack();
    else setSelection({ provider, focused: false });
  }, [provider, initialSection, onBack]);
  useEffect(() => {
    if (focused) provider.ensureLoaded();
  }, [focused, provider]);
  useEffect(() => {
    return () => {
      provider.dispose();
    };
  }, [provider]);
  const grid = (
    <DestinationHub
      title={t('sideStatsTitle')}
      onBack={onBack}
      groups={[
        {
          key: 'statistics',
          choices: statsSections,
        },
      ].map(({ key, choices }) => ({
        key,
        fillLastRow: true,
        items: choices.map((choice) => ({
          key: choice,
          label: sectionLabel(choice, t),
          imageUrl: sectionImage(choice),
          backgroundUrl: sectionBackdrop(choice),
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
            setSelectionRequest((request) => request + 1);
            provider.selectSection(choice);
            setSelection({ provider, focused: true });
          },
        })),
      }))}
    />
  );
  if (initialSection)
    return (
      <StatsScreen
        provider={provider}
        revision={revision}
        onBack={onBack}
        api={runtime.contractApi}
      />
    );
  return (
    <DestinationStack
      selectionKey={selectionRequest}
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
