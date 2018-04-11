module.exports = {
  aliases: {
    "-": "basis:empty",
    "S": "conwayLife2d:life"
  },

  tests: {
    fallow: [
      `
        ---
        ---
        ---
      `,
      { sameAs: "start" },
      { sameAs: "start" }
    ],

    underpopulation: [
     `
        ---
        -S-
        ---
      `, `
        ---
        ---
        ---
      `,
      { sameAs: "prev" }
    ],

    overpopulation: [
      `
        SSS
        SSS
        SSS
      `, `
        S-S
        ---
        S-S
      `, `
        ---
        ---
        ---
      `
    ],

    twoByTwo: [
      `
        SS-
        SS-
        ---
      `,
      { sameAs: "start" },
      { sameAs: "start" }
    ],

    blinker: [
      `
        ---
        SSS
        ---
      `, `
        -S-
        -S-
        -S-
      `,
      { sameAs: "start" }
    ]
  }
};
