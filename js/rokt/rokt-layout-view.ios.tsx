import {
  requireNativeComponent,
  StyleSheet,
  NativeEventEmitter,
  NativeModules,
  ViewProps,
  NativeModule,
} from 'react-native';
import React, { Component } from 'react';
import { isFabricEnabled } from '../utils/architecture';
import RoktLayoutNativeComponent from '../codegenSpecs/rokt/RoktLayoutNativeComponent';

const RoktEventManager = NativeModules.RoktEventManager as NativeModule;

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

const eventManagerEmitter = new NativeEventEmitter(RoktEventManager);

export class RoktLayoutView extends Component<
  RoktLayoutViewProps,
  RoktLayoutViewState
> {
  subscription = eventManagerEmitter.addListener(
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
    flex: 1,
    backgroundColor: 'transparent',
    overflow: 'hidden',
  },
});

export default RoktLayoutView;
