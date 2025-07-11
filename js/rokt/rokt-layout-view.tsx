import { Platform } from "react-native";

// Import both implementations
import { RoktLayoutView as RoktLayoutViewIOS } from "./rokt-layout-view.ios";
import { RoktLayoutView as RoktLayoutViewAndroid } from "./rokt-layout-view.android";

// Export types
export type { RoktLayoutViewProps } from "./rokt-layout-view.ios";

// Export the appropriate component based on platform
export const RoktLayoutView =
  Platform.OS === "ios" ? RoktLayoutViewIOS : RoktLayoutViewAndroid;

// Default export
export default RoktLayoutView;
