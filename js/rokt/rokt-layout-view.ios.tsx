import {
  requireNativeComponent,
  StyleSheet,
  NativeEventEmitter,
  ViewProps,
  NativeModule,
} from 'react-native';
import React, { Component } from 'react';
import { isFabricEnabled } from '../utils/architecture';
import RoktLayoutNativeComponent from '../codegenSpecs/rokt/RoktLayoutNativeComponent';
import { RoktEventManager } from './rokt-event-manager';

export interface HeightChangedEvent extends Event {
  height: string;
}

export interface WidgetChangeEvent {
  selectedPlacement: string;
  height: string;
}

export interface RoktLayoutViewProps {
  placeholderName: string;
}

export interface RoktLayoutViewState {
  height: number;
  placeholderName: string;
}

// Define the native component props interface
interface RoktNativeLayoutProps extends ViewProps {
  placeholderName?: string;
  onLayoutHeightChanged?: (event: HeightChangedEvent) => void;
}

// Use the appropriate component based on architecture
const LayoutNativeComponent = (
  isFabricEnabled
    ? RoktLayoutNativeComponent
    : requireNativeComponent<RoktNativeLayoutProps>('RoktLegacyLayout')
) as any;

// Built on first use rather than at module scope: constructing a NativeEventEmitter with a
// missing native module throws on iOS, which would take down the bundle at import time
// instead of degrading to a placement that never resizes.
let eventManagerEmitter: NativeEventEmitter | undefined;

// A subscription-shaped stand-in for when `RoktEventManager` is unavailable. Height
// updates never arrive, but nothing downstream has to know the difference.
interface NoopSubscription {
  remove(): void;
}
interface NoopEventEmitter {
  addListener(
    eventType: string,
    listener: (widgetChanges: WidgetChangeEvent) => void
  ): NoopSubscription;
}
const noopSubscription: NoopSubscription = {
  // eslint-disable-next-line @typescript-eslint/no-empty-function
  remove: () => {},
};
const noopEventEmitter: NoopEventEmitter = {
  addListener: () => noopSubscription,
};

/**
 * `RoktEventManager` resolves to `null` when neither the TurboModule registry nor
 * `NativeModules` has it -- e.g. bridgeless with TurboModule interop disabled and no
 * old-architecture fallback registered. RN's `NativeEventEmitter` constructor throws
 * an invariant on iOS in that case (`` `new NativeEventEmitter()` requires a non-null
 * argument ``), which would crash every screen that mounts a `RoktLayoutView` instead
 * of just leaving that one placement un-resizable. Guard it here and hand back a
 * no-op emitter so the view still renders; it just never receives
 * `LayoutHeightChanges`.
 */
let warnedMissingModule = false;
function getEventManagerEmitter(): NativeEventEmitter | NoopEventEmitter {
  if (!RoktEventManager) {
    if (!warnedMissingModule) {
      warnedMissingModule = true;
      console.warn(
        '[ROKT] RoktEventManager native module is unavailable; RoktLayoutView will not receive Rokt events (including height updates).'
      );
    }
    return noopEventEmitter;
  }
  if (!eventManagerEmitter) {
    eventManagerEmitter = new NativeEventEmitter(
      RoktEventManager as NativeModule
    );
  }
  return eventManagerEmitter;
}

export class RoktLayoutView extends Component<
  RoktLayoutViewProps,
  RoktLayoutViewState
> {
  subscription = getEventManagerEmitter().addListener(
    'LayoutHeightChanges',
    (widgetChanges: WidgetChangeEvent) => {
      if (widgetChanges.selectedPlacement == this.state.placeholderName) {
        this.setState({ height: parseInt(widgetChanges.height) });
      }
    }
  );

  constructor(props: RoktLayoutViewProps) {
    super(props);

    this.state = {
      height: 0,
      placeholderName: this.props.placeholderName,
    };
  }

  override render() {
    return (
      <LayoutNativeComponent
        style={[styles.widget, { height: this.state.height }]}
        placeholderName={this.state.placeholderName}
        onLayoutHeightChanged={(event: HeightChangedEvent) => {
          if (event.height) {
            this.setState({ height: parseInt(event.height) });
          }
        }}
      />
    );
  }

  override componentWillUnmount() {
    this.subscription.remove();
  }
}

const styles = StyleSheet.create({
  widget: {
    // Do NOT use `flex: 1` here. It expands to `flexBasis: 0%`, which takes
    // precedence over `height` on the parent's main axis, so inside any
    // auto-height column parent the layout collapses to 0 and the placement is
    // never visible even though it was selected and reported its height.
    // `alignSelf: 'stretch'` gives the full available width without touching the
    // main axis, leaving the measured `height` free to apply.
    alignSelf: 'stretch',
    backgroundColor: 'transparent',
    overflow: 'hidden',
  },
});

export default RoktLayoutView;
