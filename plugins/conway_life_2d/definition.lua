return {
  protocol = 1,
  version = "0.0.1",
  dependencies = {
    {"basis", "*"}
  },
  setup = function(p)
    local block_targets = require "block_targets"
    local expr = require "expr"

    local basis = p.get_dependency("basis")

    local is_alive = p.define_block_property("is_alive", "boolean", {
      default_value = false
    })

    local is_life_spawnable = p.define_block_property("is_life_spawnable", "boolean", {
      default_value = false
    })

    local bt_life = p.define_block_type("life", {
      client_hints = { color = "#00f" }
    })
    bt_life.has_property(is_alive, { fixed_value = true })

    local bt_empty = basis.get_block_type("empty")
    bt_empty.has_property(is_life_spawnable, { fixed_value = true })

    local input_self_is_spawnable = p.define_block_input(
      "self_is_spawnable",
      block_targets.self(),
      expr.singular_value(is_life_spawnable)
    )

    local input_self_is_alive = p.define_block_input(
      "self_is_alive",
      block_targets.self(),
      expr.singular_value(is_alive)
    )

    local input_num_neighbors_alive = p.define_block_input(
      "num_neighbors_alive",
      block_targets.chebyshev_neighbors(1),
      expr.count_where(is_alive, expr.eq(true))
    )

    local u_spawn = p.declare_block_updater("spawn")

    local r_spawning = p.define_block_rule("spawning")
    r_spawning.add_prereq("can_spawn", input_self_is_spawnable, expr.eq(true))
    r_spawning.add_prereq("has_parents", input_num_neighbors_alive, expr.eq(3))
    r_spawning.add_call(u_spawn)

    local u_death = p.declare_block_updater("death")

    local r_underpop_death = p.define_block_rule("underpop_death")
    r_underpop_death.add_prereq("alive", input_self_is_alive, expr.eq(true))
    r_underpop_death.add_prereq("too_few_neighbors", input_num_neighbors_alive, expr.lt(2))
    r_underpop_death.add_call(u_death)

    local r_overpop_death = p.define_block_rule("overpop_death")
    r_overpop_death.add_prereq("alive", input_self_is_alive, expr.eq(true))
    r_overpop_death.add_prereq("too_many_neighbors", input_num_neighbors_alive, expr.gt(4))
    r_overpop_death.add_call(u_death)
  end
}
