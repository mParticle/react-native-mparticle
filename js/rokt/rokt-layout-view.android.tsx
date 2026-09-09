import { StyleSheet } from 'react-native';
import React, { Component } from 'react';
import RoktNativeLayoutComponent from '../codegenSpecs/rokt/RoktLayoutNativeComponent';

/**
 * PUBLIC API: Props that users of RoktLayoutView can set
 */
export interface RoktLayoutViewProps {
  // Placeholder name to use
  placeholderName: string;
}

/**
 * INTERNAL: State managed by the component to handle native events
 */
export interface RoktLayoutViewState {
  height: number;
  placeholderName: string;
}

/**
 * Native event types for type safety
 */
interface HeightChangedEvent {
  nativeEvent: {
    height: string;
  };
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
  },
});

/**
 * RoktEmbeddedView is a wrapper component for the native RoktNativeWidget.
 * It handles the native events internally and provides a simpler API for React Native apps.
 *
 * This component only exposes the placeholderName prop to users, hiding all the internal complexity.
 */
export class RoktLayoutView extends Component<
  RoktLayoutViewProps,
  RoktLayoutViewState
> {
  constructor(props: RoktLayoutViewProps) {
    super(props);
    this.state = {
      height: 0,
      placeholderName: this.props.placeholderName,
    };
  }

  /**
   * Handles the height changed event from the native component
   * This is an internal implementation detail not exposed to users
   */
  private handleHeightChanged = (event: HeightChangedEvent) => {
    if (event && event.nativeEvent && event.nativeEvent.height) {
      this.setState({ height: parseInt(event.nativeEvent.height) });
    }
  };

  override render() {
    try {
      // Get the placeholderName from props
      const { placeholderName } = this.props;

      // Return the native component with the props
      // Cast to React.ComponentType to make it compatible with JSX
      // Using 'unknown' intermediate cast for compatibility with different @types/react versions
      const RoktComponent =
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        RoktNativeLayoutComponent as unknown as React.ComponentType<any>;
      return (
        <RoktComponent
          placeholderName={placeholderName}
          style={[
            styles.widget,
            {
              height: this.state.height,
            },
          ]}
          onLayoutHeightChanged={this.handleHeightChanged}
        />
      );
    } catch (error) {
      console.error('[ROKT] Error rendering RoktEmbeddedView:', error);
      return null;
    }
  }
}

export default RoktLayoutView;
