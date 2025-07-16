import type { HostComponent, ViewProps } from 'react-native';
import type { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

// Event types - these define the data structure passed from native to JS
type HeightChangedEvent = {
  height: string;
};

type MarginChangedEvent = {
  marginTop: string;
  marginRight: string;
  marginLeft: string;
  marginBottom: string;
};

// Native component props - these are the props the native component expects
export interface NativeProps extends ViewProps {
  // Placeholder name to be passed to the native component
  placeholderName: string;

  // Custom events
  onLayoutHeightChanged?: DirectEventHandler<HeightChangedEvent>;
  onLayoutMarginChanged?: DirectEventHandler<MarginChangedEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'RoktNativeLayout'
) as HostComponent<NativeProps>;
