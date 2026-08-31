export type AppIconPlatform = 'ios' | 'android' | 'web';

export interface AppIconOption {
  readonly labelKey: 'default' | 'christmas' | 'black_white' | 'dark_mode';
  readonly iconName: string | null;
  readonly previewAsset: string;
}

export interface NativeAppIconBridge {
  supportsAlternateIcons(): Promise<boolean>;
  getAlternateIconName(): Promise<string | null>;
  setAlternateIconName(iconName: string | null): Promise<void>;
}

export const CHRISTMAS_ICON_NAME = 'AppIconChristmas';
export const BLACK_WHITE_ICON_NAME = 'AppIconBlackWhite';
export const DARK_LOGO_ICON_NAME = 'AppIconDarkLogo';

export const APP_ICON_OPTIONS: readonly AppIconOption[] = [
  {
    labelKey: 'default',
    iconName: null,
    previewAsset: 'assets/icons/app_icon_ios_default.png',
  },
  {
    labelKey: 'christmas',
    iconName: CHRISTMAS_ICON_NAME,
    previewAsset: 'assets/icons/app_icon_christmas.png',
  },
  {
    labelKey: 'black_white',
    iconName: BLACK_WHITE_ICON_NAME,
    previewAsset: 'assets/icons/app_icon_black_white.png',
  },
  {
    labelKey: 'dark_mode',
    iconName: DARK_LOGO_ICON_NAME,
    previewAsset: 'assets/icons/app_icon_dark_logo.png',
  },
];

export class UnsupportedAppIconPlatformError extends Error {
  readonly code = 'unsupported';

  constructor() {
    super('Alternate app icons are only supported on iOS.');
    this.name = 'UnsupportedAppIconPlatformError';
  }
}

export function isAppIconPlatformSupported(platform: AppIconPlatform): boolean {
  return platform === 'ios';
}

export class AppIconService {
  constructor(
    private readonly platform: AppIconPlatform,
    private readonly native: NativeAppIconBridge | undefined,
  ) {}

  get isSupportedPlatform(): boolean {
    return isAppIconPlatformSupported(this.platform);
  }

  async supportsAlternateIcons(): Promise<boolean> {
    if (!this.isSupportedPlatform || this.native === undefined) return false;
    return (await this.native.supportsAlternateIcons()) ?? false;
  }

  async getAlternateIconName(): Promise<string | null> {
    if (!this.isSupportedPlatform || this.native === undefined) return null;
    return this.native.getAlternateIconName();
  }

  async setAlternateIconName(iconName: string | null): Promise<void> {
    if (!this.isSupportedPlatform) throw new UnsupportedAppIconPlatformError();
    if (this.native === undefined)
      throw new Error('ClashKing native app-icon bridge is unavailable.');
    await this.native.setAlternateIconName(iconName);
  }

  optionForName(iconName: string | null): AppIconOption {
    return APP_ICON_OPTIONS.find((option) => option.iconName === iconName) ?? APP_ICON_OPTIONS[0]!;
  }
}
