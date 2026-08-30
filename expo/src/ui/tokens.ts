import type { TextStyle } from 'react-native';

export const ckColors = {
  primaryRed: '#D90709',
  lightPrimaryRed: '#BF0000',
  secondaryBlue: '#026CC2',
  lightSecondaryBlue: '#035293',
  legendBlue: '#4E7DF2',
  warGold: '#E8A524',
  capitalPurple: '#8D63D9',
  builderBlue: '#2A9FD6',
  donationGreen: '#14A37F',
  lossRed: '#E35D4F',
  capitalOrange: '#E56B2F',
  capitalTrophy: '#D8891F',
  discordBlurple: '#5865F2',
  upgradePets: '#E85D9E',
  upgradeUnavailable: '#7C8798',
} as const;

export const ckThemeColors = {
  dark: {
    primary: ckColors.primaryRed,
    secondary: ckColors.secondaryBlue,
    tertiary: '#9E9E9E',
    surface: '#0B0B0C',
    background: '#030304',
    card: '#0B0B0C',
    sheet: '#030304',
    snackbar: '#151516',
    dragHandle: '#68686C',
    onPrimary: '#FFFFFF',
    onSecondary: '#FFFFFF',
    onSurface: '#FFFFFF',
    onSurfaceVariant: '#C5C6D0',
    surfaceContainerHighest: '#33343A',
    outlineVariant: '#45464F',
    error: '#FF0000',
    onError: '#FFFFFF',
  },
  light: {
    primary: ckColors.lightPrimaryRed,
    secondary: ckColors.lightSecondaryBlue,
    tertiary: '#757575',
    surface: '#FFFFFF',
    background: '#F4F4F4',
    card: '#FFFFFF',
    sheet: '#FFFFFF',
    snackbar: '#FFFFFF',
    dragHandle: '#79747E',
    onPrimary: '#FFFFFF',
    onSecondary: '#FFFFFF',
    onSurface: '#000000',
    onSurfaceVariant: '#3F484A',
    surfaceContainerHighest: '#DEE3E5',
    outlineVariant: '#BFC8CA',
    error: '#B00020',
    onError: '#FFFFFF',
  },
} as const;

export type CKThemeMode = keyof typeof ckThemeColors;
export type CKThemeColors = (typeof ckThemeColors)[CKThemeMode];

export const ckRadius = {
  control: 12,
  chip: 16,
  tile: 20,
  card: 28,
  panel: 28,
  pill: 999,
} as const;

export const ckOpacity = {
  border: 0.28,
  borderStrong: 0.32,
  fillMuted: 0.45,
} as const;

export const ckSpacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
} as const;

export const ckControlHeight = {
  compact: 44,
  standard: 52,
} as const;

export const ckMotion = {
  fast: 160,
  standard: 220,
  slow: 360,
  standardCurve: [0.215, 0.61, 0.355, 1] as const,
} as const;

export const ckBreakpoints = {
  compact: 360,
  medium: 600,
  desktop: 900,
  wide: 1320,
} as const;

export const ckFontFamily = 'ClashKing';

export const ckTypography = {
  titleLarge: { fontFamily: ckFontFamily, fontSize: 24, fontWeight: '500' },
  titleMedium: { fontFamily: ckFontFamily, fontSize: 20, fontWeight: '500' },
  titleSmall: { fontFamily: ckFontFamily, fontSize: 18, fontWeight: '500' },
  bodyLarge: { fontFamily: ckFontFamily, fontSize: 16, fontWeight: '500' },
  bodyMedium: { fontFamily: ckFontFamily, fontSize: 14, fontWeight: '500' },
  bodySmall: { fontFamily: ckFontFamily, fontSize: 12, fontWeight: '500' },
  labelLarge: { fontFamily: ckFontFamily, fontSize: 12, fontWeight: '500' },
  labelMedium: { fontFamily: ckFontFamily, fontSize: 10, fontWeight: '500' },
  labelSmall: { fontFamily: ckFontFamily, fontSize: 8, fontWeight: '500' },
  heroMetric: {
    fontFamily: ckFontFamily,
    fontSize: 36,
    fontWeight: '800',
    lineHeight: 35,
  },
  screenTitle: {
    fontFamily: ckFontFamily,
    fontSize: 24,
    fontWeight: '700',
    lineHeight: 26,
  },
  sectionTitle: {
    fontFamily: ckFontFamily,
    fontSize: 20,
    fontWeight: '700',
    lineHeight: 24,
  },
  rowTitle: {
    fontFamily: ckFontFamily,
    fontSize: 14,
    fontWeight: '600',
    lineHeight: 17,
  },
  body: {
    fontFamily: ckFontFamily,
    fontSize: 14,
    fontWeight: '500',
    lineHeight: 20,
  },
  metadata: {
    fontFamily: ckFontFamily,
    fontSize: 12,
    fontWeight: '500',
    lineHeight: 16,
  },
  compactLabel: {
    fontFamily: ckFontFamily,
    fontSize: 8,
    fontWeight: '600',
    lineHeight: 10,
  },
} satisfies Record<string, TextStyle>;

export type CKTextRole = keyof typeof ckTypography;

export const statColors = {
  warStarGold: ckColors.warGold,
  win: ckColors.donationGreen,
  loss: ckColors.lossRed,
  tie: ckColors.secondaryBlue,
  capitalLoot: ckColors.warGold,
  capitalDistrict: ckColors.donationGreen,
  capitalAttack: ckColors.builderBlue,
  capitalProjected: ckColors.capitalOrange,
  capitalTrophy: ckColors.capitalTrophy,
} as const;

export function colorWithAlpha(color: string, alpha: number): string {
  const normalized = color.replace('#', '');
  if (normalized.length !== 6) return color;
  const channel = Math.round(Math.max(0, Math.min(1, alpha)) * 255)
    .toString(16)
    .padStart(2, '0')
    .toUpperCase();
  return `#${normalized}${channel}`;
}
