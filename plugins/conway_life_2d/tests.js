module.exports: {
  blockTypeAliases: {
    empty: "-",
    life: "S"
  },

  tests: {
    fallow: {
      start: `
        ---
        ---
        ---
      `,
      after1: { sameAs: "start" },
      after2: { sameAs: "start" }
    },

    underpopulation: {
      start: `
        ---
        -S-
        ---
      `,
      after1: `
        ---
        ---
        ---
      `,
      after2: { sameAs: "after1" }
    },

    overpopulation: {
      start: `
        SSS
        SSS
        SSS
      `,
      after1: `
        S-S
        ---
        S-S
      `,
      after2: `
        ---
        ---
        ---
      `
    },

    twoByTwo: {
      start: `
        SS-
        SS-
        ---
      `,
      after1: { sameAs: "start" },
      after2: { sameAs: "start" }
    },

    blinker: {
      start: `
        ---
        SSS
        ---
      `,
      after1: `
        -S-
        -S-
        -S-
      `,
      after2: `
        ---
        SSS
        ---
      `
    }
  }
};
