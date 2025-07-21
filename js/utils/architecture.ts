import { NativeModules, TurboModuleRegistry, TurboModule } from 'react-native';

declare const global: {
  __turboModuleProxy: unknown;
};

export const isNewArchitecture = global.__turboModuleProxy != null;

/**
 * Gets the native module for both old and new architectures
 * @param turboModuleName The name of the module in new architecture
 * @param legacyModuleName The name of the module in old architecture
 * @returns The native module
 */
export function getNativeModule<T extends TurboModule>(
  turboModuleName: string,
  legacyModuleName: string
): T {
  if (isNewArchitecture) {
    return TurboModuleRegistry.getEnforcing<T>(turboModuleName);
  }
  return NativeModules[legacyModuleName] as T;
}
