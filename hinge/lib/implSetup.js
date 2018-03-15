const _ = require("lodash");

class BlockTypeImpl {
  constructor(blockTypeDef) {
    this.blockTypeDef = blockTypeDef;
  }
}

class ImplSetup {
  constructor(_loader, pluginName, universeDef) {
    this.pluginName = pluginName;
    this.udef = universeDef;
  }

  fetchBlockType(pluginName, blockTypeName) {
    const fullName = pluginName + ":" + blockTypeName;
    const btDef = this.udef.blockTypes[fullName];
    if (!btDef) { throw new Error("No such blockType " + fullName); }
    return new BlockTypeImpl(btDef);
  }

  blockUpdater(updaterName, _argDef, fn) {
  }

  getBlockUpdaters() {
    return {};
  }
}

module.exports = { ImplSetup };
