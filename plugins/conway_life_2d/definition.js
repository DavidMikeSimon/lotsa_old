module.exports = {
  protocol: 1,
  version: "0.0.1",
  dependencies: {
    basis: "*",
  },
  setup: (p) => {
    const isAlive = p.defineProperty("isAlive", "boolean", {
      defaultValue: false,
    });

    const isLifeSpawnable = p.defineProperty("isLifeSpawnable", "boolean", {
      defaultValue: false,
    });

    const btLife = p.defineBlockType("life", {
      clientHints: { color: "#00f" },
    });
    btLife.provideProperty(isAlive, { fixedValue: true });

    const basis = p.getDependency("basis");
    const btEmpty = basis.getBlockType("empty");
    btEmpty.provideProperty(isLifeSpawnable, { fixedValue: true });

    const inputSelfIsSpawnable = p.defineBlockInput(
      "selfIsSpawnable",
      p.blockTargets.self(),
      p.inputExpr.fetchValue(isLifeSpawnable)
    );

    const inputSelfIsAlive = p.defineBlockInput(
      "selfIsAlive",
      p.blockTargets.self(),
      p.inputExpr.fetchValue(isAlive)
    );

    const inputNumNeighborsAlive = p.defineBlockInput(
      "numNeighborsAlive",
      p.blockTargets.chebyshevNeighbors(1),
      p.inputExpr.countWhere(isAlive, p.bExpr.eq(true))
    );

    const uSpawn = p.declareBlockUpdater("spawn");

    const rSpawning = p.defineBlockRule("spawning");
    rSpawning.addPrereq("canSpawn", inputSelfIsSpawnable, p.bExpr.eq(true));
    rSpawning.addPrereq("hasParents", inputNumNeighborsAlive, p.bExpr.eq(3));
    rSpawning.addCall(uSpawn);

    const uDeath = p.declareBlockUpdater("death");

    const rUnderpopDeath = p.defineBlockRule("underpopDeath");
    rUnderpopDeath.addPrereq("alive", inputSelfIsAlive, p.bExpr.eq(true));
    rUnderpopDeath.addPrereq("tooFewNeighbors", inputNumNeighborsAlive, p.bExpr.lt(2));
    rUnderpopDeath.addCall(uDeath);

    const rOverpopDeath = p.defineBlockRule("overpopDeath");
    rOverpopDeath.addPrereq("alive", inputSelfIsAlive, p.bExpr.eq(true));
    rOverpopDeath.addPrereq("tooManyNeighbors", inputNumNeighborsAlive, p.bExpr.gt(4));
    rOverpopDeath.addCall(uDeath);
  },
};
