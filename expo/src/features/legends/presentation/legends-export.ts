import { File, Paths } from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { Platform } from 'react-native';

import type { PlayerLegendLeagueData } from '../../player/models';

export function legendsCsv(data: PlayerLegendLeagueData): string {
  const rows: (string | number)[][] = [
    [
      'record_type',
      'period',
      'direction',
      'opponent_tag',
      'opponent_name',
      'stars',
      'destruction_percentage',
      'duration_seconds',
      'trophies',
      'attacks',
      'defenses',
      'rank',
    ],
  ];
  for (const [direction, battles] of [
    ['attack', data.currentDay?.attacks ?? []],
    ['defense', data.currentDay?.defenses ?? []],
  ] as const)
    for (const battle of battles)
      rows.push([
        'battle',
        battle.battleTime?.toISOString() ?? data.currentDay?.day ?? '',
        direction,
        battle.opponentTag,
        battle.opponentName,
        battle.stars ?? '',
        battle.destructionPercentage ?? '',
        battle.duration,
        battle.trophies,
        '',
        '',
        '',
      ]);
  for (const season of data.history)
    rows.push([
      'season',
      season.season,
      '',
      '',
      '',
      '',
      '',
      '',
      season.trophies,
      season.attackWins,
      season.defenseWins,
      season.rank,
    ]);
  return `${rows.map((row) => row.map(csvCell).join(',')).join('\n')}\n`;
}

export function legendsExportFileName(playerName: string, now = new Date()): string {
  const safeName = playerName
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/\s+/g, '_');
  const pad = (value: number) => String(value).padStart(2, '0');
  const timestamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
  return `legends${safeName ? `_${safeName}` : ''}_${timestamp}.csv`;
}

export async function exportLegends(data: PlayerLegendLeagueData): Promise<string> {
  const fileName = legendsExportFileName(data.playerName);
  const csv = legendsCsv(data);
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

function csvCell(value: string | number): string {
  const text = String(value);
  return /[",\r\n]/u.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}
