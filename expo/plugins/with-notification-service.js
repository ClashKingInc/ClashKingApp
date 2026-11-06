const fs = require('node:fs');
const path = require('node:path');
const { withDangerousMod, withXcodeProject } = require('expo/config-plugins');
const {
  findTargetByName,
  configureWidgetEmbedding,
  attachFileReferencesToGroup,
} = require('./with-clashking-native');

module.exports = function withNotificationService(config) {
  const name = 'NotificationService';
  const bundle = `${config.ios.bundleIdentifier}.notificationservice`;
  const version = config.version;
  const build = config.ios.buildNumber;
  const team = config.ios.appleTeamId;
  config = withDangerousMod(config, [
    'ios',
    async (mod) => {
      fs.cpSync(
        path.join(mod.modRequest.projectRoot, 'native/ios', name),
        path.join(mod.modRequest.platformProjectRoot, name),
        { recursive: true },
      );
      return mod;
    },
  ]);
  return withXcodeProject(config, (mod) => {
    const project = mod.modResults;
    let entry = findTargetByName(project, name);
    if (!entry) {
      const added = project.addTarget(name, 'app_extension', name, bundle);
      project.addBuildPhase(
        [`${name}/NotificationService.swift`],
        'PBXSourcesBuildPhase',
        'Sources',
        added.uuid,
        'app_extension',
      );
      project.addBuildPhase([], 'PBXResourcesBuildPhase', 'Resources', added.uuid, 'app_extension');
      project.addBuildPhase(
        [],
        'PBXFrameworksBuildPhase',
        'Frameworks',
        added.uuid,
        'app_extension',
      );
      attachFileReferencesToGroup(
        project,
        [`${name}/NotificationService.swift`],
        project.getFirstProject().firstProject.mainGroup,
      );
      entry = findTargetByName(project, name);
    }
    const [uuid, target] = entry;
    const list = project.pbxXCConfigurationList()[target.buildConfigurationList];
    for (const { value } of list.buildConfigurations) {
      Object.assign(project.pbxXCBuildConfigurationSection()[value].buildSettings, {
        APPLICATION_EXTENSION_API_ONLY: 'YES',
        CODE_SIGN_STYLE: 'Automatic',
        DEVELOPMENT_TEAM: team,
        GENERATE_INFOPLIST_FILE: 'NO',
        INFOPLIST_FILE: `"${name}/Info.plist"`,
        IPHONEOS_DEPLOYMENT_TARGET: '17.0',
        CURRENT_PROJECT_VERSION: `"${build}"`,
        MARKETING_VERSION: `"${version}"`,
        PRODUCT_BUNDLE_IDENTIFIER: `"${bundle}"`,
        PRODUCT_NAME: '"$(TARGET_NAME)"',
        SKIP_INSTALL: 'YES',
        SWIFT_VERSION: '5.0',
        TARGETED_DEVICE_FAMILY: '"1,2"',
      });
    }
    configureWidgetEmbedding(project, uuid, target);
    return mod;
  });
};
