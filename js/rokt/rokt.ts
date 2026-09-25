import { NativeModules, Platform, TurboModuleRegistry } from 'react-native';
import { getNativeModule, isNewArchitecture } from '../utils/architecture';
import type { Spec as NativeMPRoktInterface } from '../codegenSpecs/rokt/NativeMPRokt';
import { RoktEventManager } from './rokt-event-manager';

const ROKT_MODULE_NAME = 'RNMPRokt';
const MPRokt =
  Platform.OS === 'android'
    ? getAndroidRoktModule()
    : getNativeModule<NativeMPRoktInterface>(ROKT_MODULE_NAME);

function getAndroidRoktModule(): NativeMPRoktInterface | null {
  if (isNewArchitecture) {
    return TurboModuleRegistry.get<NativeMPRoktInterface>(ROKT_MODULE_NAME);
  }
  return (
    (NativeModules[ROKT_MODULE_NAME] as NativeMPRoktInterface | undefined) ??
    null
  );
}

function getMPRokt(): NativeMPRoktInterface {
  if (MPRokt != null) {
    return MPRokt;
  }

  throw new Error(
    `${ROKT_MODULE_NAME} is unavailable. Add the native mParticle Rokt kit before using MParticle.Rokt APIs.`
  );
}

export type RoktAttributeValue = string | number | boolean;

/**
 * Embedded placeholders for `selectPlacements`.
 *
 * Preferred: the `placeholderName`s of `RoktLayoutView`s, e.g. `['Location1']`.
 * Legacy: a map of placeholder name to `findNodeHandle(ref)` react tag. Still supported.
 */
export type RoktPlaceholders = string[] | Record<string, number | null>;

/**
 * Converts the public placeholder forms to the native spec's map shape. React tags are
 * positive, so zero is an explicit request to resolve the view by its `placeholderName`.
 * A numeric sentinel is required because React Native codegen drops null-valued map entries.
 */
export function toNativePlaceholders(
  placeholders?: RoktPlaceholders
): Record<string, number> | undefined {
  if (placeholders == null) {
    return undefined;
  }

  const entries: ReadonlyArray<readonly [string, number | null]> =
    Array.isArray(placeholders)
      ? placeholders.map(name => [name, null] as const)
      : Object.entries(placeholders);

  return entries.reduce<Record<string, number>>((map, [name, reactTag]) => {
    map[name] = reactTag ?? 0;
    return map;
  }, {});
}

export abstract class Rokt {
  /**
   * Selects placements with a [identifier], [attributes], optional [placeholders], optional [roktConfig], and optional [fontFilePathMap].
   *
   * @param {string} identifier - The page identifier for the placement.
   * @param {Record<string, RoktAttributeValue>} attributes - Attributes to be associated with the placement.
   * @param {RoktPlaceholders} [placeholders] - Optional embedded placeholders: `placeholderName`s of `RoktLayoutView`s (preferred), or a legacy map of name to react tag. A named view does not need to be mounted yet: the SDK waits up to 2 seconds for it, so this can be called from the same `useEffect` that renders it.
   * @param {IRoktConfig} [roktConfig] - Optional configuration settings for Rokt.
   * @param {Record<string, string>} [fontFilesMap] - Optional mapping of font files.
   * @returns {Promise<void>} A promise that resolves when the placement request is sent.
   */
  static async selectPlacements(
    identifier: string,
    attributes: Record<string, RoktAttributeValue>,
    placeholders?: RoktPlaceholders,
    roktConfig?: IRoktConfig,
    fontFilesMap?: Record<string, string>
  ): Promise<void> {
    getMPRokt().selectPlacements(
      identifier,
      attributes,
      toNativePlaceholders(placeholders),
      roktConfig,
      fontFilesMap
    );
  }

  static async selectShoppableAds(
    identifier: string,
    attributes: Record<string, RoktAttributeValue>,
    roktConfig?: IRoktConfig
  ): Promise<void> {
    getMPRokt().selectShoppableAds(identifier, attributes, roktConfig);
  }

  static async purchaseFinalized(
    placementId: string,
    catalogItemId: string,
    success: boolean
  ): Promise<void> {
    getMPRokt().purchaseFinalized(placementId, catalogItemId, success);
  }

  static async close(): Promise<void> {
    return getMPRokt().close();
  }

  static async setSessionId(sessionId: string): Promise<void> {
    return getMPRokt().setSessionId(sessionId);
  }

  static async getSessionId(): Promise<string | null> {
    return getMPRokt().getSessionId();
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
export { RoktEventManager };

export type ColorMode = 'light' | 'dark' | 'system';
