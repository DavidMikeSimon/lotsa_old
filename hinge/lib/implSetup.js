const _ = require("lodash");

class BlockTypeImpl {
  constructor(blockTypeDef) {
    this.blockTypeDef = blockTypeDef;
  }

  getIndex() {
    return this.blockTypeDef.index;
  }
}

class ImplSetup {
  constructor(_loader, pluginName, universeDef) {
    this.pluginName = pluginName;
    this.udef = universeDef;
    this.blockUpdaters = {};
  }

  fetchBlockType(pluginName, blockTypeName) {
    const fullName = pluginName + ":" + blockTypeName;
    const btDef = this.udef.blockTypes[fullName];
    if (!btDef) { throw new Error("No such blockType " + fullName); }
    return new BlockTypeImpl(btDef);
  }

  blockUpdater(updaterName, _argDef, fn) {
    this.blockUpdaters[updaterName] = fn;
  }

  getBlockUpdaters() {
    return this.blockUpdaters;
  }
}

module.exports = { ImplSetup };
