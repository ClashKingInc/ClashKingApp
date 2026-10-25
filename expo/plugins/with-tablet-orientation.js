'use strict';

const { withMainActivity } = require('expo/config-plugins');

/** Keep the phone launch manifest portrait; unlock tablets before React starts. */
module.exports = function withTabletOrientation(config) {
  return withMainActivity(config, (mod) => {
    const marker = '// ClashKing tablet orientation';
    if (mod.modResults.contents.includes(marker)) return mod;
    if (mod.modResults.language !== 'kt') {
      throw new Error('ClashKing tablet orientation requires the Kotlin MainActivity template.');
    }
    const anchor = /super\.onCreate\((?:null|savedInstanceState)\)/;
    if (!anchor.test(mod.modResults.contents)) {
      throw new Error('MainActivity onCreate anchor missing; tablet rotation was not configured.');
    }
    mod.modResults.contents = mod.modResults.contents.replace(
      anchor,
      `${marker}
    // Width class is orientation-independent. Phones retain the manifest lock.
    // FULL_USER respects the tablet owner's rotation lock instead of forcing sensors.
    if (resources.configuration.smallestScreenWidthDp >= 600) {
      requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_FULL_USER
    }
    $&`,
    );
    return mod;
  });
};
