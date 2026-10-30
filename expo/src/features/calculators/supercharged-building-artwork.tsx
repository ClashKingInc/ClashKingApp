import { useCallback, useEffect, useRef, useState } from 'react';
import { AppState, View } from 'react-native';
import { useIsFocused } from '@react-navigation/native';
import { Image, type ImageProps } from 'expo-image';
import { useCKAccessibility } from '../../ui/accessibility';
import { MobileWebImage } from '../../ui';

type Bounds = readonly [number, number, number, number];
type SourceGeometry = { level: number; bounds: Bounds; footprint?: 2 | 3 };

// Measured from the actual first-frame exports in official fingerprint
// 7839fe492f55e0c5cb096b788649cd82f2a99f01 (18.600.6). Coordinates retain
// the SC origin lost when the CDN artwork is cropped. The original file has
// only 3x3 effect templates: a 2x2 footprint uses a uniform 2/3 adaptation
// around that origin. This is a footprint-derived placement, not an extracted
// per-building transform from the game runtime.
const geometry: Readonly<Record<string, SourceGeometry>> = {
  '1000012': { level: 16, bounds: [-50, -69, 63, 98] }, // Air Defense
  '1000013': { level: 18, bounds: [-67, -3, 62, 111] }, // Mortar
  '1000021': { level: 13, bounds: [-64, -10, 64, 113] }, // X-Bow
  '1000032': { level: 13, bounds: [-48, -36, 49, 95] }, // Bomb Tower
  '1000067': { level: 7, bounds: [-76, -27, 65, 108] }, // Scattershot
  '1000077': { level: 5, bounds: [-75, -86, 75, 121] }, // Monolith
  '1000084': { level: 4, bounds: [-65, -60, 67, 115] }, // Multi-Archer Tower
  '1000085': { level: 4, bounds: [-73, -39, 72, 113] }, // Ricochet Cannon
  '1000079': { level: 3, bounds: [-71, -89, 71, 109] }, // Multi-Gear Tower
  '1000089': { level: 3, bounds: [-82, -31, 83, 126] }, // Firespitter
  '1000086': { level: 2, bounds: [-69, -95, 69, 113] }, // Revenge Tower
  // The asset pipeline centers the 131px main sprite on its 140px base.
  // Its source origin therefore moves four pixels right in the final crop.
  '1000102': { level: 2, bounds: [-68, -49, 72, 120] }, // Super Wizard Tower
  '1000015': { level: 8, bounds: [-78, -33, 83, 108], footprint: 2 }, // Builder's Hut: turret_load
  '1000019': { level: 17, bounds: [-66, -77, 54, 83], footprint: 2 }, // Hidden Tesla
  '1000027': { level: 12, bounds: [-92, -78, 81, 100], footprint: 2 }, // Inferno Tower
};
const groundBounds: Bounds = [-94, 1, 93, 135];
const sparkleBounds: Bounds = [-120, -53, 120, 138];

export function SuperchargedBuildingArtwork({
  buildingId,
  level,
  imageUrl,
  active,
  size = 112,
}: {
  buildingId: string;
  level: number;
  imageUrl: string;
  active: boolean;
  size?: number;
}) {
  const source = geometry[buildingId];
  // Reserve the same effect envelope at every level, including levels which
  // render the ordinary image. Otherwise crossing into max level resizes the card.
  const [left, top, right, bottom] = source?.bounds ?? [0, 0, size, size];
  const scale = size / Math.max(right - left, bottom - top);
  const effectScale = (source?.footprint ?? 3) / 3;
  const offsetY = (size - (bottom - top) * scale) / 2;
  const paddingTop = source
    ? Math.max(
        0,
        (top - Math.min(top, groundBounds[1] * effectScale, sparkleBounds[1] * effectScale)) *
          scale -
          offsetY,
      )
    : 0;
  const paddingBottom = source
    ? Math.max(
        0,
        (Math.max(bottom, groundBounds[3] * effectScale, sparkleBounds[3] * effectScale) - bottom) *
          scale -
          offsetY,
      )
    : 0;
  return (
    <View style={{ paddingTop, paddingBottom }}>
      {!source || source.level !== level ? (
        <MobileWebImage
          imageUrl={imageUrl}
          contentFit="contain"
          style={{ width: size, height: size }}
        />
      ) : (
        <SourceArtwork
          key={`${buildingId}-${level}-${imageUrl}`}
          source={source}
          imageUrl={imageUrl}
          active={active}
          size={size}
        />
      )}
    </View>
  );
}

function SourceArtwork({
  source,
  imageUrl,
  active,
  size,
}: {
  source: SourceGeometry;
  imageUrl: string;
  active: boolean;
  size: number;
}) {
  const { reduceMotion } = useCKAccessibility();
  const [matchesSource, setMatchesSource] = useState(false);
  const focused = useIsFocused();
  const [foreground, setForeground] = useState(AppState.currentState === 'active');
  useEffect(() => {
    const subscription = AppState.addEventListener('change', (state) =>
      setForeground(state === 'active'),
    );
    return () => subscription.remove();
  }, []);
  const animate = focused && foreground && !reduceMotion;
  const [left, top, right, bottom] = source.bounds;
  const effectScale = (source.footprint ?? 3) / 3;
  const scaledBounds = ([x1, y1, x2, y2]: Bounds): Bounds => [
    x1 * effectScale,
    y1 * effectScale,
    x2 * effectScale,
    y2 * effectScale,
  ];
  const ground = scaledBounds(groundBounds);
  const sparkle = scaledBounds(sparkleBounds);
  // Fit the building, just as MobileWebImage's contain fit does for other
  // levels. Fitting the glow canvas instead shrinks only supported max-level
  // buildings, even when Supercharge is off. Effects share this scale, but
  // their vertical overhang is reserved outside the building's size box.
  const scale = size / Math.max(right - left, bottom - top);
  const offsetX = (size - (right - left) * scale) / 2;
  const offsetY = (size - (bottom - top) * scale) / 2;
  const place = (bounds: Bounds) => ({
    position: 'absolute' as const,
    left: offsetX + (bounds[0] - left) * scale,
    top: offsetY + (bounds[1] - top) * scale,
    width: (bounds[2] - bounds[0]) * scale,
    height: (bounds[3] - bounds[1]) * scale,
  });
  const showEffects = active && matchesSource;
  return (
    <View style={{ width: size, height: size }}>
      {showEffects ? (
        <SuperchargeEffectLayer
          source={require('../../../assets/clashking/calculators/supercharge-ground.webp')}
          animate={animate}
          style={place(ground)}
        />
      ) : null}
      <Image
        source={{ uri: imageUrl }}
        contentFit="contain"
        style={place(source.bounds)}
        onLoad={({ source: loaded }) => {
          // A later asset release may recrop an image. Hide effects if its geometry
          // changes, instead of silently placing a stale overlay on new artwork.
          setMatchesSource(loaded.width === right - left && loaded.height === bottom - top);
        }}
      />
      {showEffects ? (
        <SuperchargeEffectLayer
          source={require('../../../assets/clashking/calculators/supercharge-sparkles.webp')}
          animate={animate}
          style={place(sparkle)}
        />
      ) : null}
    </View>
  );
}

function SuperchargeEffectLayer({
  source,
  style,
  animate,
}: {
  source: ImageProps['source'];
  style: ImageProps['style'];
  animate: boolean;
}) {
  const image = useRef<Image>(null);
  const updatePlayback = useCallback(() => {
    const current = image.current;
    if (!current) return;
    // autoplay controls loading; native start/stop also updates already-loaded
    // images on both platforms. A late load must respect the current focus state.
    void (animate ? current.startAnimating() : current.stopAnimating()).catch(() => {
      // The native view may disappear while this decorative update is queued.
    });
  }, [animate]);
  useEffect(updatePlayback, [updatePlayback]);
  return (
    <Image
      ref={image}
      source={source}
      style={style}
      // Apple's animated-WebP codec can be slow on transparent animations.
      // Decode with libwebp while retaining the original game frames.
      useAppleWebpCodec={false}
      contentFit="contain"
      enforceEarlyResizing
      transition={0}
      autoplay={animate}
      onLoad={updatePlayback}
    />
  );
}
