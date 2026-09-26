import { STORAGE_KEYS, type StringStorage } from '@/core/storage/storage';
import {
  HomeAccountLimitError,
  MAX_HOME_ACCOUNTS,
  PlayerCardPreferencesService,
} from './player-card-preferences';

class MemoryStorage implements StringStorage {
  readonly values = new Map<string, string>();
  async getString(key: string) {
    return this.values.get(key) ?? null;
  }
  async setString(key: string, value: string) {
    this.values.set(key, value);
  }
  async remove(key: string) {
    this.values.delete(key);
  }
}

const six = ['#ONE', '#TWO', '#THREE', '#FOUR', '#FIVE', '#SIX'];

describe('Home account inclusion', () => {
  it('defaults to at most five verified accounts and keeps the last selected account visible', async () => {
    const storage = new MemoryStorage();
    const preferences = new PlayerCardPreferencesService(storage);
    await preferences.load();

    expect(MAX_HOME_ACCOUNTS).toBe(5);
    expect(preferences.homeIncludedTags(six, '#SIX')).toEqual([
      'ONE',
      'TWO',
      'THREE',
      'FOUR',
      'SIX',
    ]);
    await preferences.reconcileHomeIncluded(six, '#SIX');
    expect(JSON.parse(storage.values.get(STORAGE_KEYS.homeIncludedAccounts)!)).toEqual([
      'ONE',
      'TWO',
      'THREE',
      'FOUR',
      'SIX',
    ]);
  });

  it('normalizes old oversized and duplicate selections without unlinking accounts', async () => {
    const storage = new MemoryStorage();
    storage.values.set(
      STORAGE_KEYS.homeIncludedAccounts,
      JSON.stringify(['#ONE', 'TWO', 'ONE', 'THREE', 'FOUR', 'FIVE', 'SIX']),
    );
    const preferences = new PlayerCardPreferencesService(storage);
    await preferences.load();
    expect(preferences.homeIncludedTags(six, '#SIX')).toEqual([
      'ONE',
      'TWO',
      'THREE',
      'FOUR',
      'SIX',
    ]);
    await preferences.reconcileHomeIncluded(six, '#SIX');
    expect(JSON.parse(storage.values.get(STORAGE_KEYS.homeIncludedAccounts)!)).toEqual([
      'ONE',
      'TWO',
      'THREE',
      'FOUR',
      'SIX',
    ]);
  });

  it('rejects a rapid sixth inclusion but frees the slot immediately when another is deselected', async () => {
    const storage = new MemoryStorage();
    const preferences = new PlayerCardPreferencesService(storage);
    await preferences.load();
    await preferences.reconcileHomeIncluded(six.slice(0, 5), '#ONE');

    await expect(preferences.setShownOnHome('#SIX', true, six, '#ONE')).rejects.toBeInstanceOf(
      HomeAccountLimitError,
    );
    const remove = preferences.setShownOnHome('#FIVE', false, six, '#ONE');
    const add = preferences.setShownOnHome('#SIX', true, six, '#ONE');
    await Promise.all([remove, add]);
    expect(preferences.homeIncludedTags(six, '#ONE')).toEqual([
      'ONE',
      'TWO',
      'THREE',
      'FOUR',
      'SIX',
    ]);
    expect(JSON.parse(storage.values.get(STORAGE_KEYS.homeIncludedAccounts)!)).toEqual([
      'ONE',
      'TWO',
      'THREE',
      'FOUR',
      'SIX',
    ]);
  });

  it('does not erase choices during logout or an empty transient roster, and defaults a disjoint new roster', async () => {
    const storage = new MemoryStorage();
    storage.values.set(STORAGE_KEYS.homeIncludedAccounts, JSON.stringify(['ONE', 'TWO']));
    const preferences = new PlayerCardPreferencesService(storage);
    await preferences.load();
    expect(preferences.homeIncludedTags([], '#ONE')).toEqual([]);
    await preferences.reconcileHomeIncluded([], '#ONE');
    expect(storage.values.get(STORAGE_KEYS.homeIncludedAccounts)).toBe('["ONE","TWO"]');
    preferences.clear();
    expect(preferences.loaded).toBe(false);
    await preferences.load();
    expect(preferences.homeIncludedTags(six, '#ONE')).toEqual(['ONE', 'TWO']);
    expect(preferences.homeIncludedTags(['#OTHER'], '#OTHER')).toEqual(['OTHER']);
  });
});
