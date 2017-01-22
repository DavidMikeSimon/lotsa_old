return {
  block_type_aliases = {
    empty = "-",
    life = "S"
  },

  tests = {
    test_fallow = {
      start = [[
        ---
        ---
        ---
      ]],
      after_1 = "unchanged",
      after_2 = "unchanged"
    },

    test_underpopulation = {
      start = [[
        ---
        -S-
        ---
      ]],
      after_1 = "unchanged",
      after_2 = "unchanged"
    },

    test_overpopulation = {
      start = [[
        SSS
        SSS
        SSS
      ]],
      after_1 = [[
        S-S
        ---
        S-S
      ]],
      after_2 = [[
        ---
        ---
        ---
      ]]
    },

    test_two_by_two = {
      start = [[
        SS-
        SS-
        ---
      ]],
      after_1 = "unchanged",
      after_2 = "unchanged"
    },

    test_blinker = {
      start = [[
        ---
        SSS
        ---
      ]],
      after_1 = [[
        -S-
        -S-
        -S-
      ]],
      after_2 = [[
        ---
        SSS
        ---
      ]]
    }
  }
}
