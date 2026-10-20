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
 * Embedded placeholders for `selectPlacements`: the `placeholderName`s of `RoktLayoutView`s,
 * e.g. `['Location1']`.
 */
export type RoktPlaceholders = string[];

/**
 * The map of placeholder name to `findNodeHandle` react tag is no longer supported. A plain-JS
 * caller that still passes one gets an error log, and the placement is requested without
 * embedded views, instead of a platform-specific crash or conversion failure in native code.
 */
export function toNativePlaceholders(
  placeholders?: RoktPlaceholders
): string[] | undefined {
  if (placeholders == null || Array.isArray(placeholders)) {
    return placeholders;
  }
  console.error(
    '[mParticle] selectPlacements: placeholders must be an array of RoktLayoutView placeholderNames, ' +
      "e.g. ['Location1']. The map of name to findNodeHandle tag is no longer supported, so the " +
      'placement is requested without embedded views. See MIGRATING.md.'
  );
  return undefined;
}

/**
 * iOS New Architecture binds an omitted optional object param to a null C++ reference, which
 * crashes on first access. An empty config is treated by native exactly like no config.
 * Android takes a nullable `ReadableMap` and keeps receiving `undefined`: there `{}` would build a
 * default `RoktConfig`, whose `edgeToEdgeDisplay = true` turns on edge-to-edge overlays.
 */
export function toNativeRoktConfig(
  roktConfig?: IRoktConfig
): IRoktConfig | undefined {
  if (Platform.OS !== 'ios') {
    return roktConfig;
  }
  return roktConfig ?? {};
}

export abstract class Rokt {
  /**
   * Selects placements with a [identifier], [attributes], optional [placeholders], optional [roktConfig], and optional [fontFilePathMap].
   *
   * @param {string} identifier - The page identifier for the placement.
   * @param {Record<string, RoktAttributeValue>} attributes - Attributes to be associated with the placement.
   * @param {RoktPlaceholders} [placeholders] - Optional embedded placeholders: the `placeholderName`s of `RoktLayoutView`s, e.g. `['Location1']`. A named view does not need to be mounted yet: the SDK waits up to 2 seconds for it, so this can be called from the same `useEffect` that renders it.
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
      toNativeRoktConfig(roktConfig),
      fontFilesMap
    );
  }

  static async selectShoppableAds(
    identifier: string,
    attributes: Record<string, RoktAttributeValue>,
    roktConfig?: IRoktConfig
  ): Promise<void> {
    getMPRokt().selectShoppableAds(
      identifier,
      attributes,
      toNativeRoktConfig(roktConfig)
    );
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
