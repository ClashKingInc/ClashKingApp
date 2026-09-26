const test = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const source = (path) => readFileSync(resolve(__dirname, '../../native', path), 'utf8');

test('iOS widget handoffs carry the intent selection into every timeline entry', () => {
  const swift = source('ios/WarWidget/WarWidget.swift');
  assert.match(swift, /makeEntry\(data: data, clanTag: clanTag\)/);
  assert.match(swift, /widgetDestination\(tag: entry.selectedClanTag, upgrade: false\)/);
  assert.equal((swift.match(/selectedAccountTag: configuration.account\?\.id/g) ?? []).length, 3);
  assert.match(swift, /widgetDestination\(tag: entry.selectedAccountTag, upgrade: true\)/);
});
test('Android widget intents are scoped by widget ID and saved entity', () => {
  const root = 'android/app/src/main/kotlin/com/clashking/clashkingapp/';
  const war = source(root + 'WarAppWidgetProvider.kt');
  const upgrade = source(root + 'UpgradeAppWidgetProvider.kt');
  assert.match(war, /launchAppIntent\(context, appWidgetId, selectedTag\)/);
  assert.match(war, /clashking:\/\/clan\/\$tag\/war/);
  assert.match(upgrade, /getUpgradePendingIntent\(context, appWidgetId\)/);
  assert.match(upgrade, /UpgradeWidgetSelectionStore.selectedTag\(context, appWidgetId\)/);
  assert.match(upgrade, /clashking:\/\/upgrade-tracker\?player=/);
  assert.match(upgrade, /FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT/);
});
