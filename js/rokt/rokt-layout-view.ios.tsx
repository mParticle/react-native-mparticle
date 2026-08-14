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

function getEventManagerEmitter(): NativeEventEmitter {
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
