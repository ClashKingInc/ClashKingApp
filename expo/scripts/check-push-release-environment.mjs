import assert from 'node:assert/strict';
import { releaseEnvironment, RELEASE_TRACKS } from './release-environment.mjs';
import { pushEnvironment } from '../src/core/config/push-environment.js';

// Validate real release profiles with the runtime classifier. Merely comparing
// environment strings misses a production URL being labeled as sandbox.
for (const track of RELEASE_TRACKS) {
  const profile = releaseEnvironment(track);
  const actual = pushEnvironment(
    profile.EXPO_PUBLIC_CK_API_ENV,
    profile.EXPO_PUBLIC_CK_PUSH_API_V2_BASE_URL,
  );
  const expected = track === 'production' ? 'production' : 'sandbox';
  assert.equal(actual, expected, `${track} release would register the wrong push audience`);
  console.log(`${track}: push registration ${actual}`);
}
