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

class BlockUpdaterWrapper {
  constructor(updater) {
    this._updater = updater;
  }

  getIndex() {
    return this._updater.index;
  }
}

class BlockRuleWrapper {
  constructor(rule) {
    this._rule = rule;
  }

  getIndex() {
    return this._rule.index;
  }

  addPrereq(name, prereqDef) {
    this._rule.prereqs.push({
      name: name,

    });

    return this;
  }

  cadllBlockUpdater(updater) {
    this._rule.updaters.push(updater.getIndex());

    return this;
  }
}

class PluginSetup {
  constructor(pluginName, universeDef) {
    this._pluginName = pluginName;

    this._universeDef = universeDef || {};
    if (!this._universeDef.blockTypes) { this._universeDef.blockTypes = {}; }
    if (!this._universeDef.properties) { this._universeDef.properties = {}; }
    if (!this._universeDef.blockUpdaters) { this._universeDef.blockUpdaters = {}; }
    if (!this._universeDef.blockRules) { this._universeDef.blockRules = {}; }

    this._nextBlockTypeIndex = _.max(_.map(this._universeDef.blockTypes, 'index')) || 0;
    this._nextPropertyIndex = _.max(_.map(this._universeDef.properties, 'index')) || 0;
    this._nextBlockUpdaterIndex = _.max(_.map(this._universeDef.blockUpdaters, 'index')) || 0;
    this._nextBlockRuleIndex = _.max(_.map(this._universeDef.blockRules, 'index')) || 0;
  }

  defBlockType(name, options = {}) {
    const fullName = this._pluginName + ":" + name;
    const blockType = {
      index: this._nextBlockTypeIndex,
      pluginName: this._pluginName,
      name: name,
      clientHints: options.clientHints || {},
      propertyProvisions: [],
    };

    this._universeDef.blockTypes[fullName] = blockType;
    this._nextBlockTypeIndex += 1;

    return new BlockTypeWrapper(blockType);
  }

  defProperty(name, type, options = {}) {
    const fullName = this._pluginName + ":" + name;
    const property = {
      index: this._nextPropertyIndex,
      pluginName: this._pluginName,
      name: name,
      type: type,
      defaultValue: options.defaultValue || null,
    };

    this._universeDef.properties[fullName] = property;
    this._nextPropertyIndex += 1;

    return new PropertyWrapper(property);
  }

  defBlockUpdater(name) {
    const fullName = this._pluginName + ":" + name;
    const updater = {
      index: this._nextBlockUpdaterIndex,
      pluginName: this._pluginName,
      name: name,
    };

    this._universeDef.blockUpdaters[fullName] = updater;
    this._nextBlockUpdaterIndex += 1;

    return new BlockUpdaterWrapper(updater);
  }

  defBlockRule(name) {
    const fullName = this._pluginName + ":" + name;
    const rule = {
      index: this._nextBlockRuleIndex,
      pluginName: this._pluginName,
      name: name,
      prereqs: [],
      updatersCalled: [],
    };

    this._universeDef.blockRules[fullName] = rule;
    this._nextBlockRuleIndex += 1;

    return new BlockRuleWrapper(rule);
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
