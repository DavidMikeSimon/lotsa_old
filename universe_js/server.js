const ProtoBuf = require('ProtoBufjs');
const Tuple = require('tuple-w');
const erlastic = require('node_erlastic');

function loadConfig(config, protoRoot) {
  const UniverseDef = protoRoot.lookupType("LotsaProto.UniverseDef");
  const udef = UniverseDef.create({
    url: config.url
  });
  return UniverseDef.encode(udef).finish();
}

function main() {
  ProtoBuf.load("../proto/lotsa.proto").then((protoRoot) => {
    erlastic.server(
      (term, _from, state, done) => {
        term.unpack((command, args) => {
          switch (command.toString()) {
            case "ping":
              return done("reply", "pong");
            case "load_config":
              const config = JSON.parse(args[0]);
              const udefBuffer = loadConfig(config, protoRoot);
              return done("reply", new Tuple("protobuf", "UniverseDef", udefBuffer));
            default:
              throw new Error("unknown command " + command)
          }
        });
      },
      () => {
        return {};
      }
    );
  });
}

main();
