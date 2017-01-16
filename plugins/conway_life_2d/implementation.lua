basis = get_plugin("basis")
bt_empty = basis.get_block_type("empty")

conway_life_2d = get_plugin("conway_life_2d")
bt_life = conway_life_2d.get_block_type("life")

conway_life_2d.implement_fn("spawn", {}, function()
  return set_block_type(bt_life)
end)

conway_life_2d.implement_fn("death", {}, function()
  return set_block_type(bt_empty)
end)
