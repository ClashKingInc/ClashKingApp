import { File, Paths } from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { Platform } from 'react-native';
import type { PlayerWarStatsExportEndpoint } from '@clashking/api-contracts/expo';

import type { WarStatsFilter } from '../models';

export async function exportPlayerWarStats(
  download: (body: typeof PlayerWarStatsExportEndpoint.body.Type) => Promise<Response>,
  playerTag: string,
  playerName: string,
  filter: WarStatsFilter,
) {
  const body = buildPlayerWarExportBody(playerTag, filter);
  const response = await download(body);
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

export function buildPlayerWarExportBody(
  playerTag: string,
  filter: WarStatsFilter,
): typeof PlayerWarStatsExportEndpoint.body.Type {
  return {
    player_tag: playerTag,
    ...(filter.startDate ? { timestamp_start: Math.trunc(filter.startDate.getTime() / 1000) } : {}),
    ...(filter.endDate ? { timestamp_end: Math.trunc(filter.endDate.getTime() / 1000) } : {}),
    limit: filter.limit,
  };
}

export function playerWarExportFileName(playerName: string, now = new Date()) {
  const safeName = playerName.replace(/[^\w\s-]/g, '');
  const pad = (value: number) => String(value).padStart(2, '0');
  const timestamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
  return `war_stats${safeName ? `_${safeName}` : ''}_${timestamp}.xlsx`;
}
