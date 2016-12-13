block_type_aliases = {
  dead = "-"
  alive = "O"
}

tests = {
  fallow = {
    start = [[
      ---
      ---
      ---
    ]],
    after_1 = "unchanged",
    after_2 = "unchanged"
  },

  underpopulation = {
    start = [[
      ---
      -O-
      ---
    ]],
    after_1 = "unchanged",
    after_2 = "unchanged"
  },

  overpopulation = {
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

  two_by_two = {
    start = [[
      00-
      00-
      ---
    ]],
    after_1 = "unchanged",
    after_2 = "unchanged"
  },

  blinker = {
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
