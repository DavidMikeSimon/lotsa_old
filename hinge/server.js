const ProtoBuf = require('protobufjs');
const Tuple = require('tuple-w');
const erlastic = require('node_erlastic');
const bert = erlastic.bert;

const universeDefSetup = require('./lib/universeDefSetup.js');

const PLUGIN_PATHS = [
  "../plugins"
];


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
              const udef = universeDefSetup.loadConfig(protoRoot, PLUGIN_PATHS, config);
              return done("reply", new Tuple(
                bert.atom("protobuf"),
                bert.atom("UniverseDef"),
                protoRoot.lookupType("UniverseDef").encode(udef).finish()
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
