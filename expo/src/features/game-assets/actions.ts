import ClashKingNative, { type SaveFileOptions } from '@clashking/native';
import * as Clipboard from 'expo-clipboard';
import { File, Paths } from 'expo-file-system';
import { Platform, Share } from 'react-native';

import type { GameAsset } from './models';

export interface GameAssetActions {
  copy(value: string): Promise<void>;
  share(asset: GameAsset): Promise<void>;
  save(asset: GameAsset): Promise<string>;
}

export class GameAssetActionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'GameAssetActionError';
  }
}

export class PlatformGameAssetActions implements GameAssetActions {
  constructor(
    private readonly options: {
      readonly fetchImplementation?: typeof fetch;
      readonly requestTimeoutMs?: number;
      readonly platform?: typeof Platform.OS;
      readonly saveFile?: (options: SaveFileOptions) => Promise<string>;
    } = {},
  ) {}

  async copy(value: string): Promise<void> {
    await Clipboard.setStringAsync(value);
  }

  async share(asset: GameAsset): Promise<void> {
    const platform = this.options.platform ?? Platform.OS;
    await Share.share(
      platform === 'ios'
        ? { title: asset.displayName, url: asset.url }
        : { title: asset.displayName, message: asset.url },
    );
  }

  async save(asset: GameAsset): Promise<string> {
    const platform = this.options.platform ?? Platform.OS;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.options.requestTimeoutMs ?? 30_000);
    let response: Response;
    try {
      response = await (this.options.fetchImplementation ?? fetch)(asset.url, {
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeout);
    }
    if (!response.ok) {
      throw new GameAssetActionError(`Asset download failed (${response.status})`);
    }
    if (platform === 'web') {
      const blobUrl = URL.createObjectURL(await response.blob());
      const anchor = document.createElement('a');
      anchor.href = blobUrl;
      anchor.download = asset.fileName;
      anchor.click();
      URL.revokeObjectURL(blobUrl);
      return '';
    }
    const destination = new File(Paths.cache, asset.fileName);
    destination.create({ overwrite: true, intermediates: true });
    destination.write(new Uint8Array(await response.arrayBuffer()));
    try {
      return await (this.options.saveFile ?? ClashKingNative.saveFile)({
        fileUri: destination.uri,
        fileName: asset.fileName,
        mimeType: mimeTypeForExtension(asset.extension),
      });
    } finally {
      destination.delete();
    }
  }
}

export function mimeTypeForExtension(extension: string): string {
  switch (extension.toLowerCase()) {
    case 'svg':
      return 'image/svg+xml';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/png';
  }
}
