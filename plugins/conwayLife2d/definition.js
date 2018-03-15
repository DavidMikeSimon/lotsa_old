module.exports = {
  protocol: 1,
  version: "0.0.1",
  dependencies: [
    ["basis", "*"],
  ],
  setup: (p) => {
    const isAlive = p.defProperty("isAlive", "boolean", {
      defaultValue: false,
    });

    const isLifeSpawnable = p.defProperty("isLifeSpawnable", "boolean", {
      defaultValue: false,
    });

    p.defBlockType("life", {
        clientHints: { color: "#00f" },
    }).provideProperty(isAlive, { $constant: true });

    p.getBlockType("basis:empty")
     .provideProperty(isLifeSpawnable, { $constant: true });

    const buSpawn = p.defBlockUpdater("spawn");
    const buDeath = p.defBlockUpdater("death");

    const NUM_NEIGHBORS_ALIVE = { $count: [
      { $chebyshev: 1 },
      { $eq: [ "isAlive", true ] },
    ] };

    p.defBlockRule("spawning")
      .addPrereq("canSpawn", { $eq: [ isLifeSpawnable, true ] })
      .addPrereq("hasParents", { $eq: [ NUM_NEIGHBORS_ALIVE, 3 ] })
      .callBlockUpdater(buSpawn);

    p.defBlockRule("underpopDeath")
      .addPrereq("alive", { $eq: [ isAlive, true ] })
      .addPrereq("tooFewNeighbors", { $lt: [ NUM_NEIGHBORS_ALIVE, 2 ] })
      .callBlockUpdater(buDeath);

    p.defBlockRule("overpopDeath")
      .addPrereq("alive", { $eq: [ isAlive, true ] })
      .addPrereq("tooManyNeighbors", { $gt: [ NUM_NEIGHBORS_ALIVE, 4 ] })
      .callBlockUpdater(buDeath);
  },
};
