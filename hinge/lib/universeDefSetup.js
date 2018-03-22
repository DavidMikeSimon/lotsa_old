const _ = require("lodash");

const { PluginSetup } = require('./pluginSetup');
const { ImplSetup } = require('./implSetup');
const { getPluginFilePath } = require('./common');

class Loader {
  constructor(protoRoot, searchPaths) {
    this.OPERATOR = protoRoot.lookupType("ConditionalExpression").Operator;
    this.PROP_TYPE = protoRoot.lookupType("PropertyDef").PropType;

    this.searchPaths = searchPaths;
  }

  getPluginFilePath(fileName, pluginName, versionSpec) {
    const path = getPluginFilePath(fileName, pluginName, versionSpec, this.searchPaths);
    if (!path) {
      throw new Error("No such plugin '" + pluginName + "' found in search paths");
    }
    return path;
  }

  getPluginDef(pluginName, verisonSpec) {
    const pluginDefPath = this.getPluginFilePath("definition.js", pluginName, verisonSpec);
    return require(pluginDefPath);
  }

  getPluginImpl(pluginName, verisonSpec) {
    const pluginImplPath = this.getPluginFilePath("implementation.js", pluginName, verisonSpec);
    return require(pluginImplPath);
  }

  resolvePlugins(pending, stack = [], resolved = []) {
    if (pending.length == 0) {
      return resolved;
    }

    const [name, versionSpec] = pending[0];
    const plugin = this.getPluginDef(name, versionSpec);

    const depNames = _.map(plugin.dependencies, (dep) => dep[0]);
    const circularDeps = _.intersection(depNames, stack);
    if (circularDeps.length > 0) {
      throw new Error("Circular dependency from " + name + " on " + circularDeps[0]);
    }

    const depPlugins = this.resolvePlugins(plugin.dependencies, stack.concat([name]));
    const nowResolved = _.uniq(resolved.concat(depPlugins, [[name, versionSpec]]));
    return this.resolvePlugins(_.drop(pending, 1), stack, nowResolved);
  }

  loadPluginConfig(udef, [pluginName, versionSpec]) {
    const pdef = this.getPluginDef(pluginName, versionSpec);
    const ps = new PluginSetup(this, pluginName, pdef, udef);
    pdef.setup(ps);
    return ps.getUniverseDef();
  }

  loadConfig(config) {
    const plugins = this.resolvePlugins(config.plugins);
    const udef = plugins.reduce(
      (udef, plugin) => this.loadPluginConfig(udef, plugin),
      { url: config.url }
    );

    return udef;
  }

  loadImplementation(udef) {
    const pluginsWithImpls = _.uniq(_.map(udef.blockUpdaters, 'pluginName'));

    return _.fromPairs(_.map(pluginsWithImpls, (pluginName) => {
      const verObj = udef.plugins[pluginName].version;
      const verStr = verObj.major + "." + verObj.minor + "." + verObj.patch
      const implDef = this.getPluginImpl(pluginName, verStr);
      const is = new ImplSetup(this, pluginName, udef); 
      if (implDef.blockUpdaters) { implDef.blockUpdaters(is); }

      const pluginImpl = {
        blockUpdaters: is.getBlockUpdaters()
      };
      return [ pluginName, pluginImpl ];
    }));
  }
}

module.exports = { Loader };
