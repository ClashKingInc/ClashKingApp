import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { homedir } from 'node:os';
import path from 'node:path';

const require = createRequire(import.meta.url);
const cli = path.join(path.dirname(require.resolve('expo-device-hub/package.json')), 'dist/server/cli.mjs');
const environment = { ...process.env };
const androidSdk = environment.ANDROID_HOME || environment.ANDROID_SDK_ROOT
  || (process.platform === 'darwin' ? path.join(homedir(), 'Library', 'Android', 'sdk') : undefined);
// Device discovery resolves the SDK itself, but the streaming subprocess invokes
// adb by name. Keep both paths aligned without changing the user's shell setup.
if (androidSdk && existsSync(androidSdk)) {
  environment.ANDROID_HOME = androidSdk;
  environment.PATH = [path.join(androidSdk, 'platform-tools'), path.join(androidSdk, 'emulator'), environment.PATH]
    .filter(Boolean).join(path.delimiter);
}
const studioJava = '/Applications/Android Studio.app/Contents/jbr/Contents/Home';
// Android Studio bundles Java, but macOS shells do not automatically expose it.
// Use it only for this process; preserve any explicitly configured JAVA_HOME.
if (!environment.JAVA_HOME && process.platform === 'darwin' && existsSync(studioJava)) {
  environment.JAVA_HOME = studioJava;
}

// Metro is publicly tunneled. Keep device/host controls on a separate loopback
// listener, and do not forward flags that could enable network sharing.
const child = spawn(process.execPath, [cli, '--host', '127.0.0.1', '--port', '7358', '--disable-share'], {
  env: environment,
  stdio: 'inherit',
});
const stop = (signal) => child.kill(signal);
process.on('SIGINT', stop);
process.on('SIGTERM', stop);
child.on('error', (error) => {
  console.error(error.message);
  process.exitCode = 1;
});
child.on('exit', (code) => {
  process.removeListener('SIGINT', stop);
  process.removeListener('SIGTERM', stop);
  process.exitCode = code ?? 1;
});
