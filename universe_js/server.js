const path = require('path');
const ProtoBuf = require('protobufjs');
const Tuple = require('tuple-w');
const _ = require('lodash');
const erlastic = require('node_erlastic');
const bert = erlastic.bert;

class PluginSetupHelper {
  constructor(pluginName, priorUniverseDef) {
    this._pluginName = pluginName;
    this._universeDef = Object.assign(
      {},
      {
        blockTypes: {}
      },
      priorUniverseDef
    );

    this._nextBlockIndex = _.max(_.map(this._universeDef.blockTypes, 'index')) || 0;
  }

  defineBlockType(name, options) {
    const fullName = this._pluginName + ":" + name;
    this._universeDef.blockTypes[fullName] = {
      index: this._nextBlockIndex,
      pluginName: this._pluginName,
      name: name,
      clientHints: options.clientHints || {},
      propertyProvisions: [],
    };
    this._nextBlockIndex += 1;
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
  const helper = new PluginSetupHelper(pluginName, udef);
  pdef.setup(helper);
  return helper.getUniverseDef();
}

function loadConfig(config, protoRoot) {
  const udef = config.plugins.reduce(loadPluginConfig, { url: config.url });
  return protoRoot.lookupType("LotsaProto.UniverseDef").encode(udef).finish();
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
