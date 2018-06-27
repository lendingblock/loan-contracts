'use strict';

const OFF = 0;
const ERROR = 2;

module.exports = {
  parser: 'babel-eslint',

  env: {
    es6: true,
    node: true
  },

  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:prettier/recommended',
  ],

  plugins: ['react'],

  rules: {
    'no-cond-assign': OFF,
    'no-floating-decimal': ERROR,
    'no-trailing-spaces': ERROR,
    'no-multiple-empty-lines': [ERROR, { max: 2, maxEOF: 0 }],
    'eol-last': ERROR,
    indent: [ERROR, 2],
    semi: ERROR,
    quotes: [ERROR, `single`],
    complexity: [ERROR, { max: 11 }],
    'react/prop-types': OFF
  },

  globals: {
    artifacts: true,
    web3: true,
    require: true,
    contract: true,
    it: true,
    assert: true
  }
};
