return {
  protocol = 1,
  version = "0.0.1",
  dependencies = {
    {"basis", "*"}
  },
  setup = function(p) 
    is_alive = p.define_property("is_alive", "boolean", {
      default_value = false
    })

    is_life_spawnable = p.define_property("is_life_spawnable", "boolean", {
      default_value = false
    })

    bt_life = p.define_block_type("life", {
      client_hints = { color = "#00f" }
    })
    bt_life.has_property(is_alive, { fixed_value = true })

    bt_empty = p.get_dependency("basis").get_block_type("empty")
    bt_empty.has_property(is_life_spawnable, { fixed_value = true })

    input_self_is_spawnable = p.define_input(
      "self_is_spawnable",
      targets.self(),
      expr.singular_value(is_life_spawnable)
    )

    input_self_is_alive = p.define_input(
      "self_is_alive",
      targets.self(),
      expr.singular_value(is_alive)
    )

    input_number_of_neighbors_alive = p.define_input(
      "number_of_neighbors_alive",
      targets.chebyshev_neighbors(1),
      expr.count_where(is_alive, expr.eq(true))
    )

    u_spawn = p.define_updater("spawn")

    p.define_rule("spawning", function(r)
      r.prereq("can_spawn", input_self_is_spawnable, expr.eq(true))
      r.prereq("has_parents", input_number_of_neighbors_alive, expr.eq(3))
      r.calls(u_spawn)
    end)

    u_death = p.define_updater("death")

    p.define_rule("underpopulation_death", function(r)
      r.prereq("alive", input_self_is_alive, expr.eq(true))
      r.prereq("too_few_neighbors", input_number_of_neighbors_alive, expr.lt(2))
      r.calls(u_death)
    end)

    p.define_rule("overpopulation_death", function(r)
      r.prereq("alive", input_self_is_alive, expr.eq(true))
      r.prereq("too_many_neighbors", input_number_of_neighbors_alive, expr.gt(4))
      r.calls(u_death)
    end)
  end
}

