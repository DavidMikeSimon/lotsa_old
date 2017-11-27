const erlastic = require('node_erlastic');

erlastic.server(
  (term, _from, state, done) => {
    const {command, args} = term;

    switch (command) {
      case "load":
        return done("reply", null);
      default;
        throw new Error("unknown command")
    }
  },
  () => {
    return {};
  }
);
