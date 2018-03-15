const _ = require("lodash");

class BlockTypeWrapper {
  constructor(ps, blockType) {
    this.ps = ps;
    this.blockType = blockType;
  }

  getIndex() {
    return this.blockType.index;
  }

  provideProperty(prop, source) {
    let protoSource;
    if (source.hasOwnProperty("$constant")) {
      // FIXME In the proto, we just end up with nil source :-(
      protoSource = { fixedValue: source.$constant };
    } else {
      throw new Error("Can't figure out source " + JSON.stringify(source));
    }

    this.blockType.propertyProvisions.push({
      property: prop.getIndex(),
      source: protoSource,
    });

    return this;
  }
}

class PropertyWrapper {
  constructor(ps, property) {
    this.ps = ps;
    this.property = property;
  }

  getIndex() {
    return this.property.index;
  }
}

class BlockUpdaterWrapper {
  constructor(ps, updater) {
    this.ps = ps;
    this.updater = updater;
  }

  getIndex() {
    return this.updater.index;
  }
}

class BlockRuleWrapper {
  constructor(ps, rule) {
    this.ps = ps;
    this.rule = rule;
  }

  getIndex() {
    return this.rule.index;
  }

  addPrereq(name, prereqDef) {
    this.rule.prereqs[name] = this.ps.buildConditionalExpr(prereqDef);

    return this;
  }

  callBlockUpdater(updater) {
    this.rule.updaters.push(updater.getIndex());

    return this;
  }
}

class PluginSetup {
  constructor(loader, pluginName, pluginDef, universeDef) {
    this.OPERATOR = loader.OPERATOR;
    this.pluginName = pluginName;

    this.universeDef = universeDef || {};

    if (!this.universeDef.plugins) { this.universeDef.plugins = {}; }
    const versionParts = pluginDef.version.split(".").map((s) => parseInt(s))
    const maxLoadOrder = _.max(_.map(this.universeDef.plugins, 'loadOrder'));
    this.universeDef.plugins[pluginName] = {
      name: pluginName,
      loadOrder: _.isUndefined(maxLoadOrder) ? 0 : maxLoadOrder + 1,
      version: {
        major: versionParts[0],
        minor: versionParts[1],
        patch: versionParts[2]
      }
    }

    if (!this.universeDef.blockTypes) { this.universeDef.blockTypes = {}; }
    this.nextBlockTypeIndex = _.max(_.map(this.universeDef.blockTypes, 'index')) || 0;

    if (!this.universeDef.properties) { this.universeDef.properties = {}; }
    this.nextPropertyIndex = _.max(_.map(this.universeDef.properties, 'index')) || 0;

    if (!this.universeDef.blockUpdaters) { this.universeDef.blockUpdaters = {}; }
    this.nextBlockUpdaterIndex = _.max(_.map(this.universeDef.blockUpdaters, 'index')) || 0;

    if (!this.universeDef.blockRules) { this.universeDef.blockRules = {}; }
    this.nextBlockRuleIndex = _.max(_.map(this.universeDef.blockRules, 'index')) || 0;
  }

  buildConditionalExpr(obj) {
    if (_.size(obj) != 1) {
      throw new Error("Conditional expression objects must have one key");
    }

    const key = _.keys(obj)[0];
    const operator = this.OPERATOR[key.substr(1).toUpperCase()];
    if (_.isUndefined(operator)) { throw new Error("No such operator " + key); }
    const operands = obj[key];

    return {
      left: this.buildValueExpr(operands[0]),
      operator,
      right: this.buildValueExpr(operands[1]),
    };
  }

  buildValueExpr(val) {
    if (_.isString(val)) {
      return { constant: { string: val } };
    } else if (_.isInteger(val)) {
      return { constant: { integer: val } };
    } else if (_.isBoolean(val)) {
      return { constant: { boolean: val } };
    } else if (_.isObject(val)) {
      if (val['$count']) {
        return { countBlocks: {
          target: this.buildBlockTarget(val['$count'][0]),
          filter: this.buildConditionalExpr(val['$count'][1]),
        } };
      } else if (val.constructor == PropertyWrapper) {
        return { fetchBlockProperty: { property: val.getIndex() } };
      }
    }

    throw new Error("Unknown value expression");
  }

  buildBlockTarget(obj) {
    if (_.size(obj) != 1) {
      throw new Error("Block target objects must have one key");
    }

    const key = _.keys(obj)[0];
    const val = obj[key];

    if (key == '$chebyshev') {
      return { chebyshevNeighbors: { range: val } };
    }
  }

  defBlockType(name, options = {}) {
    const fullName = this.pluginName + ":" + name;
    const blockType = {
      index: this.nextBlockTypeIndex,
      pluginName: this.pluginName,
      name: name,
      clientHints: options.clientHints || {},
      propertyProvisions: [],
    };

    this.universeDef.blockTypes[fullName] = blockType;
    this.nextBlockTypeIndex += 1;

    return new BlockTypeWrapper(this, blockType);
  }

  defProperty(name, type, options = {}) {
    const fullName = this.pluginName + ":" + name;
    const property = {
      index: this.nextPropertyIndex,
      pluginName: this.pluginName,
      name: name,
      type: type,
      defaultValue: options.defaultValue || null,
    };

    this.universeDef.properties[fullName] = property;
    this.nextPropertyIndex += 1;

    return new PropertyWrapper(this, property);
  }

  defBlockUpdater(name) {
    const fullName = this.pluginName + ":" + name;
    const updater = {
      index: this.nextBlockUpdaterIndex,
      pluginName: this.pluginName,
      name: name,
    };

    this.universeDef.blockUpdaters[fullName] = updater;
    this.nextBlockUpdaterIndex += 1;

    return new BlockUpdaterWrapper(this, updater);
  }

  defBlockRule(name) {
    const fullName = this.pluginName + ":" + name;
    const rule = {
      index: this.nextBlockRuleIndex,
      pluginName: this.pluginName,
      name: name,
      prereqs: {},
      updaters: [],
    };

    this.universeDef.blockRules[fullName] = rule;
    this.nextBlockRuleIndex += 1;

    return new BlockRuleWrapper(this, rule);
  }

  getUniverseDef() {
    return this.universeDef;
  }

  getBlockType(fullName) {
    const blockType = this.universeDef.blockTypes[fullName];
    if (!blockType) {
      throw new Error("No such block type found: " + fullName);
    }
    return new BlockTypeWrapper(this, blockType);
  }
}

module.exports = { PluginSetup };
