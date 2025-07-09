import {
  requireNativeComponent,
  StyleSheet,
  NativeEventEmitter,
  NativeModules,
  HostComponent,
  ViewProps,
  NativeModule,
  UIManager,
} from "react-native";
import React, { Component } from "react";
import RoktNativeLayoutComponent from "./RoktNativeLayoutComponent";

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

// Architecture detection - Updated for RN 0.80+ compatibility
// In RN 0.80+, check for Fabric renderer using a more reliable method
const isNewArchitecture = (() => {
  // Check if Fabric renderer is enabled by looking at UIManager properties
  // This is a safer approach that works in RN 0.80+
  const hasFabricUIManager =
    UIManager &&
    typeof UIManager.hasViewManagerConfig === "function" &&
    UIManager.hasViewManagerConfig("RCTView");

  if (hasFabricUIManager) {
    return true;
  }

  // Fallback: check TurboModule presence (less reliable in 0.80+)
  const turboModuleCheck =
    (NativeModules as { RNRoktWidget?: unknown }).RNRoktWidget == null;
  return turboModuleCheck;
})();

// Conditional component loading based on architecture
let WidgetNativeComponent: HostComponent<RoktNativeLayoutProps>;

if (isNewArchitecture) {
  try {
    // Try to import the new architecture component
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const NativeComponent = require("./RoktNativeLayoutComponent") as {
      default: HostComponent<RoktNativeLayoutProps>;
    };
    WidgetNativeComponent = NativeComponent.default;
  } catch (error) {
    WidgetNativeComponent = requireNativeComponent("RoktNativeLayout");
  }
} else {
  WidgetNativeComponent = requireNativeComponent("RoktNativeLayout");
}

const eventManagerEmitter = new NativeEventEmitter(RoktEventManager);

export class RoktLayoutView extends Component<
  RoktLayoutViewProps,
  RoktLayoutViewState
> {
  subscription = eventManagerEmitter.addListener(
    "LayoutHeightChanges",
    (widgetChanges: WidgetChangeEvent) => {
      if (widgetChanges.selectedPlacement == this.state.placeholderName) {
        this.setState({ height: parseInt(widgetChanges.height) });
      }
    },
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
    // Cast to React.ComponentType to make it compatible with JSX
    const RoktComponent = RoktNativeLayoutComponent as React.ComponentType<any>;
    return (
      <RoktComponent
        style={[styles.widget, { height: this.state.height }]}
        placeholderName={this.state.placeholderName}
        onLayoutHeightChanged={(event: HeightChangedEvent) => {
          if (event.height) {
            this.setState({ height: parseInt(event.height) });
          }
        }}
        onLayoutMarginChanged={(event: MarginChangedEvent) => {
          this.setState({
            marginTop: parseInt(event.marginTop || "0"),
            marginRight: parseInt(event.marginRight || "0"),
            marginLeft: parseInt(event.marginLeft || "0"),
            marginBottom: parseInt(event.marginBottom || "0"),
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
    backgroundColor: "transparent",
    overflow: "hidden",
  },
});

export default RoktLayoutView;
