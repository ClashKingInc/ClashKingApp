/** Presentation colors sampled from the saturated body of the published
 * league badges. These are artwork accents, not gameplay metadata. */
export function rankedLeagueDisplayColor(name: string): string {
  const family = name.toLowerCase().replace(/[^a-z]/g, '');
  const colors: Readonly<Record<string, string>> = {
    skeleton: '#976D38', barbarian: '#DBA222', archer: '#CA4689',
    wizard: '#18749C', valkyrie: '#CB5627', witch: '#554AC2',
    golem: '#844994', pekka: '#4D6D93', titan: '#52A8BC',
    dragon: '#6B57C4', electro: '#3B8BBC', legend: '#D87114',
  };
  return Object.entries(colors).find(([key]) => family.startsWith(key))?.[1] ?? '#8A8F98';
}
