import { File, Paths } from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { Platform } from 'react-native';

import type { WarStatsFilter } from '../models';

export async function exportPlayerWarStats(
  apiV2Url: string,
  playerTag: string,
  playerName: string,
  filter: WarStatsFilter,
) {
  const body = buildPlayerWarExportBody(playerTag, filter);
  const response = await fetch(`${apiV2Url.replace(/\/$/, '')}/exports/war/player-stats`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!response.ok) throw new Error(`Export failed (${response.status})`);
  const contentType = response.headers.get('content-type') ?? '';
  if (!/spreadsheet|excel|application\/octet-stream/i.test(contentType))
    throw new Error(`Expected Excel file but got: ${contentType}`);
  const fileName = playerWarExportFileName(playerName);
  if (Platform.OS === 'web') {
    const url = URL.createObjectURL(await response.blob());
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();
    URL.revokeObjectURL(url);
    return fileName;
  }
  const file = new File(Paths.document, fileName);
  file.write(new Uint8Array(await response.arrayBuffer()));
  if (await Sharing.isAvailableAsync())
    await Sharing.shareAsync(file.uri, {
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      dialogTitle: fileName,
    });
  return file.uri;
}

export function buildPlayerWarExportBody(playerTag: string, filter: WarStatsFilter) {
  const body: Record<string, unknown> = { player_tags: [playerTag] };
  if (!filter.hasActiveFilters()) return body;
  if (filter.season) body.season = filter.season;
  if (filter.startDate) body.timestamp_start = Math.trunc(filter.startDate.getTime() / 1000);
  if (filter.endDate) body.timestamp_end = Math.trunc(filter.endDate.getTime() / 1000);
  if (filter.warTypes?.length && !filter.warTypes.includes('all')) body.type = filter.warTypes;
  if (filter.ownTownHalls?.length) body.own_th = filter.ownTownHalls;
  if (filter.enemyTownHalls?.length) body.enemy_th = filter.enemyTownHalls;
  if (filter.allowedStars?.length) body.stars = filter.allowedStars;
  if (filter.minDestruction !== null) body.min_destruction = filter.minDestruction;
  if (filter.maxDestruction !== null) body.max_destruction = filter.maxDestruction;
  if (filter.minMapPosition !== null) body.map_position_min = filter.minMapPosition;
  if (filter.maxMapPosition !== null) body.map_position_max = filter.maxMapPosition;
  if (filter.freshAttacksOnly === true) body.fresh_only = true;
  return body;
}

export function playerWarExportFileName(playerName: string, now = new Date()) {
  const safeName = playerName.replace(/[^\w\s-]/g, '');
  const pad = (value: number) => String(value).padStart(2, '0');
  const timestamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
  return `war_stats${safeName ? `_${safeName}` : ''}_${timestamp}.xlsx`;
}
