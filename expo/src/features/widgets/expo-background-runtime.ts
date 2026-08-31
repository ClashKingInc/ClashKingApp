import * as BackgroundTask from 'expo-background-task';
import * as TaskManager from 'expo-task-manager';
import { initializeObservability, reportException } from '../../core/observability/observability';
import type { WidgetBackgroundScheduler } from './contracts';
import { WAR_WIDGET_BACKGROUND_TASK } from './war-widget-service';

export type WarWidgetBackgroundExecutor = (taskName: string) => Promise<boolean>;

let backgroundExecutor: WarWidgetBackgroundExecutor | undefined;
let backgroundRuntimeInitializer: (() => void) | undefined;

if (!TaskManager.isTaskDefined(WAR_WIDGET_BACKGROUND_TASK)) {
  TaskManager.defineTask(WAR_WIDGET_BACKGROUND_TASK, async () => {
    try {
      initializeObservability();
      if (backgroundExecutor === undefined) {
        backgroundRuntimeInitializer?.();
      }
      if (backgroundExecutor === undefined) {
        const error = new Error('War widget background executor is not configured.');
        reportException(error, 'widget.background');
        return BackgroundTask.BackgroundTaskResult.Failed;
      }
      return (await backgroundExecutor(WAR_WIDGET_BACKGROUND_TASK))
        ? BackgroundTask.BackgroundTaskResult.Success
        : BackgroundTask.BackgroundTaskResult.Failed;
    } catch (error) {
      reportException(error, 'widget.background');
      return BackgroundTask.BackgroundTaskResult.Failed;
    }
  });
}

/** Configure at module scope so Expo can execute after starting a headless JS bundle. */
export function configureWarWidgetBackgroundExecutor(executor: WarWidgetBackgroundExecutor): void {
  backgroundExecutor = executor;
}

export function configureWarWidgetBackgroundRuntimeInitializer(initializer: () => void): void {
  backgroundRuntimeInitializer = initializer;
}

export class ExpoWidgetBackgroundScheduler implements WidgetBackgroundScheduler {
  registerPeriodicTask(taskName: string, minimumIntervalMinutes: number): Promise<void> {
    return BackgroundTask.registerTaskAsync(taskName, {
      minimumInterval: minimumIntervalMinutes,
    });
  }
}
