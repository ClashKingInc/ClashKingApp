import { useEffect, useState } from 'react';
import { BackHandler, Image, StyleSheet, View, useWindowDimensions } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { Asset } from 'expo-asset';
import { HeroHeaderScrim } from '../../ui/hero-header-scrim';
import { useI18n } from '../../i18n';
import { CKText, DestinationStack, MobileWebImage, PressableSurface, ResponsiveGrid, useCKTheme } from '../../ui';
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
  const [contentHeight, setContentHeight] = useState(0);
  const gridWidth = Math.min(width - 24, 1096);
  const gridRows = gridWidth >= 732 ? 2 : 3;
  // Size from the actual page, not the image aspect ratio, so all destinations
  // remain on screen even when native navigation reduces the available height.
  const availableHeight = contentHeight || height - insets.bottom;
  const cardHeight = Math.max(0, (availableHeight - insets.top - 4 - 76 - 16 - 6 - (gridRows - 1) * 12) / gridRows);
  const compact = width < 360;
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
  const grid = (
    <CalculatorFireballPlayground visible={page === 'home'}>
    <SafeAreaView
      edges={['bottom', 'left', 'right']}
      style={{ flex: 1, backgroundColor: pageBackground }}
      testID="calculator-hub"
    >
      {/* Fixed-height native artwork reaches the page color before the grid;
          it must never tint the entire scroll surface navy. */}
      <View pointerEvents="none" style={styles.backdrop}>
        {/* The source is only two pixels wide. Explicit dimensions prevent a
            native image from falling back to a thin intrinsic-width strip. */}
        <Image source={dark ? require('../../../assets/clashking/backgrounds/hub-blue-dark.png') : require('../../../assets/clashking/backgrounds/hub-blue-light.png')} resizeMode="stretch" style={styles.backdropImage} />
      </View>
      <View onLayout={event => setContentHeight(event.nativeEvent.layout.height)} style={[styles.content, { paddingTop: insets.top + 4 }]}>
        <View style={{ paddingHorizontal: 8 }}><CalculatorHeader onBack={onBack} compact={compact} /></View>
        <ResponsiveGrid minItemWidth={360} maxColumns={2} gap={12} initialWidth={gridWidth}>
          {cards.map((card) => (
            <PressableSurface
              key={card.id}
              accessibilityRole="button"
              accessibilityLabel={card.id === 'farming' ? `${card.title}, ${t('calcComingSoon')}` : card.title}
              accessibilityState={{ disabled: card.id === 'farming' }}
              disabled={card.id === 'farming'}
              testID={`calculator-card-${card.id}`}
              onPress={() => { if (card.id !== 'farming') setPage(card.id); }}
              radius={28}
              style={[styles.destination, { height: cardHeight }]}
            >
              <MobileWebImage imageUrl={Asset.fromModule(card.image).uri} contentFit="cover" style={[StyleSheet.absoluteFill, card.id === 'farming' && styles.disabledArt]} transition={0} />
              <HeroHeaderScrim variant={card.id === 'farming' ? 'calculatorDisabled' : 'calculator'} />
              <View style={styles.copy}>
                {card.id === 'farming' ? <View style={styles.comingSoon}><CKText role="metadata" style={styles.disabledText}>{t('calcComingSoon')}</CKText></View> : null}
                <CKText role="sectionTitle" style={[styles.cardTitle, card.id === 'farming' && styles.disabledText]}>{card.title}</CKText>
                <CKText role="body" style={[styles.cardBody, card.id === 'farming' && styles.disabledText]}>{card.body}</CKText>
              </View>
            </PressableSurface>
          ))}
        </ResponsiveGrid>
      </View>
    </SafeAreaView>
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

const styles = StyleSheet.create({
  backdrop: { position: 'absolute', top: 0, left: 0, width: '100%', height: 260 },
  backdropImage: { width: '100%', height: '100%' },
  content: { flex: 1, paddingHorizontal: 12, paddingBottom: 16, maxWidth: 1120, width: '100%', alignSelf: 'center', gap: 6 },
  destination: { borderWidth: 0, backgroundColor: '#030304', overflow: 'hidden', justifyContent: 'flex-end' },
  copy: { padding: 18, gap: 4 },
  cardTitle: { color: '#FFFFFF', fontSize: 20, lineHeight: 25, fontWeight: '700' },
  cardBody: { color: '#ECECF0', fontSize: 12, lineHeight: 17 },
  disabledArt: { opacity: 0.42 },
  disabledText: { color: '#A1A1AA' },
  comingSoon: { alignSelf: 'flex-start', paddingHorizontal: 12, paddingVertical: 5, borderRadius: 999, backgroundColor: '#FFFFFF1A', marginBottom: 4 },
});
