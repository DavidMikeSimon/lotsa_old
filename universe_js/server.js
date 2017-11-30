const erlastic = require('node_erlastic');

erlastic.server(
  (term, _from, state, done) => {
    term.unpack((command) => {
      switch (command.toString()) {
        case "ping":
          return done("reply", "pong");
        default:
          throw new Error("unknown command " + command)
      }
    });
  },
  () => {
    return {};
  }
);
