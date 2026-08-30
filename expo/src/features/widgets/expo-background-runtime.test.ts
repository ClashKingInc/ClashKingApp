const mockGetAppRuntime = jest.fn();
const mockInitializeObservability = jest.fn();
const mockReportException = jest.fn();
let mockTaskHandler: (() => Promise<string>) | undefined;

jest.mock('expo-background-task', () => ({
  BackgroundTaskResult: { Failed: 'failed', Success: 'success' },
  registerTaskAsync: jest.fn(async () => undefined),
}));

jest.mock('expo-task-manager', () => ({
  isTaskDefined: jest.fn(() => false),
  defineTask: (...args: unknown[]) => {
    mockTaskHandler = args[1] as () => Promise<string>;
  },
}));

jest.mock('../../core/app/runtime', () => ({
  getAppRuntime: (...args: unknown[]) => mockGetAppRuntime(...args),
}));

jest.mock('../../core/observability/observability', () => ({
  initializeObservability: (...args: unknown[]) => mockInitializeObservability(...args),
  reportException: (...args: unknown[]) => mockReportException(...args),
}));

// Install the global TaskManager callback after the native boundaries are mocked.
// eslint-disable-next-line import/first
import {
  configureWarWidgetBackgroundExecutor,
  configureWarWidgetBackgroundRuntimeInitializer,
} from './expo-background-runtime';

describe('Expo war-widget background runtime', () => {
  beforeEach(() => jest.clearAllMocks());

  it('initializes observability, attempts lazy runtime construction, and reports missing executors', async () => {
    configureWarWidgetBackgroundRuntimeInitializer(mockGetAppRuntime);
    await expect(mockTaskHandler?.()).resolves.toBe('failed');
    expect(mockInitializeObservability).toHaveBeenCalledTimes(1);
    expect(mockGetAppRuntime).toHaveBeenCalledTimes(1);
    expect(mockReportException).toHaveBeenCalledWith(
      expect.objectContaining({ message: 'War widget background executor is not configured.' }),
      'widget.background',
    );
  });

  it('reports unexpected outer executor failures', async () => {
    const error = new Error('executor failed before service boundary');
    configureWarWidgetBackgroundExecutor(async () => Promise.reject(error));

    await expect(mockTaskHandler?.()).resolves.toBe('failed');
    expect(mockReportException).toHaveBeenCalledWith(error, 'widget.background');
  });

  it('reports observability initialization failures through the outer task boundary', async () => {
    const error = new Error('observability initialization failed');
    mockInitializeObservability.mockImplementationOnce(() => {
      throw error;
    });

    await expect(mockTaskHandler?.()).resolves.toBe('failed');
    expect(mockReportException).toHaveBeenCalledWith(error, 'widget.background');
  });
});
