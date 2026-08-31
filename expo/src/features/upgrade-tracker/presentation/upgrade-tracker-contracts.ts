import type { CocAccountLink } from '../../auth/models';
import type { Player } from '../../player/models';
import type { UpgradeTrackerRepository, UpgradeWidgetSyncService } from '../data';

export interface UpgradeTrackerRootProps {
  readonly initialTag?: string;
  readonly onBack: () => void;
  readonly repository?: UpgradeTrackerRepository;
  readonly widgetSync?: UpgradeWidgetSyncService;
  readonly accounts?: readonly CocAccountLink[];
  readonly players?: readonly Player[];
  readonly accountId?: string | null;
}
