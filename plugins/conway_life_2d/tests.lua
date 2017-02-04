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
      after_1 = { same_as = "start" },
      after_2 = { same_as = "start" }
    },

    test_underpopulation = {
      start = [[
        ---
        -S-
        ---
      ]],
      after_1 = { same_as = "start" },
      after_2 = { same_as = "start" }
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
      after_1 = { same_as = "start" },
      after_2 = { same_as = "start" }
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
