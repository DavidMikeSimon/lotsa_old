const erlastic = require('node_erlastic');

erlastic.server(
  (term, _from, state, done) => {
    const {command, args} = term;

    switch (command) {
      case "ping":
        return done("reply", "pong");
      default:
        throw new Error("unknown command in: " + JSON.stringify(term))
    }
  },
  () => {
    return {};
  }
);
