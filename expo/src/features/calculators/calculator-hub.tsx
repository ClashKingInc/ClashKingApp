import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import { useEffect, useState, type ReactNode } from 'react';
import {
  BackHandler,
  Image,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
  type LayoutChangeEvent,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { bundledImageUrl } from '../../core/assets/bundled-image-source';
import { HeroHeaderScrim } from '../../ui/hero-header-scrim';
import { useI18n } from '../../i18n';
import {
  CKText,
  DestinationStack,
  MobileWebImage,
  PressableSurface,
  ResponsiveGrid,
  useCKTheme,
} from '../../ui';
import { CalculatorHeader } from './calculator-header';
import { CalculatorFireballPlayground } from './calculator-fireball-playground';
import { useLinkParameters } from '../../core/deep-links/link-parameters';
import type { Player } from '../player/models';
import type { DamageCalculatorSession, DamageAccountPreset } from '../damage-calculator';
import { DamageWorkbench } from './damage-workbench';
import { EquipmentCompare } from './equipment-compare';

export function CalculatorHub({
  session,
  accountPresets,
  players,
  onBack,
}: {
  session: DamageCalculatorSession;
  accountPresets: readonly DamageAccountPreset[];
  players: readonly Player[];
  onBack: () => void;
}) {
  const { t } = useI18n(),
    theme = useCKTheme(),
    link = useLinkParameters();
  // No route, flag, or saved tab can open Farming while it is unfinished.
  const [page, setPage] = useState<'home' | 'damage' | 'equipment'>(() =>
    link.mode === 'damage' ? 'damage' : link.mode === 'equipment' ? 'equipment' : 'home',
  );
  const insets = useSafeAreaInsets();
  const { width, height } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const effectiveWidth =
    layout.isDuo && !layout.isExpanded
      ? Math.min(layout.width, layout.contentMaxWidth)
      : layout.isDuo || layout.isTablet
        ? layout.width
        : width;
  const [contentHeight, setContentHeight] = useState(0);
  const gridWidth = layout.isExpanded
    ? Math.min(layout.usableWidth, layout.contentMaxWidth) - 24
    : Math.min(effectiveWidth - 24, 1096);
  const gridColumns = layout.isExpanded
    ? layout.columns(320, layout.isTablet ? 3 : 2)
    : !layout.isDuo && gridWidth >= 732
      ? 2
      : 1;
  const gridRows = Math.ceil(3 / gridColumns);
  // Size from the actual page, not the image aspect ratio, so all destinations
  // remain on screen even when native navigation reduces the available height.
  const availableHeight =
    contentHeight || (layout.isDuo || layout.isTablet ? layout.height : height) - insets.bottom;
  const naturalCardHeight = Math.max(
    0,
    (availableHeight - insets.top - 4 - 76 - 16 - 6 - (gridRows - 1) * 12) / gridRows,
  );
  const cardHeight = layout.isExpanded
    ? Math.min(360, Math.max(220, naturalCardHeight))
    : naturalCardHeight;
  const compact = effectiveWidth < 360;
  const dark = theme.background === '#030304';
  const pageBackground = theme.background;
  useEffect(() => {
    if (page === 'home') return;
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      setPage('home');
      return true;
    });
    return () => sub.remove();
  }, [page]);
  const detail =
    page === 'damage' ? (
      <DamageWorkbench session={session} accounts={accountPresets} onBack={() => setPage('home')} />
    ) : page === 'equipment' ? (
      <EquipmentCompare players={players} onBack={() => setPage('home')} />
    ) : null;
  const cards = [
    {
      id: 'damage',
      title: t('calculatorsModeDamage'),
      body: t('calcDamageIntro'),
      image: require('../../../assets/clashking/calculators/damage.webp'),
    },
    {
      id: 'equipment',
      title: t('calcEquipmentTitle'),
      body: t('calcEquipmentIntro'),
      image: require('../../../assets/clashking/calculators/equipment-bare-hands.png'),
    },
    {
      id: 'farming',
      title: t('calculatorsModeFarmGoal'),
      body: t('calcFarmIntro'),
      image: require('../../../assets/clashking/calculators/farming.webp'),
    },
  ] as const;
  const backdrop = (
    <View pointerEvents="none" style={styles.backdrop}>
      {/* The source is two pixels wide, so explicit dimensions fill the pane. */}
      <Image
        source={
          dark
            ? require('../../../assets/clashking/backgrounds/hub-blue-dark.png')
            : require('../../../assets/clashking/backgrounds/hub-blue-light.png')
        }
        resizeMode="stretch"
        style={styles.backdropImage}
      />
    </View>
  );
  const grid = (
    <CalculatorFireballPlayground visible={page === 'home'}>
      <DuoBackgroundPane enabled={layout.isDuo} backgroundColor={pageBackground}>
        {layout.isDuo ? backdrop : null}
        <SafeAreaView
          edges={['bottom', 'left', 'right']}
          style={{ flex: 1, backgroundColor: layout.isDuo ? 'transparent' : pageBackground }}
          testID="calculator-hub"
        >
          {!layout.isDuo ? backdrop : null}
          <HubContent
            onLayout={(event) => setContentHeight(event.nativeEvent.layout.height)}
            style={[
              styles.content,
              { paddingTop: insets.top + 4 },
              (layout.isExpanded || layout.isDuo) && { maxWidth: layout.contentMaxWidth },
            ]}
          >
            <View style={{ paddingHorizontal: 8 }}>
              <CalculatorHeader onBack={onBack} compact={compact} />
            </View>
            <ResponsiveGrid
              minItemWidth={layout.isExpanded ? 320 : 360}
              maxColumns={layout.isExpanded ? gridColumns : layout.isDuo ? 1 : 2}
              gap={12}
              initialWidth={gridWidth}
            >
              {cards.map((card) => (
                <PressableSurface
                  key={card.id}
                  accessibilityRole="button"
                  accessibilityLabel={
                    card.id === 'farming' ? `${card.title}, ${t('calcComingSoon')}` : card.title
                  }
                  accessibilityState={{ disabled: card.id === 'farming' }}
                  disabled={card.id === 'farming'}
                  testID={`calculator-card-${card.id}`}
                  onPress={() => {
                    if (card.id !== 'farming') setPage(card.id);
                  }}
                  radius={28}
                  style={[styles.destination, { height: cardHeight }]}
                >
                  <MobileWebImage
                    imageUrl={bundledImageUrl(card.image)}
                    contentFit="cover"
                    style={[StyleSheet.absoluteFill, card.id === 'farming' && styles.disabledArt]}
                    transition={0}
                  />
                  <HeroHeaderScrim
                    variant={card.id === 'farming' ? 'calculatorDisabled' : 'calculator'}
                  />
                  <View style={styles.copy}>
                    {card.id === 'farming' ? (
                      <View style={styles.comingSoon}>
                        <CKText role="metadata" style={styles.disabledText}>
                          {t('calcComingSoon')}
                        </CKText>
                      </View>
                    ) : null}
                    <CKText
                      role="sectionTitle"
                      style={[
                        styles.cardTitle,
                        layout.isExpanded && { fontSize: 25, lineHeight: 30 },
                        card.id === 'farming' && styles.disabledText,
                      ]}
                    >
                      {card.title}
                    </CKText>
                    <CKText
                      role="body"
                      style={[
                        styles.cardBody,
                        layout.isExpanded && { fontSize: 18, lineHeight: 25 },
                        card.id === 'farming' && styles.disabledText,
                      ]}
                    >
                      {card.body}
                    </CKText>
                  </View>
                </PressableSurface>
              ))}
            </ResponsiveGrid>
          </HubContent>
        </SafeAreaView>
      </DuoBackgroundPane>
    </CalculatorFireballPlayground>
  );
  return (
    <DestinationStack
      focused={page !== 'home'}
      onCloseDetail={() => setPage('home')}
      grid={grid}
      detail={detail}
      backgroundColor={theme.background}
    />
  );
}

// The Duo rail insets content, not the fixed backdrop. Other devices retain
// their original tree and safe-area behavior.
function DuoBackgroundPane({
  children,
  enabled,
  backgroundColor,
}: {
  children: ReactNode;
  enabled: boolean;
  backgroundColor: string;
}) {
  return enabled ? <View style={{ flex: 1, backgroundColor }}>{children}</View> : <>{children}</>;
}

function HubContent({
  children,
  style,
  onLayout,
}: {
  children: ReactNode;
  style: StyleProp<ViewStyle>;
  onLayout: (event: LayoutChangeEvent) => void;
}) {
  const layout = useAdaptiveLayout();
  if (!layout.isExpanded)
    return (
      <View onLayout={onLayout} style={style}>
        {children}
      </View>
    );
  return (
    <ScrollView
      style={{ flex: 1 }}
      onLayout={onLayout}
      contentContainerStyle={[style, { flex: 0, flexGrow: 1 }]}
    >
      {children}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  backdrop: { position: 'absolute', top: 0, left: 0, width: '100%', height: 260 },
  backdropImage: { width: '100%', height: '100%' },
  content: {
    flex: 1,
    paddingHorizontal: 12,
    paddingBottom: 16,
    maxWidth: 1120,
    width: '100%',
    alignSelf: 'center',
    gap: 6,
  },
  destination: {
    borderWidth: 0,
    backgroundColor: '#030304',
    overflow: 'hidden',
    justifyContent: 'flex-end',
  },
  copy: { padding: 18, gap: 4 },
  cardTitle: { color: '#FFFFFF', fontSize: 20, lineHeight: 25, fontWeight: '700' },
  cardBody: { color: '#ECECF0', fontSize: 12, lineHeight: 17 },
  disabledArt: { opacity: 0.42 },
  disabledText: { color: '#A1A1AA' },
  comingSoon: {
    alignSelf: 'flex-start',
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 999,
    backgroundColor: '#FFFFFF1A',
    marginBottom: 4,
  },
});
