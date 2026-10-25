import { useState } from 'react';
import { Image, StyleSheet } from 'react-native';
import Svg, { Path } from 'react-native-svg';
import { StartupBrand } from './startup-brand';

const CROWN = require('../../../assets/clashking/startup/halloween/crown.png');
const ARROW = require('../../../assets/clashking/startup/halloween/arrow-ends.png');
const SHAFT_CUT =
  'M797 289 L841 318 L590 741 L651 776 L588 750 L569 770 L569 748 L547 768 L550 741 L521 759 L533 729 L507 735 L524 718 L491 716 L525 702 L490 655 L548 680 Z';

/** Plain native images avoid SVG bitmap masks, which hid the crown on iOS.
 * Both image planes decode before the shared flight timeline starts. */
export function StartupHalloweenBrand(props: {
  reduceMotion: boolean;
  foreground: string;
  background: string;
  label: string;
  width: number;
}) {
  const [loaded, setLoaded] = useState({ crown: false, arrow: false });
  const [failed, setFailed] = useState(false);
  if (failed) return <StartupBrand {...props} />;
  return (
    <StartupBrand
      {...props}
      artwork={{
        crown: (
          <Image
            source={CROWN}
            resizeMode="stretch"
            fadeDuration={0}
            style={styles.crown}
            onLoad={() =>
              setLoaded((current) => (current.crown ? current : { ...current, crown: true }))
            }
            onError={() => setFailed(true)}
          />
        ),
        impact: (
          <Svg width={134} height={134} viewBox="0 0 1254 1254" style={{ marginLeft: -11 }}>
            <Path d={SHAFT_CUT} fill="#FFF8DE" />
          </Svg>
        ),
        arrow: (
          <Image
            source={ARROW}
            resizeMode="stretch"
            fadeDuration={0}
            style={styles.arrow}
            onLoad={() =>
              setLoaded((current) => (current.arrow ? current : { ...current, arrow: true }))
            }
            onError={() => setFailed(true)}
          />
        ),
        accent: '#ED7811',
        ready: loaded.crown && loaded.arrow,
        arrowBehindCrown: true,
      }}
    />
  );
}

// The transparent canvases are aligned by their alpha bounds to the original
// icon's 134pt plane. This keeps the crown and arrow registered without masks.
const styles = StyleSheet.create({
  crown: { position: 'absolute', left: -3.61, top: 3.15, width: 118.9, height: 122.66 },
  arrow: { position: 'absolute', left: -7.47, top: -1.47, width: 123.95, height: 132.92 },
});
