/**
 * Metro configuration for React Native
 * https://github.com/facebook/react-native
 *
 * @format
 */

const path = require('path');
// const blacklist = require('metro-config/src/defaults/blacklist');

const reactNativeLib = path.resolve(__dirname, '..');


module.exports = {
  watchFolders: [path.resolve(__dirname, 'node_modules'), reactNativeLib],

  transformer: {
    getTransformOptions: async () => ({
      transform: {
        experimentalImportSupport: false,
        inlineRequires: false,
      },
    }),
  },
  
};
