conway_life_2d = plugin.setup({
  protocol = 1,
  version = "0.0.1",
  dependencies = {
    basis = "*"
  }
})

is_alive = conway_life_2d.define_property("is_alive", "boolean", {
  default_value = false
})

is_life_spawnable = conway_life_2d.define_property("is_life_spawnable", "boolean", {
  default_value = false
})

bt_life = conway_life_2d.define_block_type("life", {
  client_hints = { color = "#00f" }
})
bt_life.has_property(is_alive, { fixed_value = true })

bt_empty = conway_life_2d.get_dependency("basis").get_block_type("empty")
bt_empty.has_property(is_life_spawnable, { fixed_value = true })

input_self_is_spawnable = conway_life_2d.define_input(
  "self_is_spawnable",
  targets.self(),
  expr.singular_value(is_life_spawnable)
)

input_self_is_alive = conway_life_2d.define_input(
  "self_is_alive",
  targets.self(),
  expr.singular_value(is_alive)
)

input_number_of_neighbors_alive = conway_life_2d.define_input(
  "number_of_neighbors_alive",
  targets.chebyshev_neighbors(1),
  expr.count_where(is_alive, expr.eq(true))
)

fn_spawn = conway_life_2d.define_fn("spawning")

spawning_rule = conway_life_2d.define_rule("spawning")
spawning_rule.uses(input_self_is_spawnable, { skip_unless = expr.eq(true) })
spawning_rule.uses(input_number_of_neighbors_alive, { skip_unless = expr.eq(3) })
spawning_rule.calls(fn_spawn)

fn_death = conway_life_2d.define_fn("death")

underpopulation_death_rule = conway_life_2d.define_rule("underpopulation_death")
underpopulation_death_rule.uses(input_self_is_alive, { skip_unless = expr.eq(true) })
underpopulation_death_rule.uses(input_number_of_neighbors_alive, { skip_unless = expr.lt(2) })
underpopulation_death_rule.calls(fn_death)

overpopulation_death_rule = conway_life_2d.define_rule("overpopulation_death")
overpopulation_death_rule.uses(input_self_is_alive, { skip_unless = expr.eq(true) })
overpopulation_death_rule.uses(input_number_of_neighbors_alive, { skip_unless = expr.gt(4) })
overpopulation_death_rule.calls(fn_death)
