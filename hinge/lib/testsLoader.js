const _ = require("lodash");
const path = require('path');
const fs = require('fs');

const { getPluginFilePath } = require('./common');

function loadPluginTests(pluginName, searchPaths) {
  const testsPath = getPluginFilePath("tests.js", pluginName, "*", searchPaths);
  if (!testsPath) { return {}; }
  return require(testsPath);
}

module.exports = { loadPluginTests };
