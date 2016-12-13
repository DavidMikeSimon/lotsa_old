block_type_aliases = {
  dead = "-"
  alive = "O"
}

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
      -O-
      ---
    ]],
    after_1 = "unchanged",
    after_2 = "unchanged"
  },

  test_overpopulation = {
    start = [[
      OOO
      OOO
      OOO
    ]],
    after_1 = [[
      O-O
      ---
      O-O
    ]],
    after_2 = [[
      ---
      ---
      ---
    ]]
  },

  test_two_by_two = {
    start = [[
      00-
      00-
      ---
    ]],
    after_1 = "unchanged",
    after_2 = "unchanged"
  },

  test_blinker = {
    start = [[
      ---
      OOO
      ---
    ]],
    after_1 = [[
      -O-
      -O-
      -O-
    ]],
    after_2 = [[
      ---
      OOO
      ---
    ]]
  }
}
