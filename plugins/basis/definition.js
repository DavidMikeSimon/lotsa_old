module.exports = {
  protocol: 1,
  version: "0.0.1",
  dependencies: {},
  setup: (p) => {
    // Must have block type index 0
    p.defBlockType("unknown", { clientHints: { color: "#000" } });

    // Must have block type index 1
    p.defBlockType("empty", { clientHints: { color: "#fff" } });
  },
};
