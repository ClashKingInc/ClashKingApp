import { createExpoGameDataService } from './expo-game-data-service';

jest.mock('@react-native-async-storage/async-storage', () => ({
  __esModule: true,
  default: {
    getItem: jest.fn(),
    setItem: jest.fn(),
  },
}));

jest.mock('expo-file-system', () => ({
  Directory: class {
    constructor() {
      throw new Error('Native filesystem was constructed');
    }
  },
  File: class {},
  Paths: { document: 'document://' },
}));

describe('createExpoGameDataService', () => {
  test('does not construct the native filesystem on web', () => {
    expect(() => createExpoGameDataService('web')).not.toThrow();
  });
});
