local M = require "moses"

local function get_plugin_def(name)
  local path = Lotsa.get_plugin_path(name)
  return dofile(path)
  -- TODO Verify protocol version
end

local function allocate_index(index_list, plugin_name, object_name)
  local idx = M.size(index_list)
  index_list[idx] = { plugin_name, object_name }
  return idx
end

local function new_block_type_setup_dsl(rc, plugin_name, name, options)
  options = options or {}

  local bt_index = nil
  if M.isNil(rc.plugins[plugin_name].block_types[name]) then
    bt_index = allocate_index(rc.block_type_indexes, plugin_name, name)
    rc.plugins[plugin_name].block_types[name] = {
      index = bt_index,
      properties = {}
    }
  else
    bt_index = rc.plugins[plugin_name].block_types[name].index
  end

  local function has_property(prop, prop_options)
    prop_options = prop_options or {}
  end

  return {
    has_property = has_property
  }
end

local function new_block_rule_setup_dsl(rc, plugin_name, name)
  local rule_index = nil
  if M.isNil(rc.plugins[plugin_name].block_rules[name]) then
    rule_index = allocate_index(rc.block_rule_indexes, plugin_name, name)
    rc.plugins[plugin_name].block_rules[name] = {
      index = rule_index,
      properties = {}
    }
  else
    rule_index = rc.plugins[plugin_name].block_rules[name].index
  end

  local function add_prereq(prereq_name, input, expression)
  end

  local function calls(updater)
  end

  return {
    add_prereq = add_prereq,
    calls = calls
  }
end

local function new_plugin_setup_dsl(rc, plugin_name, plugin)
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
  end

  local function define_block_input(name, targets, expression)
  end

  local function define_block_rule(name)
    return new_block_rule_setup_dsl(rc, plugin_name, name)
  end

  local function declare_block_updater(name)
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

  local dep_names = M.map(plugin.dependencies, function(i,v) return v[1] end)
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
