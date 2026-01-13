import {
  ConfigPlugin,
  withAppDelegate,
  withDangerousMod,
} from '@expo/config-plugins';
import { mergeContents } from '@expo/config-plugins/build/utils/generateCode';
import { MParticlePluginProps } from './withMParticle';
import * as fs from 'fs';
import * as path from 'path';

// Tag used for mergeContents to identify code blocks added by this plugin
const MPARTICLE_TAG = 'react-native-mparticle';

/**
 * Get the mParticle log level for iOS (Swift syntax)
 */
function getSwiftLogLevel(
  logLevel?: MParticlePluginProps['logLevel']
): string | null {
  switch (logLevel) {
    case 'none':
      return '.none';
    case 'error':
      return '.error';
    case 'warning':
      return '.warning';
    case 'debug':
      return '.debug';
    case 'verbose':
      return '.verbose';
    default:
      return null;
  }
}

/**
 * Get the mParticle environment for iOS (Swift syntax)
 */
function getSwiftEnvironment(
  environment?: MParticlePluginProps['environment']
): string | null {
  switch (environment) {
    case 'development':
      return '.development';
    case 'production':
      return '.production';
    case 'autoDetect':
      return '.autoDetect';
    default:
      return null;
  }
}

/**
 * Get the mParticle log level for iOS (Objective-C syntax)
 */
function getObjcLogLevel(
  logLevel?: MParticlePluginProps['logLevel']
): string | null {
  switch (logLevel) {
    case 'none':
      return 'MPILogLevelNone';
    case 'error':
      return 'MPILogLevelError';
    case 'warning':
      return 'MPILogLevelWarning';
    case 'debug':
      return 'MPILogLevelDebug';
    case 'verbose':
      return 'MPILogLevelVerbose';
    default:
      return null;
  }
}

/**
 * Get the mParticle environment for iOS (Objective-C syntax)
 */
function getObjcEnvironment(
  environment?: MParticlePluginProps['environment']
): string | null {
  switch (environment) {
    case 'development':
      return 'MPEnvironmentDevelopment';
    case 'production':
      return 'MPEnvironmentProduction';
    case 'autoDetect':
      return 'MPEnvironmentAutoDetect';
    default:
      return null;
  }
}

/**
 * Generate mParticle initialization code for Swift AppDelegate
 */
function generateSwiftInitCode(props: MParticlePluginProps): string {
  const {
    iosApiKey,
    iosApiSecret,
    logLevel,
    environment,
    useEmptyIdentifyRequest = true,
    dataPlanId,
    dataPlanVersion,
  } = props;

  const lines: string[] = [
    '// mParticle SDK initialization',
    `let mParticleOptions = MParticleOptions(key: "${iosApiKey}", secret: "${iosApiSecret}")`,
  ];

  const swiftLogLevel = getSwiftLogLevel(logLevel);
  if (swiftLogLevel) {
    lines.push(`mParticleOptions.logLevel = ${swiftLogLevel}`);
  }

  const swiftEnvironment = getSwiftEnvironment(environment);
  if (swiftEnvironment) {
    lines.push(`mParticleOptions.environment = ${swiftEnvironment}`);
  }

  if (dataPlanId) {
    lines.push(`mParticleOptions.dataPlanId = "${dataPlanId}"`);
    if (dataPlanVersion) {
      lines.push(
        `mParticleOptions.dataPlanVersion = ${dataPlanVersion} as NSNumber`
      );
    }
  }

  if (useEmptyIdentifyRequest) {
    lines.push('let identifyRequest = MPIdentityApiRequest.withEmptyUser()');
    lines.push('mParticleOptions.identifyRequest = identifyRequest');
  }

  lines.push('MParticle.sharedInstance().start(with: mParticleOptions)');

  return lines.join('\n    ');
}

/**
 * Generate mParticle initialization code for Objective-C AppDelegate
 */
function generateObjcInitCode(props: MParticlePluginProps): string {
  const {
    iosApiKey,
    iosApiSecret,
    logLevel,
    environment,
    useEmptyIdentifyRequest = true,
    dataPlanId,
    dataPlanVersion,
  } = props;

  const lines: string[] = [
    '// mParticle SDK initialization',
    `MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:@"${iosApiKey}"`,
    `                                                               secret:@"${iosApiSecret}"];`,
  ];

  const objcLogLevel = getObjcLogLevel(logLevel);
  if (objcLogLevel) {
    lines.push(`mParticleOptions.logLevel = ${objcLogLevel};`);
  }

  const objcEnvironment = getObjcEnvironment(environment);
  if (objcEnvironment) {
    lines.push(`mParticleOptions.environment = ${objcEnvironment};`);
  }

  if (dataPlanId) {
    lines.push(`mParticleOptions.dataPlanId = @"${dataPlanId}";`);
    if (dataPlanVersion) {
      lines.push(`mParticleOptions.dataPlanVersion = @(${dataPlanVersion});`);
    }
  }

  if (useEmptyIdentifyRequest) {
    lines.push(
      'MPIdentityApiRequest *identifyRequest = [MPIdentityApiRequest requestWithEmptyUser];'
    );
    lines.push('mParticleOptions.identifyRequest = identifyRequest;');
  }

  lines.push('[[MParticle sharedInstance] startWithOptions:mParticleOptions];');

  return lines.join('\n  ');
}

/**
 * Add mParticle configuration to AppDelegate
 * Handles both Swift and Objective-C/Objective-C++
 */
const withMParticleAppDelegate: ConfigPlugin<MParticlePluginProps> = (
  config,
  props
) => {
  return withAppDelegate(config, config => {
    const { contents, language } = config.modResults;

    // Check if mParticle is already initialized
    if (
      contents.includes('MParticleOptions') ||
      contents.includes('mParticleOptions')
    ) {
      return config;
    }

    if (language === 'swift') {
      config.modResults.contents = addMParticleToSwiftAppDelegate(
        contents,
        props
      );
    } else if (language === 'objc' || language === 'objcpp') {
      config.modResults.contents = addMParticleToObjcAppDelegate(
        contents,
        props
      );
    } else {
      console.warn(
        `[react-native-mparticle] Unsupported AppDelegate language: ${language}. ` +
          'mParticle initialization must be added manually.'
      );
    }

    return config;
  });
};

/**
 * Add mParticle import and initialization to Swift AppDelegate
 */
function addMParticleToSwiftAppDelegate(
  contents: string,
  props: MParticlePluginProps
): string {
  // Add import statement
  // Use mergeContents for safe, idempotent code injection
  const withImport = mergeContents({
    src: contents,
    newSrc: 'import mParticle_Apple_SDK',
    anchor: /import Expo/,
    offset: 1, // Add after the anchor
    tag: `${MPARTICLE_TAG}-import`,
    comment: '//',
  });

  // Generate initialization code
  const initCode = generateSwiftInitCode(props);

  // Find the right place to add initialization code
  // For Expo SDK 53+, it should be in didFinishLaunchingWithOptions before the return
  // Look for the return super.application pattern
  const withInit = mergeContents({
    src: withImport.contents,
    newSrc: `\n    ${initCode}\n`,
    anchor:
      /return super\.application\(application, didFinishLaunchingWithOptions: launchOptions\)/,
    offset: 0, // Add before the anchor
    tag: `${MPARTICLE_TAG}-init`,
    comment: '//',
  });

  return withInit.contents;
}

/**
 * Add mParticle import and initialization to Objective-C AppDelegate
 */
function addMParticleToObjcAppDelegate(
  contents: string,
  props: MParticlePluginProps
): string {
  // Add import statement after React import or first import
  const withImport = mergeContents({
    src: contents,
    newSrc: '#import "mParticle.h"',
    anchor: /#import <React\/RCTBundleURLProvider\.h>|#import "AppDelegate\.h"/,
    offset: 1, // Add after the anchor
    tag: `${MPARTICLE_TAG}-import`,
    comment: '//',
  });

  // Generate initialization code
  const initCode = generateObjcInitCode(props);

  // Try different patterns for where to insert the init code
  let result = withImport.contents;

  // Pattern 1: Expo's return [super application...
  if (
    result.includes(
      'return [super application:application didFinishLaunchingWithOptions:launchOptions];'
    )
  ) {
    const withInit = mergeContents({
      src: result,
      newSrc: `\n  ${initCode}\n`,
      anchor:
        /return \[super application:application didFinishLaunchingWithOptions:launchOptions\];/,
      offset: 0,
      tag: `${MPARTICLE_TAG}-init`,
      comment: '//',
    });
    result = withInit.contents;
  }
  // Pattern 2: self.initialProps = @{};
  else if (result.includes('self.initialProps = @{};')) {
    const withInit = mergeContents({
      src: result,
      newSrc: `\n  ${initCode}\n`,
      anchor: /self\.initialProps = @\{\};/,
      offset: 1,
      tag: `${MPARTICLE_TAG}-init`,
      comment: '//',
    });
    result = withInit.contents;
  }
  // Pattern 3: return YES;
  else if (result.includes('return YES;')) {
    const withInit = mergeContents({
      src: result,
      newSrc: `\n  ${initCode}\n`,
      anchor: /return YES;/,
      offset: 0,
      tag: `${MPARTICLE_TAG}-init`,
      comment: '//',
    });
    result = withInit.contents;
  }

  return result;
}

/**
 * Known transitive dependencies that need dynamic linking for each kit
 * These are dependencies of mParticle kits that must also be dynamic frameworks
 */
const KIT_TRANSITIVE_DEPENDENCIES: Record<string, string[]> = {
  'mParticle-Rokt': ['Rokt-Widget'],
  // Add other kit dependencies here as needed
  // "mParticle-Amplitude": [],
  // "mParticle-Braze": [],
};

/**
 * Get all pods that need dynamic framework linking
 */
function getDynamicFrameworkPods(iosKits?: string[]): string[] {
  const pods = ['mParticle-Apple-SDK'];

  if (iosKits) {
    for (const kit of iosKits) {
      pods.push(kit);
      // Add transitive dependencies for this kit
      const transitiveDeps = KIT_TRANSITIVE_DEPENDENCIES[kit];
      if (transitiveDeps) {
        pods.push(...transitiveDeps);
      }
    }
  }

  return [...new Set(pods)]; // Remove duplicates
}

/**
 * Add kit pods and pre_install hook to Podfile
 */
const withMParticlePodfile: ConfigPlugin<MParticlePluginProps> = (
  config,
  props
) => {
  return withDangerousMod(config, [
    'ios',
    async config => {
      const podfilePath = path.join(
        config.modRequest.platformProjectRoot,
        'Podfile'
      );

      if (!fs.existsSync(podfilePath)) {
        return config;
      }

      let podfileContent = fs.readFileSync(podfilePath, 'utf-8');

      // Add pre_install hook for dynamic framework linking if not already present
      if (!podfileContent.includes('mParticle-Apple-SDK')) {
        // Get all pods that need dynamic linking (including transitive dependencies)
        const dynamicPods = getDynamicFrameworkPods(props.iosKits);
        const podConditions = dynamicPods
          .map(pod => `pod.name == '${pod}'`)
          .join(' || ');

        const preInstallHook = `
# mParticle dynamic framework linking (added by react-native-mparticle expo plugin)
pre_install do |installer|
  installer.pod_targets.each do |pod|
    if ${podConditions}
      def pod.build_type;
        Pod::BuildType.new(:linkage => :dynamic, :packaging => :framework)
      end
    end
  end
end
`;

        // Add pre_install hook after platform declaration
        const platformRegex = /platform :ios.*\n/;
        if (platformRegex.test(podfileContent)) {
          podfileContent = podfileContent.replace(
            platformRegex,
            `$&${preInstallHook}`
          );
        }
      }

      // Add kit pods if specified
      if (props.iosKits && props.iosKits.length > 0) {
        const kitPods = props.iosKits.map(kit => `  pod '${kit}'`).join('\n');

        // Check if kits are already added
        const kitsAlreadyAdded = props.iosKits.every(kit =>
          podfileContent.includes(`pod '${kit}'`)
        );

        if (!kitsAlreadyAdded) {
          // Add kit pods inside the main target block
          // Look for use_react_native! and add after it
          const useReactNativeRegex = /(use_react_native!\([^)]*\))/s;
          if (useReactNativeRegex.test(podfileContent)) {
            podfileContent = podfileContent.replace(
              useReactNativeRegex,
              `$1\n\n  # mParticle kits (added by react-native-mparticle expo plugin)\n${kitPods}`
            );
          }
        }
      }

      fs.writeFileSync(podfilePath, podfileContent);

      return config;
    },
  ]);
};

/**
 * Apply all iOS-specific mParticle configurations
 */
export const withMParticleIOS: ConfigPlugin<MParticlePluginProps> = (
  config,
  props
) => {
  config = withMParticleAppDelegate(config, props);
  config = withMParticlePodfile(config, props);

  return config;
};
