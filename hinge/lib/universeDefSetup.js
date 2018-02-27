const _ = require("lodash");
const path = require('path');
const fs = require('fs');

function getPluginDef(searchPaths, name, _versionSpec) {
  // TODO: Validate pluginName
  // TODO: Check against versionSpec
  const possiblePaths = _.map(searchPaths, (p) => path.resolve(p, name, "definition.js"));
  const pluginDefPath = _.find(possiblePaths, fs.existsSync);
  if (!pluginDefPath) {
    throw new Error("No such plugin '" + name + "' found in search paths");
  }
  return require(pluginDefPath);
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
    throw new Error("Circular dependency from " + name + " on " + circularDeps[0]);
  }

  const depPlugins = resolvePlugins(searchPaths, plugin.dependencies, stack.concat([name]));
  const nowResolved = _.uniq(resolved.concat(depPlugins, [[name, versionSpec]]));
  return resolvePlugins(searchPaths, _.drop(pending, 1), stack, nowResolved)
}

class BlockTypeWrapper {
  constructor(blockType) {
    this._blockType = blockType;
  }

  getIndex() {
    return this._blockType.index;
  }

  provideProperty(prop, source) {
    let protoSource;
    if (source.hasOwnProperty("$constant")) {
      // FIXME In the proto, we just end up with nil source :-(
      protoSource = { fixedValue: source.$constant };
    } else {
      throw new Error("Can't figure out source " + JSON.stringify(source));
    }

    this._blockType.propertyProvisions.push({
      property: prop.getIndex(),
      source: protoSource,
    });

    return this;
  }
}

class PropertyWrapper {
  constructor(property) {
    this._property = property;
  }

  getIndex() {
    return this._property.index;
  }
}

class PluginSetup {
  constructor(pluginName, universeDef) {
    this._pluginName = pluginName;

    this._universeDef = universeDef || {};
    if (!this._universeDef.blockTypes) { this._universeDef.blockTypes = {}; }
    if (!this._universeDef.properties) { this._universeDef.properties = {}; }

    this._nextBlockIndex = _.max(_.map(this._universeDef.blockTypes, 'index')) || 0;
    this._nextPropIndex = _.max(_.map(this._universeDef.properties, 'index')) || 0;
  }

  defBlockType(name, options = {}) {
    const fullName = this._pluginName + ":" + name;
    const blockType = {
      index: this._nextBlockIndex,
      pluginName: this._pluginName,
      name: name,
      clientHints: options.clientHints || {},
      propertyProvisions: [],
    };

    this._universeDef.blockTypes[fullName] = blockType;
    this._nextBlockIndex += 1;

    return new BlockTypeWrapper(blockType);
  }

  defProperty(name, type, options = {}) {
    const fullName = this._pluginName + ":" + name;
    const property = {
      index: this._nextPropIndex,
      pluginName: this._pluginName,
      name: name,
      type: type,
      defaultValue: options.defaultValue || null,
    };

    this._universeDef.properties[fullName] = property;
    this._nextPropIndex += 1;

    return new PropertyWrapper(property);
  }

  getUniverseDef() {
    return this._universeDef;
  }

  getBlockType(fullName) {
    const blockType = this._universeDef.blockTypes[fullName];
    if (!blockType) {
      throw new Error("No such block type found: " + fullName);
    }
    return new BlockTypeWrapper(blockType);
  }
}

function loadPluginConfig(searchPaths, udef, [pluginName, versionSpec]) {
  const pdef = getPluginDef(searchPaths, pluginName, versionSpec);
  const ps = new PluginSetup(pluginName, udef);
  pdef.setup(ps);
  return ps.getUniverseDef();
}

function loadConfig(searchPaths, config) {
  const plugins = resolvePlugins(searchPaths, config.plugins);
  return plugins.reduce(
    (udef, plugin) => loadPluginConfig(searchPaths, udef, plugin),
    { url: config.url }
  );
}

module.exports = { loadConfig };
