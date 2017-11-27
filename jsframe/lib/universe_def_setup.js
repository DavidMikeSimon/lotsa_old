const _ = require("lodash");
const ProtoBuf = require("protobufjs");

function getPluginDef(name, _versionSpec) {
  // TODO: Verify that version spec fits
}

function resolvePlugins(searchPaths, pending, stack = [], resolved = []) {
  if (pending.length == 0) {
    return resolved;
  }

  const [name, versionSpec] = pending[0];
  const plugin = getPluginDef(searchPaths, name, versionSpec);

  const depNames = _.map(plugin.dependencies, (dep) => dep[0]);
  const circularDeps = _.intersection(depNames, stack);
  if (circularDeps.length > 0) {
    throw new Error("Circular dependency from " + name + " on " circularDeps[0]);
  }

  const depPlugins = resolvePlugins(searchPaths, plugin.dependencies, stack.concat([name]));
  const nowResolved = _.uniq(resolved.concat(depPlugins, [name]));
  return resolvePlugins(searchPaths, _.drop(pending, 1), stack, nowResolved)
}

function setup(pluginSearchPaths, config) {
  const paths = resolvePlugins(pluginSearchPaths, config.plugins);

  let universeDef = {};
  for (path of paths) {
    const pluginDef = require(path);
    const setupDsl = new PluginSetupDSL(universeDef, pluginDef);
    pluginDef.setup(setupDsl);
  }

  return LotsaProto.UniverseDef.encode(universeDef);
}

module.exports = { setup };
