import { File, Paths } from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { Platform } from 'react-native';

import type { PlayerBattlelogEntry, PlayerBattlelogMode } from '../models';

export function playerBattlelogCsv(items: readonly PlayerBattlelogEntry[]): string {
  const rows = [
    [
      'battle_mode',
      'direction',
      'battle_time',
      'opponent_tag',
      'opponent_name',
      'opponent_town_hall',
      'stars',
      'destruction_percentage',
      'duration_seconds',
      'gold',
      'elixir',
      'dark_elixir',
      'army_share_code',
    ],
    ...items.map((item) => [
      item.mode,
      item.attack ? 'attack' : 'defense',
      item.timestamp?.toISOString() ?? '',
      item.opponentTag,
      item.opponentName,
      item.opponentTownHall || '',
      item.stars,
      item.destructionPercentage,
      item.duration,
      item.gold,
      item.elixir,
      item.darkElixir,
      item.armyShareCode,
    ]),
  ];
  return `${rows.map((row) => row.map(csvCell).join(',')).join('\n')}\n`;
}

export function playerBattlelogExportFileName(
  playerName: string,
  mode: PlayerBattlelogMode,
  now = new Date(),
): string {
  const safeName = playerName
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/\s+/g, '_');
  const pad = (value: number) => String(value).padStart(2, '0');
  const timestamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
  return `battlelog_${mode}${safeName ? `_${safeName}` : ''}_${timestamp}.csv`;
}

export async function exportPlayerBattlelog(
  items: readonly PlayerBattlelogEntry[],
  playerName: string,
  mode: PlayerBattlelogMode,
): Promise<string> {
  const fileName = playerBattlelogExportFileName(playerName, mode);
  const csv = playerBattlelogCsv(items);
  if (Platform.OS === 'web') {
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName;
    link.click();
    URL.revokeObjectURL(url);
    return fileName;
  }
  const file = new File(Paths.cache, fileName);
  file.create({ overwrite: true, intermediates: true });
  file.write(csv);
  if (!(await Sharing.isAvailableAsync())) throw new Error('Sharing is unavailable.');
  await Sharing.shareAsync(file.uri, { mimeType: 'text/csv', dialogTitle: fileName });
  return file.uri;
}

function csvCell(value: unknown): string {
  const text = String(value ?? '');
  return /[",\r\n]/u.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}
