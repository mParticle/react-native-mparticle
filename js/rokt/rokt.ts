import { NativeModules } from 'react-native';

export abstract class Rokt {
  /**
   * Selects placements with a [identifier], optional [attributes], optional [placeholders], optional [roktConfig], and optional [fontFilePathMap].
   *
   * @param {string} identifier - The page identifier for the placement.
   * @param {Record<string, string>} [attributes] - Optional attributes to be associated with the placement.
   * @param {Record<string, number | null>} [placeholders] - Optional placeholders for dynamic content.
   * @param {IRoktConfig} [roktConfig] - Optional configuration settings for Rokt.
   * @param {Record<string, string>} [fontFilesMap] - Optional mapping of font files.
   * @returns {Promise<void>} A promise that resolves when the placement request is sent.
   */
  static async selectPlacements(
    identifier: string,
    attributes: Record<string, string>,
    placeholders?: Record<string, number | null>,
    roktConfig?: IRoktConfig,
    fontFilesMap?: Record<string, string>
  ): Promise<void> {
    NativeModules.MPRokt.selectPlacements(
      identifier,
      attributes,
      placeholders,
      roktConfig,
      fontFilesMap
    );
  }
}

// Define the interface that matches the native module for cleaner code
export interface IRoktConfig {
  readonly colorMode?: ColorMode;
  readonly cacheConfig?: CacheConfig;
}

/**
 * Cache configuration for Rokt SDK
 */
export class CacheConfig {
  /**
   * @param cacheDurationInSeconds - The duration in seconds for which the Rokt SDK should cache the experience. Default is 90 minutes
   * @param cacheAttributes - optional attributes to be used as cache key. If null, all the attributes will be used as the cache key
   */
  constructor(
    public readonly cacheDurationInSeconds?: number,
    public readonly cacheAttributes?: Record<string, string>
  ) {}
}

class RoktConfig implements IRoktConfig {
  constructor(roktConfig: RoktConfig) {
    Object.assign(this, roktConfig);
  }
}

export class RoktConfigBuilder implements Partial<IRoktConfig> {
  readonly colorMode?: ColorMode;
  readonly cacheConfig?: CacheConfig;

  public withColorMode(
    value: ColorMode
  ): this & Pick<IRoktConfig, 'colorMode'> {
    return Object.assign(this, { colorMode: value });
  }

  public withCacheConfig(
    value: CacheConfig
  ): this & Pick<IRoktConfig, 'cacheConfig'> {
    return Object.assign(this, { cacheConfig: value });
  }

  public build(this: IRoktConfig) {
    return new RoktConfig(this);
  }
}

export type ColorMode = 'light' | 'dark' | 'system';
