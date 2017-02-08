return function(i)
  local bt_life = i.fetch_block_type("conway_life_2d", "life")
  local bt_empty = i.fetch_block_type("basis", "empty")

  i.implement_block_updater("spawn", {}, function()
    return { block_type = bt_life }
  end)

  i.implement_block_updater("death", {}, function()
    return { block_type = bt_empty }
  end)
end
