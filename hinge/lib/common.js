const _ = require("lodash");
const path = require('path');
const fs = require('fs');

function getPluginFilePath(fileName, pluginName, _versionSpec, searchPaths) {
  // TODO: Validate pluginName
  // TODO: Check against versionSpec
  const possiblePaths = _.map(searchPaths, (p) => path.resolve(p, pluginName, fileName));
  return _.find(possiblePaths, fs.existsSync);
}

module.exports = { getPluginFilePath };
