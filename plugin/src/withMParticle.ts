import { ConfigPlugin, createRunOncePlugin } from '@expo/config-plugins';
import { withMParticleIOS } from './withMParticleIOS';
import { withMParticleAndroid } from './withMParticleAndroid';

const pkg = require('../../package.json');

/**
 * A kit taken from Swift Package Manager that is not in `iosKits`' list of known kits
 */
export interface IosSpmKit {
  /** Package repository URL, e.g. `https://github.com/mparticle-integrations/mp-apple-integration-rokt` */
  url: string;
  /** Package product to link, e.g. `mParticle-Rokt` */
  product: string;
  /** Exact version; defaults to the core SDK version */
  version?: string;
}

/**
 * mParticle plugin configuration options
 */
export interface MParticlePluginProps {
  /**
   * iOS API key from mParticle dashboard
   */
  iosApiKey: string;

  /**
   * iOS API secret from mParticle dashboard
   */
  iosApiSecret: string;

  /**
   * Android API key from mParticle dashboard
   */
  androidApiKey: string;

  /**
   * Android API secret from mParticle dashboard
   */
  androidApiSecret: string;

  /**
   * Log level for debugging
   * @default 'none'
   */
  logLevel?: 'none' | 'error' | 'warning' | 'debug' | 'verbose';

  /**
   * mParticle environment
   * @default 'autoDetect'
   */
  environment?: 'development' | 'production' | 'autoDetect';

  /**
   * Data plan ID for validation
   */
  dataPlanId?: string;

  /**
   * Data plan version for validation
   */
  dataPlanVersion?: number;

  /**
   * iOS kits, by CocoaPods name. With Swift Package Manager (the default), each must be one of the
   * kits in `ios/mparticle_spm_kits.json`; list any other kit in `iosSpmKits`.
   * @example ['mParticle-Rokt', 'mParticle-Braze-14']
   */
  iosKits?: string[];

  /**
   * Where the iOS mParticle SDK and kits come from.
   * - `'spm'`: Swift packages linked into the app target (README › Swift Package Manager).
   * - `'cocoapods'`: pods. Deprecated: CocoaPods trunk becomes read-only on 2 December 2026.
   * @default 'spm'
   */
  iosDependencyManager?: 'cocoapods' | 'spm';

  /**
   * With Swift Package Manager, the exact mParticle core SDK version, also used for kits without a
   * version.
   * @default the version this release of react-native-mparticle was tested with
   */
  iosSdkVersion?: string;

  /**
   * With Swift Package Manager, kits that `iosKits` does not know, as Swift packages.
   * @example [{ url: 'https://github.com/mparticle-integrations/mp-apple-integration-rokt', product: 'mParticle-Rokt' }]
   */
  iosSpmKits?: IosSpmKit[];

  /**
   * Custom base URL for global CNAME setup.
   * This is applied before mParticle starts on iOS and Android.
   * @example 'https://your-cname.example.com'
   */
  customBaseUrl?: string;

  /**
   * When true, disables SSL certificate pinning for mParticle network traffic.
   *
   * - **iOS:** Sets `MPNetworkOptions.pinningDisabled` before startup.
   * - **Android:** Sets `NetworkOptions.Builder.setPinningDisabledInDevelopment(true)`
   *   (mParticle's Android API for proxy/debug builds; see Android SDK docs).
   */
  pinningDisabled?: boolean;

  /**
   * Android kit artifact names to include (version auto-detected from core SDK)
   * @example ['android-rokt-kit', 'android-amplitude-kit']
   */
  androidKits?: string[];

  /**
   * Whether to use an empty identify request at initialization
   * If true or omitted, uses requestWithEmptyUser/withEmptyUser()
   * If false, no identify request is made at initialization
   * Identity should be updated from React Native code after initialization
   * @default true
   */
  useEmptyIdentifyRequest?: boolean;
}

/**
 * Expo Config Plugin for mParticle React Native SDK
 *
 * This plugin configures your Expo project to use the mParticle SDK by:
 * - Adding mParticle SDK initialization to iOS AppDelegate
 * - Adding mParticle SDK initialization to Android MainApplication
 * - Adding kit dependencies to iOS Podfile
 * - Adding kit dependencies to Android build.gradle
 */
const withMParticle: ConfigPlugin<MParticlePluginProps> = (config, props) => {
  // Validate required props
  if (!props.iosApiKey || !props.iosApiSecret) {
    throw new Error(
      'react-native-mparticle plugin requires iosApiKey and iosApiSecret'
    );
  }
  if (!props.androidApiKey || !props.androidApiSecret) {
    throw new Error(
      'react-native-mparticle plugin requires androidApiKey and androidApiSecret'
    );
  }

  // Apply iOS modifications
  config = withMParticleIOS(config, props);

  // Apply Android modifications
  config = withMParticleAndroid(config, props);

  return config;
};

export default createRunOncePlugin(withMParticle, pkg.name, pkg.version);
