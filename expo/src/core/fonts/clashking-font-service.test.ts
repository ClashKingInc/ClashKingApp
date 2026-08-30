import * as Font from 'expo-font';
import { File } from 'expo-file-system';

import { loadClashKingFont } from './clashking-font-service';

jest.mock('expo-font', () => ({
  loadAsync: jest.fn(async () => undefined),
}));

jest.mock('expo-file-system', () => {
  class Directory {
    readonly uri: string;

    constructor(root: string, name: string) {
      this.uri = `${root}/${name}`;
    }

    create() {}
  }

  class File {
    static deletedUris: string[] = [];
    private present = false;
    size: number | null = null;
    uri: string;

    constructor(directory: Directory, name: string) {
      this.uri = `${directory.uri}/${name}`;
    }

    get exists() {
      return this.present;
    }

    delete() {
      File.deletedUris.push(this.uri);
      this.present = false;
      this.size = null;
    }

    info() {
      return { modificationTime: Date.now() };
    }

    async move(destination: File) {
      destination.present = true;
      destination.size = this.size;
      // Match Expo File.move(): the source handle now represents the
      // destination and continues to report that the moved file exists.
      this.uri = destination.uri;
    }

    static async downloadFileAsync(_url: string, destination: File) {
      destination.present = true;
      destination.size = 121_204;
      return destination;
    }
  }

  return {
    Directory,
    File,
    Paths: { document: 'file:///documents' },
  };
});

describe('ClashKing native font loading', () => {
  it('registers the committed cache URI after the atomic move', async () => {
    await expect(loadClashKingFont()).resolves.toBe(true);

    expect(Font.loadAsync).toHaveBeenCalledWith(
      'ClashKing',
      'file:///documents/fonts/clashking.ttf',
    );
    expect((File as unknown as { deletedUris: string[] }).deletedUris).not.toContain(
      'file:///documents/fonts/clashking.ttf',
    );
  });
});
