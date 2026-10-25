import { buildModelViewerDocument } from '../../../ui/model-viewer-document';
import type { AchievementModelRequest } from './contracts';
export { MODEL_VIEWER_SCRIPT } from '../../../ui/model-viewer-document';
export function buildAchievementModelDocument(
  source: string,
  request: AchievementModelRequest,
): string {
  return buildModelViewerDocument(source, {
    label: request.semanticLabel,
    interactive: request.interactive,
    idleRotation: request.enableIdleRotation,
    locked: request.achievement.earnedCount <= 0,
  });
}
