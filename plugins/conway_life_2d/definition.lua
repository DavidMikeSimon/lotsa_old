-- TODO Separate plugins into a public API (defined as a flat table with access to convenience
-- DSL callbacks) and a private implementation (defined as functions). When one plugin
-- depends upon or extends another, then that should continue to basically work as long as
-- nothing is changed in the dependee's public API. When extending another plugin, you
-- write a function which accepts its API table and returns an altered version.

-- TODO When overriding methods in another plugin, use an alias_method_chain approach to
-- allow access to un-overridden method from elsewhere.

plugin_protocol = "1"

definition = {
  version = "0.0.1",

  dependencies = {
    basis = "*"
  },

  properties = {
    is_alive = { type = "boolean", default = false },
    is_life_spawnable = { type = "boolean", default = false }
  },

  block_types = {
    life = {
      client_hints = { color = "#00f" },
      properties = { is_alive = true }
    }
  },

  block_type_amendments = {
    basis = {
      empty = { properties = { is_life_spawnable = true } }
    }
  },

  selectors = {
    xy_and_diag_neighbors = {
      -- Immediate and diagonal XY neighbors
      {1,0}, {-1,0}, {0,1}, {0,-1},
      {1,1}, {-1,1}, {1,-1}, {-1,-1}
    }
  },

  config = {
    cells_needed_to_spawn = 3,
    min_living_neighbors = 2,
    max_living_neighbors = 3
  },

  rules = {
    spawning = {
      needs = {
        self_is_spawnable = { selector = "self", property = "is_life_spawnable", match = true },

        neighours_alive = {
          selector = "neighbors",
          property = "is_alive",
          match = { at_least = {
            n = { conf = "cells_needed_to_spawn" },
            match = true
          } }
        }
      },

      fn = function()
        bt_life = resolve_block_type("life")
        return function()
          return {{ set_block_type = bt_life }}
        end
      end
    },

    underpopulation_death = {
      needs = {
        self_is_alive = { selector = "self", property = "is_alive", match = true },

        too_few_neighbors_alive = {
          selector = "neighbors",
          property = "is_alive",
          match = { less_than = {
            n = { conf = "min_living_neighbors" },
            match = true
          } }
        }
      },

      fn = function()
        bt_empty = resolve_block_type("empty")
        return function()
          return {{ set_block_type = bt_empty }}
        end
      end
    },

    overpopulation_death = {
      needs = {
        self_is_alive = { selector = "self", property = "is_alive", match = true },

        too_many_neighbors_alive = {
          selector = "neighbors",
          property = "is_alive",
          match = { more_than = {
            n = { conf = "max_living_neighbors" },
            match = true
          } }
        }
      },

      fn = function()
        bt_empty = resolve_block_type("empty")
        return function()
          return {{ set_block_type = bt_empty }}
        end
      end
    }
  }
}
