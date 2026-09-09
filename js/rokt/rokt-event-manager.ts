import { NativeModules, TurboModuleRegistry } from 'react-native';

const ROKT_EVENT_MANAGER_MODULE_NAME = 'RoktEventManager';

/**
 * The native emitter that carries `RoktEvents` and `LayoutHeightChanges` to JS.
 *
 * Resolved through the TurboModule registry first: the native class is an
 * `RCTEventEmitter`, and under bridgeless those are only instantiated when the host app
 * has enabled TurboModule interop. Registering it via codegen makes it resolvable either
 * way; without this the module is undefined and every Rokt event is dropped silently.
 *
 * Falls back to `NativeModules` for the old architecture, and is null on Android, where
 * the same events arrive over `RCTDeviceEventEmitter` and `NativeEventEmitter` accepts a
 * null module.
 */
export const RoktEventManager =
  TurboModuleRegistry.get(ROKT_EVENT_MANAGER_MODULE_NAME) ??
  NativeModules[ROKT_EVENT_MANAGER_MODULE_NAME] ??
  null;
