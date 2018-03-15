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
      (term, _from, state, done) => {
        term.unpack((command, args) => {
          switch (command.toString()) {
            case "ping":
              return done("reply", "pong");
            case "load_config":
              const config = JSON.parse(args[0]);
              const loader = new universeDefSetup.Loader(protoRoot, PLUGIN_PATHS);
              const udef = loader.loadConfig(config);

              const newImplementation = loader.loadImplementation(udef);
              const newState = { implementation: newImplementation };

              const reply = new Tuple(
                bert.atom("protobuf"),
                bert.atom("UniverseDef"),
                protoRoot.lookupType("UniverseDef").encode(udef).finish()
              );

              return done("reply", reply, newState);
            default:
              throw new Error("unknown command " + command)
          }
        });
      },

      // Init
      () => {
        return {
          implementation: {}
        };
      }
    );
  });
}

main();
