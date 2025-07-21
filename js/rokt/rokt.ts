import { NativeModules } from 'react-native';
import { getNativeModule } from '../utils/architecture';
import type { Spec as NativeMPRoktInterface } from '../codegenSpecs/rokt/NativeMPRokt';

const MPRokt = getNativeModule<NativeMPRoktInterface>('MPRokt', 'MPRokt');

export abstract class Rokt {
  /**
   * Selects placements with a [identifier], [attributes], optional [placeholders], optional [roktConfig], and optional [fontFilePathMap].
   *
   * @param {string} identifier - The page identifier for the placement.
   * @param {Record<string, string>} attributes - Attributes to be associated with the placement.
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
    MPRokt.selectPlacements(
      identifier,
      attributes,
      placeholders,
      roktConfig,
      fontFilesMap
    );
  }

  static createRoktConfig(colorMode?: ColorMode, cacheConfig?: CacheConfig) {
    return new RoktConfig(colorMode ?? 'system', cacheConfig);
  }

  static createCacheConfig(
    cacheDurationInSeconds: number,
    cacheAttributes: Record<string, string>
  ) {
    return new CacheConfig(cacheDurationInSeconds, cacheAttributes);
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
  public readonly colorMode: ColorMode;
  public readonly cacheConfig?: CacheConfig;

  constructor(colorMode: ColorMode, cacheConfig?: CacheConfig) {
    this.colorMode = colorMode;
    this.cacheConfig = cacheConfig;
  }
}
const { RoktEventManager } = NativeModules;

export { RoktEventManager };

export type ColorMode = 'light' | 'dark' | 'system';
