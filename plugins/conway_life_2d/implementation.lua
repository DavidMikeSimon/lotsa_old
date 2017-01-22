basis = lotsa.get_plugin("basis")
bt_empty = basis.get_block_type("empty")

conway_life_2d = lotsa.get_plugin("conway_life_2d")
bt_life = conway_life_2d.get_block_type("life")

conway_life_2d.implement_updater("spawn", {}, function()
  return set_block_type(bt_life)
end)

conway_life_2d.implement_updater("death", {}, function()
  return set_block_type(bt_empty)
end)
