export type AppIconPlatform = 'ios' | 'android' | 'web';

export interface AppIconOption {
  readonly labelKey: 'default' | 'christmas' | 'halloween' | 'black_white' | 'dark_mode';
  readonly iconName: string | null;
  readonly previewAsset: string;
}

export interface NativeAppIconBridge {
  supportsAlternateIcons(): Promise<boolean>;
  getAlternateIconName(): Promise<string | null>;
  setAlternateIconName(iconName: string | null): Promise<void>;
}

export const CHRISTMAS_ICON_NAME = 'AppIconChristmas';
export const HALLOWEEN_ICON_NAME = 'AppIconHalloween';
export const BLACK_WHITE_ICON_NAME = 'AppIconBlackWhite';
export const DARK_LOGO_ICON_NAME = 'AppIconDarkLogo';

export const APP_ICON_OPTIONS: readonly AppIconOption[] = [
  {
    labelKey: 'default',
    iconName: null,
    previewAsset: 'assets/icons/app_icon_ios_default.png',
  },
  {
    labelKey: 'halloween',
    iconName: HALLOWEEN_ICON_NAME,
    previewAsset: 'assets/icons/app_icon_halloween.png',
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
    super('Alternate app icons are only supported in native iOS and Android builds.');
    this.name = 'UnsupportedAppIconPlatformError';
  }
}

export function isAppIconPlatformSupported(platform: AppIconPlatform): boolean {
  return platform === 'ios' || platform === 'android';
}

export class AppIconService {
  private selectedIconName: string | null | undefined;
  private selectionRevision = 0;
  private readonly selectionListeners = new Set<() => void>();
  private pendingSelectionRead: Promise<string | null> | undefined;

  constructor(
    private readonly platform: AppIconPlatform,
    private readonly native: NativeAppIconBridge | undefined,
  ) {}

  get isSupportedPlatform(): boolean {
    return isAppIconPlatformSupported(this.platform);
  }

  // Undefined means native selection has not been read yet. Startup must not
  // briefly animate the default mark before discovering a seasonal selection.
  getSelectionSnapshot = (): string | null | undefined => this.selectedIconName;

  subscribeSelection = (listener: () => void): (() => void) => {
    this.selectionListeners.add(listener);
    return () => {
      this.selectionListeners.delete(listener);
    };
  };

  private publishSelection(iconName: string | null): void {
    if (this.selectedIconName === iconName) return;
    this.selectedIconName = iconName;
    this.selectionListeners.forEach((listener) => listener());
  }

  async supportsAlternateIcons(): Promise<boolean> {
    if (!this.isSupportedPlatform || this.native === undefined) return false;
    return (await this.native.supportsAlternateIcons()) ?? false;
  }

  async getAlternateIconName(): Promise<string | null> {
    if (!this.isSupportedPlatform || this.native === undefined) {
      this.publishSelection(null);
      return null;
    }
    if (!this.pendingSelectionRead) {
      const revision = this.selectionRevision;
      this.pendingSelectionRead = this.native
        .getAlternateIconName()
        .then((iconName) => {
          // A native read started before a successful icon change must not
          // overwrite that newer selection when the read resolves late.
          if (revision === this.selectionRevision) this.publishSelection(iconName);
          return this.selectedIconName ?? null;
        })
        .finally(() => {
          this.pendingSelectionRead = undefined;
        });
    }
    return this.pendingSelectionRead;
  }

  async setAlternateIconName(iconName: string | null): Promise<void> {
    if (!this.isSupportedPlatform) throw new UnsupportedAppIconPlatformError();
    if (this.native === undefined)
      throw new Error('ClashKing native app-icon bridge is unavailable.');
    await this.native.setAlternateIconName(iconName);
    this.selectionRevision += 1;
    this.publishSelection(iconName);
  }

  optionForName(iconName: string | null): AppIconOption {
    return APP_ICON_OPTIONS.find((option) => option.iconName === iconName) ?? APP_ICON_OPTIONS[0]!;
  }
}
