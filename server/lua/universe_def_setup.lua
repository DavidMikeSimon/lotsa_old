local M = require "moses"

local function get_plugin_def(name)
  local path = Lotsa.get_plugin_path(name)
  local pdef = dofile(path)
  if M.isNil(pdef.protocol) then
    error("Protocol missing for \"" .. name .. "\"")
  end
  if pdef.protocol ~= 1 then
    error("Unknown protocol for \"" .. name .. "\", perhaps Lotsa needs an update?")
  end
  return pdef
end

local function indexed_subrc_dsl(type_name, items_list, plugin_name, object_name, defaults)
  -- TODO Validate that plugin_name is a real plugin
  -- TODO Validate that object_name is sensible

  defaults = defaults or {}
  if M.isNil(items_list[object_name]) then
    local idx = M.size(index_list)
    max_idx = M.max(items_list, function(i) return i.index end) or -1
    items_list[object_name] = proto_table(type_name, M.extend({}, defaults, {
      plugin_name = plugin_name,
      name = object_name,
      index = max_idx + 1
    }))
  end

  local sub_rc = items_list[object_name]

  local dsl = {
    get_index = function() return sub_rc.index end
  }

  return sub_rc, dsl
end

local function to_generic_value(v)
  t = {}
  if M.isString(v) then
    t.string = v
  elseif M.isBoolean(v) then
    t.boolean = v
  elseif M.isInteger(v) then
    t.integer = v
  else
    error("Unable to convert \"" .. v .. "\" to GenericValue")
  end

  return proto_table("GenericValue", t)
end

local function new_block_type_setup_dsl(rc, plugin_name, name, extras)
  extras = extras or {}

  local bt_rc, bt_dsl = indexed_subrc_dsl(
    "BlockTypeDef",
    rc.block_types,
    plugin_name,
    name,
    {
      property_provisions = {},
      client_hints = map_table(extras.client_hints or {})
    }
  )

  local function provide_property(prop, source)
    provision = proto_table("BlockTypeDef.PropertyProvision", {
      property = prop.get_index(),
      -- FixedValue is only possible type of property provision for now
      source = proto_table("BlockTypeDef.PropertyProvision.FixedValue", {
        value = source.fixed_value
      })
    })
    M.push(bt_rc.property_provisions, provision)
  end

  return M.extend(bt_dsl, {
    provide_property = provide_property
  })
end

local function protoify_boolean_expression(expression)
  t = {}
  if M.has(expression, "eq") then
    t["eq"] = to_generic_value(expression["eq"])
  elseif M.has(expression, "lt") then
    t["lt"] = to_generic_value(expression["lt"])
  elseif M.has(expression, "gt") then
    t["gt"] = to_generic_value(expression["gt"])
  else
    error("Unable to figure out the boolean expression \"" .. expression .. "\"")
  end

  return proto_table("BooleanExpression", t)
end

local function new_block_rule_setup_dsl(rc, plugin_name, name)
  local rule_rc, rule_dsl = indexed_subrc_dsl(
    "BlockRuleDef",
    rc.block_rules,
    plugin_name,
    name,
    { prereqs = {}, updaters_called = {} }
  )

  local function add_prereq(prereq_name, input, expression)
    M.push(rule_rc.prereqs, proto_table("BlockRuleDef.Prereq", {
      name = prereq_name,
      block_input = input.get_index(),
      expression = protoify_boolean_expression(expression)
    }))
  end

  local function add_call(updater)
    M.push(rule_rc.updaters_called, updater.index)
  end

  return M.extend(rule_dsl, {
    add_prereq = add_prereq,
    add_call = add_call
  })
end

local function new_property_setup_dsl(rc, plugin_name, name, prop_type, options)
  local _, prop_dsl = indexed_subrc_dsl(
    rc.properties,
    plugin_name,
    name,
    { prop_type = prop_type, options = options }
  )

  return prop_dsl
end

local function new_block_input_setup_dsl(rc, plugin_name, name, targets, expression)
  local _, input_dsl = indexed_subrc_dsl(
    rc.plugins[plugin_name].block_inputs,
    plugin_name,
    name,
    { targets = targets, expression = expression }
  )

  return input_dsl
end

local function new_block_updater_declaration_dsl(rc, plugin_name, name)
  local _, updater_dsl = indexed_subrc_dsl(
    rc.plugins[plugin_name].block_updaters,
    plugin_name,
    name
  )

  return updater_dsl
end

local function new_plugin_setup_dsl(rc, plugin_name, plugin)
  -- TODO Validate that plugin_name is sensible
  if M.isNil(rc.plugins[plugin_name]) then
    major_v, minor_v, patch_v = string.match(plugin.version, "^(%d+).(%d+).(%d+)")
    if M.isNil(major_v) then
      error("Couldn't parse plugin version in \"" .. plugin_name .. "\"")
    end

    max_load_order = M.max(rc.plugins, function(p) return p.load_order end) or -1

    rc.plugins[plugin_name] = proto_table("PluginDescription", {
      name = plugin_name,
      version = proto_table("PluginDescription.Version", {
        major = major_v,
        minor = minor_v,
        patch = patch_v
      }),
      load_order = max_load_order + 1,
      lua_impls = {}
    })
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

  local function define_property(name, prop_type, options)
    options = options or {}
    return new_property_setup_dsl(rc, plugin_name, name, prop_type, options)
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
    define_property = define_property,
    define_block_type = define_block_type,
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

local function proto_table(proto_name, contents)
  contents = contents or {}
  return M.extend({_table_type = {proto = proto_name}}, contents)
end

local function map_table(contents)
  contents = contents or {}
  return M.extend({_table_type = "map"}, contents)
end

local function get_rc_plugin(rc, plugin_name)
  M.findWhere(rc.plugins, { name = plugin_name })
end

local function setup(universe_num, config)
  local rc = proto_table("UniverseDef", {
    num = universe_num,
    plugins = map_table(),
    properties = map_table(),
    block_types = map_table(),
    block_inputs = map_table(),
    block_rules = map_table(),
    block_updaters = map_table()
  })

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
