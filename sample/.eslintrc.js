const path = require('path');

module.exports = {
  root: true,
  extends: '@react-native',
  parserOptions: {
    babelOptions: {
      configFile: path.join(__dirname, 'babel.config.js'),
    },
  },
};
