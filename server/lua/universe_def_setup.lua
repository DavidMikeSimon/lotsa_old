local M = require "moses"

local function get_plugin_def(name)
  local path = Lotsa.get_plugin_path(name)
  return dofile(path)
  -- TODO Verify protocol version
end

local function indexed_subrc_dsl(index_list, items_list, plugin_name, object_name, defaults)
  -- TODO Validate that object_name is sensible
  defaults = defaults or {}
  if M.isNil(index_list[object_name]) then
    local idx = M.size(index_list)
    index_list[idx] = { plugin_name, object_name }
    items_list[object_name] = M.extend({}, defaults, { index = idx })
  end

  local rc = items_list[object_name]

  local dsl = {
    get_index = function() return rc.index end,
    get_desc = function() return {rc.index, plugin_name, object_name} end
  }

  return rc, dsl
end

local function new_block_type_setup_dsl(rc, plugin_name, name, extras)
  extras = extras or {}

  local bt_rc, bt_dsl = indexed_subrc_dsl(
    rc.block_type_indexes,
    rc.plugins[plugin_name].block_types,
    plugin_name,
    name,
    { properties = {}, extras = extras }
  )

  local function has_property(prop, prop_options)
    prop_options = prop_options or {}
    M.push(bt_rc.properties, { prop = prop.get_desc(), options = prop_options } )
  end

  return M.extend(bt_dsl, {
    has_property = has_property
  })
end

local function new_block_rule_setup_dsl(rc, plugin_name, name)
  local rule_rc, rule_dsl = indexed_subrc_dsl(
    rc.block_rule_indexes,
    rc.plugins[plugin_name].block_rules,
    plugin_name,
    name,
    { prereqs = {}, calls = {} }
  )

  local function add_prereq(prereq_name, input, expression)
    M.push(rule_rc.prereqs, {
      name = prereq_name,
      input = input.get_desc(),
      expression = expression
    })
  end

  local function add_call(updater)
    M.push(rule_rc.calls, {
      updater = updater.get_desc()
    })
  end

  return M.extend(rule_dsl, {
    add_prereq = add_prereq,
    add_call = add_call
  })
end

local function new_block_property_setup_dsl(rc, plugin_name, name, prop_type, options)
  local _, prop_dsl = indexed_subrc_dsl(
    rc.block_property_indexes,
    rc.plugins[plugin_name].block_properties,
    plugin_name,
    name,
    { prop_type = prop_type, options = options }
  )

  return prop_dsl
end

local function new_block_input_setup_dsl(rc, plugin_name, name, targets, expression)
  local _, input_dsl = indexed_subrc_dsl(
    rc.block_input_indexes,
    rc.plugins[plugin_name].block_inputs,
    plugin_name,
    name,
    { targets = targets, expression = expression }
  )

  return input_dsl
end

local function new_block_updater_declaration_dsl(rc, plugin_name, name)
  local _, updater_dsl = indexed_subrc_dsl(
    rc.block_updater_indexes,
    rc.plugins[plugin_name].block_updaters,
    plugin_name,
    name
  )

  return updater_dsl
end

local function new_plugin_setup_dsl(rc, plugin_name, plugin)
  -- TODO Validate that plugin_name is sensible
  if M.isNil(rc.plugins[plugin_name]) then
    M.push(rc.plugin_load_order, plugin_name)

    rc.plugins[plugin_name] = {
      version = plugin.version,
      block_types = {},
      block_properties = {},
      block_inputs = {},
      block_rules = {},
      block_updaters = {}
    }
  end

  local function get_dependency(name)
    if M.isNil(rc.plugins[name]) then
      error("No such plugin \"" .. name .. "\" loaded")
    end
    -- TODO Check if actual dependency of this plugin
    return new_plugin_setup_dsl(rc, name, get_plugin_def(name))
  end

  local function get_block_type(name)
    if M.isNil(rc.plugins[plugin_name].block_types[name]) then
      error("No such block_type \"" .. name .. "\" for plugin \"" .. plugin_name .. "\"")
    end
    return new_block_type_setup_dsl(rc, plugin_name, name)
  end

  local function define_block_type(name, options)
    options = options or {}
    return new_block_type_setup_dsl(rc, plugin_name, name, options)
  end

  local function define_block_property(name, prop_type, options)
    options = options or {}
    return new_block_property_setup_dsl(rc, plugin_name, name, prop_type, options)
  end

  local function define_block_input(name, targets, expression)
    return new_block_input_setup_dsl(rc, plugin_name, name, targets, expression)
  end

  local function define_block_rule(name)
    return new_block_rule_setup_dsl(rc, plugin_name, name)
  end

  local function declare_block_updater(name)
    return new_block_updater_declaration_dsl(rc, plugin_name, name)
  end

  return {
    get_dependency = get_dependency,
    get_block_type = get_block_type,
    define_block_type = define_block_type,
    define_block_property = define_block_property,
    define_block_input = define_block_input,
    define_block_rule = define_block_rule,
    declare_block_updater = declare_block_updater
  }
end

local function resolve_plugins(pending, stack, resolved)
  stack = stack or {}
  resolved = resolved or {}

  if #pending == 0 then
    return resolved
  end

  -- TODO Verify that version spec fits
  local name = M.pop(pending)[1]
  local plugin = get_plugin_def(name)

  local dep_names = M.map(plugin.dependencies, function(_,v) return v[1] end)
  local circular_deps = M.intersection(dep_names, stack)
  if M.size(circular_deps) > 0 then
    error("Circular dependency from " .. name .. " on " .. circular_deps[1])
  end

  local dep_plugins = resolve_plugins(plugin.dependencies, M.append(stack, {name}), {})
  resolved = M.uniq(M.append(M.append(resolved, dep_plugins), {name}))
  return resolve_plugins(pending, stack, resolved)
end

local function setup(config)
  local rc = {
    plugin_load_order = {},
    plugins = {},
    block_type_indexes = {},
    block_property_indexes = {},
    block_input_indexes = {},
    block_rule_indexes = {},
    block_updater_indexes = {}
  }

  local plugins = resolve_plugins(config.plugins)
  -- TODO Complain if dep resolution puts a plugin earlier in the list than requested

  for _, name in ipairs(plugins) do
    local plugin = get_plugin_def(name)
    local setup_dsl = new_plugin_setup_dsl(rc, name, plugin)
    plugin.setup(setup_dsl)
  end

  return rc
end

return {
  setup = setup
}
