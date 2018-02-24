const path = require('path');
const ProtoBuf = require('protobufjs');
const Tuple = require('tuple-w');
const _ = require('lodash');
const erlastic = require('node_erlastic');
const bert = erlastic.bert;

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
  constructor(pluginName, priorUniverseDef) {
    this._pluginName = pluginName;
    this._universeDef = Object.assign(
      {},
      {
        blockTypes: {},
        properties: {},
      },
      priorUniverseDef
    );

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
}

function getPluginDef(pluginName, versionSpec) {
  // TODO: Validate pluginName
  // TODO: Check against versionSpec
  const pluginDefPath = path.join("..", "plugins", pluginName, "definition");
  return require(pluginDefPath);
}

function loadPluginConfig(udef, [pluginName, versionSpec]) {
  const pdef = getPluginDef(pluginName, versionSpec);
  const setup = new PluginSetup(pluginName, udef);
  pdef.setup(setup);
  return setup.getUniverseDef();
}

function loadConfig(config, protoRoot) {
  const udef = config.plugins.reduce(loadPluginConfig, { url: config.url });
  return protoRoot.lookupType("UniverseDef").encode(udef).finish();
}

function main() {
  ProtoBuf.load("../proto/lotsa.proto").then((protoRoot) => {
    erlastic.server(
      // Response loop
      (term, _from, _state, done) => {
        term.unpack((command, args) => {
          switch (command.toString()) {
            case "ping":
              return done("reply", "pong");
            case "load_config":
              const config = JSON.parse(args[0]);
              return done("reply", new Tuple(
                bert.atom("protobuf"),
                bert.atom("UniverseDef"),
                loadConfig(config, protoRoot)
              ));
            default:
              throw new Error("unknown command " + command)
          }
        });
      },

      // Init
      () => {
        return {};
      }
    );
  });
}

main();
