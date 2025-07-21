import { NativeModules, TurboModuleRegistry, TurboModule } from 'react-native';

declare const global: {
  __turboModuleProxy: unknown;
};

export const isNewArchitecture = global.__turboModuleProxy != null;

/**
 * Gets the native module for both old and new architectures
 * @param moduleName The name of the module
 * @returns The native module
 */
export function getNativeModule<T extends TurboModule>(moduleName: string): T {
  if (isNewArchitecture) {
    return TurboModuleRegistry.getEnforcing<T>(moduleName);
  }
  return NativeModules[moduleName] as T;
}
