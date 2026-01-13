import { ConfigPlugin, createRunOncePlugin } from '@expo/config-plugins';
import { withMParticleIOS } from './withMParticleIOS';
import { withMParticleAndroid } from './withMParticleAndroid';

const pkg = require('../../package.json');

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
   * iOS kit pod names to include
   * @example ['mParticle-Rokt', 'mParticle-Amplitude']
   */
  iosKits?: string[];

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
