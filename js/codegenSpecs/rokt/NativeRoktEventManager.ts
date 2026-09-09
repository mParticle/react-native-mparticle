import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

/**
 * Event channel for Rokt placement events.
 *
 * The native side is an `RCTEventEmitter`, which only conforms to `RCTBridgeModule`.
 * Under bridgeless that is not enough to be instantiated unless the host app has
 * opted into TurboModule interop, so this spec exists to register the emitter as a
 * TurboModule and keep `RoktEvents` reaching JS in every architecture.
 *
 * iOS only. Android delivers the same events over `RCTDeviceEventEmitter`, so this
 * module is absent there and `TurboModuleRegistry.get` returns null by design.
 */
export interface Spec extends TurboModule {
  addListener(eventName: string): void;
  removeListeners(count: number): void;
}

export default TurboModuleRegistry.get<Spec>('RoktEventManager');
