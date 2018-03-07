const _ = require("lodash");
const path = require('path');
const fs = require('fs');

function loadConfig(protoRoot, searchPaths, config) {
  const OPERATOR = protoRoot.lookupType("ConditionalExpression").Operator;
  const PROP_TYPE = protoRoot.lookupType("PropertyDef").PropType;

  function getPluginDef(name, _versionSpec) {
    // TODO: Validate pluginName
    // TODO: Check against versionSpec
    const possiblePaths = _.map(searchPaths, (p) => path.resolve(p, name, "definition.js"));
    const pluginDefPath = _.find(possiblePaths, fs.existsSync);
    if (!pluginDefPath) {
      throw new Error("No such plugin '" + name + "' found in search paths");
    }
    return require(pluginDefPath);
  }

  function resolvePlugins(pending, stack = [], resolved = []) {
    if (pending.length == 0) {
      return resolved;
    }

    const [name, versionSpec] = pending[0];
    const plugin = getPluginDef(name, versionSpec);

    const depNames = _.map(plugin.dependencies, (dep) => dep[0]);
    const circularDeps = _.intersection(depNames, stack);
    if (circularDeps.length > 0) {
      throw new Error("Circular dependency from " + name + " on " + circularDeps[0]);
    }

    const depPlugins = resolvePlugins(plugin.dependencies, stack.concat([name]));
    const nowResolved = _.uniq(resolved.concat(depPlugins, [[name, versionSpec]]));
    return resolvePlugins(_.drop(pending, 1), stack, nowResolved)
  }

  function buildConditionalExpr(obj) {
    if (_.size(obj) != 1) {
      throw new Error("Conditional expression objects must have one key");
    }

    const key = _.keys(obj)[0];
    const operator = OPERATOR[key.substr(1).toUpperCase()];
    if (_.isUndefined(operator)) { throw new Error("No such operator " + key); }
    const operands = obj[key];

    return {
      left: buildValueExpr(operands[0]),
      operator,
      right: buildValueExpr(operands[1]),
    };
  }

  function buildValueExpr(val) {
    if (_.isString(val)) {
      return { constant: { string: val } };
    } else if (_.isInteger(val)) {
      return { constant: { integer: val } };
    } else if (_.isBoolean(val)) {
      return { constant: { boolean: val } };
    } else if (_.isObject(val)) {
      if (val['$count']) {
        return { countBlocks: {
          target: buildBlockTarget(val['$count'][0]),
          filter: buildConditionalExpr(val['$count'][1]),
        } };
      } else if (val.constructor == PropertyWrapper) {
        return { fetchBlockProperty: { property: val.getIndex() } };
      }
    }

    throw new Error("Unknown value expression");
  }

  function buildBlockTarget(obj) {
    if (_.size(obj) != 1) {
      throw new Error("Block target objects must have one key");
    }

    const key = _.keys(obj)[0];
    const val = obj[key];

    if (key == '$chebyshev') {
      return { chebyshevNeighbors: { range: val } };
    }
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
      this._rule.prereqs[name] = buildConditionalExpr(prereqDef);

      return this;
    }

    callBlockUpdater(updater) {
      this._rule.updaters.push(updater.getIndex());

      return this;
    }
  }

  class PluginSetup {
    constructor(pluginName, pluginDef, universeDef) {
      this._pluginName = pluginName;

      this._universeDef = universeDef || {};

      if (!this._universeDef.plugins) { this._universeDef.plugins = {}; }
      const versionParts = pluginDef.version.split(".").map((s) => parseInt(s))
      const maxLoadOrder = _.max(_.map(this._universeDef.plugins, 'loadOrder'));
      this._universeDef.plugins[pluginName] = {
        name: pluginName,
        loadOrder: _.isUndefined(maxLoadOrder) ? 0 : maxLoadOrder + 1,
        version: {
          major: versionParts[0],
          minor: versionParts[1],
          patch: versionParts[2]
        }
      }

      if (!this._universeDef.blockTypes) { this._universeDef.blockTypes = {}; }
      this._nextBlockTypeIndex = _.max(_.map(this._universeDef.blockTypes, 'index')) || 0;

      if (!this._universeDef.properties) { this._universeDef.properties = {}; }
      this._nextPropertyIndex = _.max(_.map(this._universeDef.properties, 'index')) || 0;

      if (!this._universeDef.blockUpdaters) { this._universeDef.blockUpdaters = {}; }
      this._nextBlockUpdaterIndex = _.max(_.map(this._universeDef.blockUpdaters, 'index')) || 0;

      if (!this._universeDef.blockRules) { this._universeDef.blockRules = {}; }
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
        prereqs: {},
        updaters: [],
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

  function loadPluginConfig(udef, [pluginName, versionSpec]) {
    const pdef = getPluginDef(pluginName, versionSpec);
    const ps = new PluginSetup(pluginName, pdef, udef);
    pdef.setup(ps);
    return ps.getUniverseDef();
  }

  function main() {
    const plugins = resolvePlugins(config.plugins);
    return plugins.reduce(
      (udef, plugin) => loadPluginConfig(udef, plugin),
      { url: config.url }
    );
  }

  return main();
}

module.exports = { loadConfig };
