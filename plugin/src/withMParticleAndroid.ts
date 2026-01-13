import {
  ConfigPlugin,
  withMainApplication,
  withAppBuildGradle,
} from '@expo/config-plugins';
import { mergeContents } from '@expo/config-plugins/build/utils/generateCode';
import { MParticlePluginProps } from './withMParticle';

// Tag used for mergeContents to identify code blocks added by this plugin
const MPARTICLE_TAG = 'react-native-mparticle';

/**
 * Get the mParticle log level string for Android
 */
function getAndroidLogLevel(
  logLevel?: MParticlePluginProps['logLevel']
): string | null {
  switch (logLevel) {
    case 'none':
      return 'MParticle.LogLevel.NONE';
    case 'error':
      return 'MParticle.LogLevel.ERROR';
    case 'warning':
      return 'MParticle.LogLevel.WARNING';
    case 'debug':
      return 'MParticle.LogLevel.DEBUG';
    case 'verbose':
      return 'MParticle.LogLevel.VERBOSE';
    default:
      return null;
  }
}

/**
 * Get the mParticle environment string for Android
 */
function getAndroidEnvironment(
  environment?: MParticlePluginProps['environment']
): string | null {
  switch (environment) {
    case 'development':
      return 'MParticle.Environment.Development';
    case 'production':
      return 'MParticle.Environment.Production';
    case 'autoDetect':
      return 'MParticle.Environment.AutoDetect';
    default:
      return null;
  }
}

/**
 * Generate mParticle initialization code for Kotlin MainApplication
 */
function generateKotlinInitCode(props: MParticlePluginProps): string {
  const {
    androidApiKey,
    androidApiSecret,
    logLevel,
    environment,
    useEmptyIdentifyRequest = true,
    dataPlanId,
    dataPlanVersion,
  } = props;

  const lines: string[] = [
    '// mParticle SDK initialization',
    'val mParticleOptions = MParticleOptions.builder(this)',
    `    .credentials("${androidApiKey}", "${androidApiSecret}")`,
  ];

  const androidLogLevel = getAndroidLogLevel(logLevel);
  if (androidLogLevel) {
    lines.push(`    .logLevel(${androidLogLevel})`);
  }

  const androidEnvironment = getAndroidEnvironment(environment);
  if (androidEnvironment) {
    lines.push(`    .environment(${androidEnvironment})`);
  }

  if (dataPlanId) {
    const versionParam = dataPlanVersion ? `, ${dataPlanVersion}` : '';
    lines.push(`    .dataplan("${dataPlanId}"${versionParam})`);
  }

  if (useEmptyIdentifyRequest) {
    lines.push('    .identify(IdentityApiRequest.withEmptyUser().build())');
  }

  lines.push('    .build()');
  lines.push('MParticle.start(mParticleOptions)');

  return lines.join('\n    ');
}

/**
 * Generate mParticle initialization code for Java MainApplication
 */
function generateJavaInitCode(props: MParticlePluginProps): string {
  const {
    androidApiKey,
    androidApiSecret,
    logLevel,
    environment,
    useEmptyIdentifyRequest = true,
    dataPlanId,
    dataPlanVersion,
  } = props;

  const lines: string[] = [
    '// mParticle SDK initialization',
    'MParticleOptions.Builder optionsBuilder = MParticleOptions.builder(this)',
    `    .credentials("${androidApiKey}", "${androidApiSecret}")`,
  ];

  const androidLogLevel = getAndroidLogLevel(logLevel);
  if (androidLogLevel) {
    lines.push(`    .logLevel(${androidLogLevel})`);
  }

  const androidEnvironment = getAndroidEnvironment(environment);
  if (androidEnvironment) {
    lines.push(`    .environment(${androidEnvironment})`);
  }

  if (dataPlanId) {
    const versionParam = dataPlanVersion ? `, ${dataPlanVersion}` : '';
    lines.push(`    .dataplan("${dataPlanId}"${versionParam})`);
  }

  if (useEmptyIdentifyRequest) {
    lines.push('    .identify(IdentityApiRequest.withEmptyUser().build())');
  }

  // Java needs semicolons
  lines.push(';');
  lines.push('MParticle.start(optionsBuilder.build());');

  return lines.join('\n    ');
}

/**
 * Generate mParticle import statements for Kotlin
 */
function getKotlinImports(): string {
  return `import com.mparticle.MParticle
import com.mparticle.MParticleOptions
import com.mparticle.identity.IdentityApiRequest`;
}

/**
 * Generate mParticle import statements for Java
 */
function getJavaImports(): string {
  return `import com.mparticle.MParticle;
import com.mparticle.MParticleOptions;
import com.mparticle.identity.IdentityApiRequest;`;
}

/**
 * Add mParticle configuration to MainApplication
 * Handles both Kotlin and Java
 */
const withMParticleMainApplication: ConfigPlugin<MParticlePluginProps> = (
  config,
  props
) => {
  return withMainApplication(config, config => {
    const { contents, language } = config.modResults;

    // Check if mParticle is already initialized
    if (
      contents.includes('MParticleOptions') ||
      contents.includes('mParticleOptions')
    ) {
      return config;
    }

    const isKotlin = language === 'kt';

    if (isKotlin) {
      config.modResults.contents = addMParticleToKotlinMainApplication(
        contents,
        props
      );
    } else if (language === 'java') {
      config.modResults.contents = addMParticleToJavaMainApplication(
        contents,
        props
      );
    } else {
      console.warn(
        `[react-native-mparticle] Unsupported MainApplication language: ${language}. ` +
          'mParticle initialization must be added manually.'
      );
    }

    return config;
  });
};

/**
 * Add mParticle import and initialization to Kotlin MainApplication
 */
function addMParticleToKotlinMainApplication(
  contents: string,
  props: MParticlePluginProps
): string {
  // Add import statements using mergeContents
  const withImports = mergeContents({
    src: contents,
    newSrc: getKotlinImports(),
    anchor: /^package .+$/m,
    offset: 1, // Add after package declaration
    tag: `${MPARTICLE_TAG}-import`,
    comment: '//',
  });

  // Generate initialization code
  const initCode = generateKotlinInitCode(props);

  // Find the right place to add initialization code
  // Try ApplicationLifecycleDispatcher first (Expo pattern), then super.onCreate()
  let result = withImports.contents;

  if (
    result.includes('ApplicationLifecycleDispatcher.onApplicationCreate(this)')
  ) {
    const withInit = mergeContents({
      src: result,
      newSrc: `\n    ${initCode}\n`,
      anchor: /ApplicationLifecycleDispatcher\.onApplicationCreate\(this\)/,
      offset: 1, // Add after the anchor
      tag: `${MPARTICLE_TAG}-init`,
      comment: '//',
    });
    result = withInit.contents;
  } else if (result.includes('super.onCreate()')) {
    const withInit = mergeContents({
      src: result,
      newSrc: `\n    ${initCode}\n`,
      anchor: /super\.onCreate\(\)/,
      offset: 1, // Add after the anchor
      tag: `${MPARTICLE_TAG}-init`,
      comment: '//',
    });
    result = withInit.contents;
  }

  return result;
}

/**
 * Add mParticle import and initialization to Java MainApplication
 */
function addMParticleToJavaMainApplication(
  contents: string,
  props: MParticlePluginProps
): string {
  // Add import statements using mergeContents
  const withImports = mergeContents({
    src: contents,
    newSrc: getJavaImports(),
    anchor: /^package .+;$/m,
    offset: 1, // Add after package declaration
    tag: `${MPARTICLE_TAG}-import`,
    comment: '//',
  });

  // Generate initialization code
  const initCode = generateJavaInitCode(props);

  // Find the right place to add initialization code
  let result = withImports.contents;

  if (
    result.includes('ApplicationLifecycleDispatcher.onApplicationCreate(this);')
  ) {
    const withInit = mergeContents({
      src: result,
      newSrc: `\n    ${initCode}\n`,
      anchor: /ApplicationLifecycleDispatcher\.onApplicationCreate\(this\);/,
      offset: 1, // Add after the anchor
      tag: `${MPARTICLE_TAG}-init`,
      comment: '//',
    });
    result = withInit.contents;
  } else if (result.includes('super.onCreate();')) {
    const withInit = mergeContents({
      src: result,
      newSrc: `\n    ${initCode}\n`,
      anchor: /super\.onCreate\(\);/,
      offset: 1, // Add after the anchor
      tag: `${MPARTICLE_TAG}-init`,
      comment: '//',
    });
    result = withInit.contents;
  }

  return result;
}

/**
 * Add kit dependencies to app/build.gradle
 */
const withMParticleAppBuildGradle: ConfigPlugin<MParticlePluginProps> = (
  config,
  props
) => {
  return withAppBuildGradle(config, config => {
    const { contents } = config.modResults;

    if (!props.androidKits || props.androidKits.length === 0) {
      return config;
    }

    // Check if kits are already added
    const kitsAlreadyAdded = props.androidKits.every(kit =>
      contents.includes(`com.mparticle:${kit}`)
    );

    if (kitsAlreadyAdded) {
      return config;
    }

    // Generate kit dependency lines
    // Use + for version to auto-match core SDK version
    const kitDependencies = props.androidKits
      .map(kit => `    implementation "com.mparticle:${kit}:+"`)
      .join('\n');

    // Use mergeContents for idempotent injection
    const withKits = mergeContents({
      src: contents,
      newSrc: `\n    // mParticle kits\n${kitDependencies}`,
      anchor: /dependencies\s*\{/,
      offset: 1, // Add after the opening brace
      tag: `${MPARTICLE_TAG}-kits`,
      comment: '//',
    });

    config.modResults.contents = withKits.contents;
    return config;
  });
};

/**
 * Apply all Android-specific mParticle configurations
 */
export const withMParticleAndroid: ConfigPlugin<MParticlePluginProps> = (
  config,
  props
) => {
  config = withMParticleMainApplication(config, props);
  config = withMParticleAppBuildGradle(config, props);

  return config;
};
