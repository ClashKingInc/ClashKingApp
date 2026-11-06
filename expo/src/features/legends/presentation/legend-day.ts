export function legendDayOffset(day: string, offset: number): string {
  const date = new Date(`${day}T00:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() + offset);
  return date.toISOString().slice(0, 10);
}

export function canMoveToNextLegendDay(day: string, today: string): boolean {
  return day < today;
}
