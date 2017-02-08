return {
  protocol = 1,
  version = "0.0.1",
  dependencies = {},
  setup = function(p)
    -- Must have block type index 0
    p.define_block_type("unknown", {
      client_hints = { color = "#000" }
    })

    -- Must have block type index 1
    p.define_block_type("empty", {
      client_hints = { color = "#fff" }
    })
  end
}
