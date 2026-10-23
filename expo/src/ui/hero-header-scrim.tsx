import { Image, StyleSheet } from 'react-native';
import { useCKThemeMode } from './theme';

const sources = {
  standard: {
    dark: require('../../assets/clashking/backgrounds/header-standard-dark.png'),
    light: require('../../assets/clashking/backgrounds/header-standard-light.png'),
  },
  clan: {
    dark: require('../../assets/clashking/backgrounds/header-clan-dark.png'),
    light: require('../../assets/clashking/backgrounds/header-clan-light.png'),
  },
  player: {
    dark: require('../../assets/clashking/backgrounds/header-player-dark.png'),
    light: require('../../assets/clashking/backgrounds/header-player-light.png'),
  },
  war: {
    dark: require('../../assets/clashking/backgrounds/header-war-dark.png'),
    light: require('../../assets/clashking/backgrounds/header-war-light.png'),
  },
};

/** Bundled gradients share artwork bounds in native layout, including rotation.
 * Do not wait for onLayout in JS: that exposes an untinted frame while resizing. */
export function HeroHeaderScrim({ variant = 'standard' }: {
  variant?: 'standard' | 'clan' | 'player' | 'war' | 'ranked' | 'calculator' | 'calculatorDisabled';
}) {
  const mode = useCKThemeMode();
  const source = variant === 'ranked'
    ? require('../../assets/clashking/backgrounds/header-ranked.png')
    : variant === 'calculator'
    ? require('../../assets/clashking/backgrounds/header-calculator.png')
    : variant === 'calculatorDisabled'
      ? require('../../assets/clashking/backgrounds/header-calculator-disabled.png')
      : sources[variant][mode];
  return <Image pointerEvents="none" accessible={false} source={source}
    resizeMode="stretch" style={styles.fill} />;
}

const styles = StyleSheet.create({
  // These source images are only 2px wide. Absolute edge constraints alone can
  // retain an Image's intrinsic bounds on native; specify both dimensions so
  // the gradient fills its parent in the same layout pass, including rotation.
  fill: { position: 'absolute', top: 0, left: 0, width: '100%', height: '100%' },
});
