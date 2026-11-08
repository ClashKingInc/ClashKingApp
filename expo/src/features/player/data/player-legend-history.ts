import { PlayerLegendHistoryEndpoint } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';
import type { ContractApiService } from '@/core/api/contract-api';
import { canonicalTag } from '@/core/domain/tags';
import { PlayerLegendHistoryEntry } from '../models/player-legend-history';

// Both the history tab and progressive Legend detail load the same archive.
// Current league membership must never hide a player's retained finishes.
export async function readPlayerLegendHistory(api: ContractApiService, rawTag: string): Promise<readonly PlayerLegendHistoryEntry[]> {
  const response = await Effect.runPromise(api.execute(PlayerLegendHistoryEndpoint, {
    path: { tag: canonicalTag(rawTag) }, query: {}, body: {},
  }));
  return response.items.map(PlayerLegendHistoryEntry.fromJson);
}
