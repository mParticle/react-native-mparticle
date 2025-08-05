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

export interface MarginChangedEvent extends Event {
  marginTop: string;
  marginRight: string;
  marginLeft: string;
  marginBottom: string;
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
  marginTop: number;
  marginRight: number;
  marginLeft: number;
  marginBottom: number;
}

// Define the native component props interface
interface RoktNativeLayoutProps extends ViewProps {
  placeholderName?: string;
  onLayoutHeightChanged?: (event: HeightChangedEvent) => void;
  onLayoutMarginChanged?: (event: MarginChangedEvent) => void;
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
      marginTop: 0,
      marginRight: 0,
      marginLeft: 0,
      marginBottom: 0,
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
        onLayoutMarginChanged={(event: MarginChangedEvent) => {
          this.setState({
            marginTop: parseInt(event.marginTop || '0'),
            marginRight: parseInt(event.marginRight || '0'),
            marginLeft: parseInt(event.marginLeft || '0'),
            marginBottom: parseInt(event.marginBottom || '0'),
          });
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
