import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { registerHooks } from 'node:module';
import { test } from 'node:test';
import { setImmediate } from 'node:timers/promises';
import ts from 'typescript';

// Exercise the real startup coordinator in Node with deterministic service responses.
registerHooks({
  load(url, context, nextLoad) {
    if (!url.startsWith('file:') || !url.endsWith('.ts')) return nextLoad(url, context);
    const source = ts.transpileModule(readFileSync(new URL(url), 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 },
    }).outputText;
    return { format: 'module', source, shortCircuit: true };
  },
  resolve(specifier, context, nextResolve) {
    if (specifier.startsWith('.') && context.parentURL) {
      const source = new URL(specifier + '.ts', context.parentURL);
      if (source.protocol === 'file:' && existsSync(source)) return nextResolve(source.href, context);
    }
    return nextResolve(specifier, context);
  },
});

const { initializeApplication, prepareLocalStartup } =
  await import('../src/core/app/startup-coordinator.ts');
const { UnauthorizedException } = await import('../src/core/api/contract-api.ts');

function createDependencies({ authenticated = true, verified = true } = {}) {
  return {
    preferenceMigration: { run: async () => {} },
    auth: {
      canUseApp: authenticated,
      state: { currentUser: authenticated ? { userId: 'player' } : null },
      initializeAuth: async () => {},
    },
    accounts: {
      hasVerifiedAccounts: verified,
      setCurrentUserId: () => {},
      loadSelectedTag: async () => {},
      fetchAccounts: async () => {},
    },
    appState: {
      getState: () => ({
        initializePreferences: async () => {},
        initialize: async () => {},
        isFeatureEnabled: () => false,
      }),
    },
    gameData: { loadGameData: async () => {} },
    push: { supportsPushNotifications: false },
  };
}

test('local startup preparation overlaps the update gate and is reused after release', async () => {
  const dependencies = createDependencies({ authenticated: false });
  const migration = Promise.withResolvers();
  const events = [];
  dependencies.preferenceMigration.run = () => {
    events.push('migration');
    return migration.promise;
  };
  const appState = dependencies.appState.getState();
  dependencies.appState.getState = () => appState;
  const preferences = Promise.withResolvers();
  appState.initializePreferences = () => {
    events.push('preferences');
    return preferences.promise;
  };
  appState.initialize = async () => { events.push('remote configuration'); };
  dependencies.gameData.loadGameData = async () => { events.push('game data'); };
  dependencies.auth.initializeAuth = async () => { events.push('auth'); };

  const preparedMigration = prepareLocalStartup(dependencies);
  assert.deepEqual(events, ['migration']);
  migration.resolve();
  await setImmediate();
  assert.deepEqual(events, ['migration', 'preferences']);

  const startup = initializeApplication({ ...dependencies, preparedMigration });
  await setImmediate();
  assert.ok(events.includes('auth'));
  assert.equal(events.filter((event) => event === 'migration').length, 1);
  preferences.resolve();
  assert.equal((await startup).destination, 'login');
});

test('login is usable with a game data request still pending', async () => {
  const dependencies = createDependencies({ authenticated: false });
  const gameData = Promise.withResolvers();
  dependencies.gameData.loadGameData = () => gameData.promise;
  dependencies.accounts.fetchAccounts = async () => assert.fail('accounts queried without a session');

  try {
    assert.equal((await initializeApplication(dependencies)).destination, 'login');
  } finally {
    gameData.resolve();
  }
}, { timeout: 1000 });

test('login waits for local preferences and does not wait for remote configuration', async () => {
  const dependencies = createDependencies({ authenticated: false });
  const preferences = Promise.withResolvers();
  const configuration = Promise.withResolvers();
  const appState = dependencies.appState.getState();
  dependencies.appState.getState = () => appState;
  appState.initializePreferences = () => preferences.promise;
  appState.initialize = () => configuration.promise;
  const startup = initializeApplication(dependencies);

  try {
    assert.equal(await Promise.race([startup, Promise.resolve('pending')]), 'pending');
    preferences.resolve();
    assert.equal((await startup).destination, 'login');
  } finally {
    preferences.resolve();
    configuration.resolve();
  }
}, { timeout: 1000 });

test('account verification overlaps game data and still waits for authentication', async () => {
  const dependencies = createDependencies();
  const authStarted = Promise.withResolvers();
  const auth = Promise.withResolvers();
  const gameData = Promise.withResolvers();
  const accountStarted = Promise.withResolvers();
  dependencies.auth.initializeAuth = () => {
    authStarted.resolve();
    return auth.promise;
  };
  dependencies.gameData.loadGameData = () => gameData.promise;
  dependencies.accounts.fetchAccounts = async () => accountStarted.resolve();
  let finished = false;
  const startup = initializeApplication(dependencies).then((result) => {
    finished = true;
    return result;
  });

  try {
    await authStarted.promise;
    assert.equal(
      await Promise.race([accountStarted.promise, Promise.resolve('pending')]),
      'pending',
    );
    auth.resolve();
    await accountStarted.promise;
    assert.equal(finished, false);
  } finally {
    auth.resolve();
    gameData.resolve();
  }
  assert.equal((await startup).destination, 'home');
}, { timeout: 1000 });

test('a session without a verified link still requires account setup', async () => {
  const result = await initializeApplication(createDependencies({ verified: false }));
  assert.equal(result.destination, 'account-setup');
});

test('an authenticated launch still waits for the remote app state', async () => {
  const dependencies = createDependencies();
  const configuration = Promise.withResolvers();
  const appState = dependencies.appState.getState();
  dependencies.appState.getState = () => appState;
  appState.initialize = () => configuration.promise;
  let finished = false;
  const startup = initializeApplication(dependencies).then((result) => {
    finished = true;
    return result;
  });

  try {
    await setImmediate();
    assert.equal(finished, false);
  } finally {
    configuration.resolve();
  }
  assert.equal((await startup).destination, 'home');
}, { timeout: 1000 });

test('a definitive session rejection still goes to login', async () => {
  const dependencies = createDependencies({ authenticated: false });
  dependencies.auth.initializeAuth = async () => {
    throw new UnauthorizedException();
  };
  assert.equal((await initializeApplication(dependencies)).destination, 'login');
});

test('an account outage still shows the startup error and can be retried', async () => {
  const dependencies = createDependencies();
  const failure = new Error('network timeout');
  dependencies.accounts.fetchAccounts = async () => {
    throw failure;
  };
  const result = await initializeApplication(dependencies);
  assert.equal(result.destination, 'error');
  assert.equal(result.failure, failure);
  assert.equal(result.networkError, true);

  dependencies.accounts.fetchAccounts = async () => {};
  assert.equal((await initializeApplication(dependencies)).destination, 'home');
});
