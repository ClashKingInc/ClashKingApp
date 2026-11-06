import { useCallback, useMemo, type ReactNode } from 'react';
import { PanResponder, Pressable, StyleSheet, View } from 'react-native';
import { ChevronLeft, ChevronRight } from 'lucide-react-native';
import { CKText, colorWithAlpha, useCKTheme } from '../../ui';
import { useCKAccessibility } from '../../ui/accessibility';
import { BundledHeroScene } from '../../ui/bundled-hero-scene';

/* eslint-disable @typescript-eslint/no-require-imports -- Metro requires static bundled-asset references. */
const models: Record<string, number> = {
  // Keep static references so Metro includes the original, converted game models.
  'Barbarian King': require('../../../assets/clashking/heroes/barbarian-king-rigged.glb'),
  'Archer Queen': require('../../../assets/clashking/heroes/archer-queen-rigged.glb'),
  'Grand Warden': require('../../../assets/clashking/heroes/grand-warden-rigged.glb'),
  'Royal Champion': require('../../../assets/clashking/heroes/royal-champion-rigged.glb'),
  'Minion Prince': require('../../../assets/clashking/heroes/minion-prince-rigged.glb'),
  'Dragon Duke': require('../../../assets/clashking/heroes/dragon-duke-rigged.glb'),
};
/* eslint-enable @typescript-eslint/no-require-imports */
export const heroAccents: Record<string, string> = {
  'Barbarian King': '#DCAE56',
  'Archer Queen': '#A585DD',
  'Grand Warden': '#A996EF',
  'Royal Champion': '#5AA9CD',
  'Minion Prince': '#6C8EDD',
  'Dragon Duke': '#D88D59',
};
// Centers and framing cover the union of 61 sampled idle frames, not the
// unanimated bind pose. Flying heroes otherwise rise out of the viewport.
const framing: Record<string, { target: string; orbit: string }> = {
  'Barbarian King': { target: '0.076m 12.670m 4.948m', orbit: '0deg 75deg 56m' },
  'Archer Queen': { target: '-0.264m 11.611m -3.195m', orbit: '0deg 75deg 52m' },
  'Grand Warden': { target: '0.463m 12.261m 1.748m', orbit: '0deg 75deg 60m' },
  'Royal Champion': { target: '-0.071m 10.858m 1.607m', orbit: '0deg 75deg 49m' },
  'Minion Prince': { target: '-0.6314m 25.7346m -0.8984m', orbit: '0deg 75deg 60m' },
  'Dragon Duke': { target: '1.131m 13.774m -3.682m', orbit: '0deg 75deg 72m' },
};
type Hero = { id: string; name: string; label: string };

export function HeroCarousel({
  heroes,
  selectedId,
  onSelect,
  trailing,
  leading,
  children,
}: {
  heroes: Hero[];
  selectedId: string;
  onSelect: (id: string) => void;
  trailing?: ReactNode;
  leading?: ReactNode;
  children?: ReactNode;
}) {
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const index = Math.max(
    0,
    heroes.findIndex((hero) => hero.id === selectedId),
  );
  const selected = heroes[index]!;
  const accent = heroAccents[selected.name] ?? theme.secondary;
  const move = useCallback(
    (direction: number) =>
      onSelect(heroes[(index + direction + heroes.length) % heroes.length]!.id),
    [heroes, index, onSelect],
  );
  const responder = useMemo(
    () =>
      PanResponder.create({
        // Horizontal intent only: the surrounding page must retain vertical scrolling.
        onMoveShouldSetPanResponder: (_, gesture) =>
          Math.abs(gesture.dx) > 18 && Math.abs(gesture.dx) > Math.abs(gesture.dy) * 1.8,
        onPanResponderRelease: (_, gesture) => {
          if (Math.abs(gesture.dx) > 40) move(gesture.dx < 0 ? 1 : -1);
        },
        onPanResponderTerminationRequest: () => true,
      }),
    [move],
  );
  return (
    <View style={styles.card}>
      {trailing ? (
        <View
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: 12,
            paddingBottom: 0,
          }}
        >
          {leading}
          <View style={{ width: 164 }}>{trailing}</View>
        </View>
      ) : null}
      <View style={styles.stage} {...responder.panHandlers}>
        <BundledHeroScene
          models={heroes.map((hero) => ({
            source: models[hero.name]!,
            label: hero.label,
            target: framing[hero.name]?.target,
            orbit: framing[hero.name]?.orbit,
          }))}
          selected={index}
          playing={!reduceMotion}
        />
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={heroes[(index - 1 + heroes.length) % heroes.length]!.label}
          onPress={() => move(-1)}
          style={[
            styles.arrow,
            styles.left,
            { backgroundColor: colorWithAlpha(theme.background, 0.5) },
          ]}
        >
          <ChevronLeft size={22} color={theme.onSurface} />
        </Pressable>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={heroes[(index + 1) % heroes.length]!.label}
          onPress={() => move(1)}
          style={[
            styles.arrow,
            styles.right,
            { backgroundColor: colorWithAlpha(theme.background, 0.5) },
          ]}
        >
          <ChevronRight size={22} color={theme.onSurface} />
        </Pressable>
      </View>
      <CKText role="titleMedium" style={styles.name}>
        {selected.label}
      </CKText>
      <View style={styles.dots}>
        {heroes.map((hero) => (
          <Pressable
            key={hero.id}
            accessibilityRole="tab"
            accessibilityLabel={hero.label}
            accessibilityState={{ selected: hero.id === selected.id }}
            onPress={() => onSelect(hero.id)}
            style={styles.dotTarget}
          >
            <View
              style={{
                width: hero.id === selected.id ? 18 : 6,
                height: 6,
                borderRadius: 3,
                backgroundColor:
                  hero.id === selected.id ? accent : colorWithAlpha(theme.onSurface, 0.3),
              }}
            />
          </Pressable>
        ))}
      </View>
      {children ? (
        <View style={{ paddingHorizontal: 16, paddingBottom: 8 }}>{children}</View>
      ) : null}
    </View>
  );
}
const styles = StyleSheet.create({
  card: { borderRadius: 28, overflow: 'hidden', paddingBottom: 8 },
  stage: { height: 220, overflow: 'hidden', width: '100%', maxWidth: 700, alignSelf: 'center' },
  arrow: {
    position: 'absolute',
    top: 94,
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 3,
  },
  left: { left: 8 },
  right: { right: 8 },
  name: { textAlign: 'center' },
  dots: { flexDirection: 'row', justifyContent: 'center' },
  dotTarget: { height: 32, minWidth: 28, justifyContent: 'center', alignItems: 'center' },
});
