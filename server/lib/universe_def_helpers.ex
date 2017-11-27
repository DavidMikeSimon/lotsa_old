defmodule Lotsa.UniverseDefHelpers do
  def new_from_config(num, config) do
    universe_def = resolve_config(num, config)

    bt_def_0 = universe_def.block_types[0]
    unless bt_def_0.plugin_name == "basis" && bt_def_0.name == "unknown" do
      raise "Block type index 0 must be basis:unknown"
    end

    bt_def_1 = universe_def.block_types[1]
    unless bt_def_1.plugin_name == "basis" && bt_def_1.name == "empty" do
      raise "Block type index 1 must be basis:empty"
    end

    universe_def
  end

  def validate_universe_def(universe_def) do
    # TODO: Assert that actual list indexes and internal indexes match
    # TODO: Assert that all index references point at something real
    # TODO: Assert that PluginDescription load_orders are contiguous from 0
  end

  defp get_plugin_path(name) do
    path_parts = [
      Mix.Project.build_path, "..", "..", "..", "plugins", name, "definition.lua"
    ]
    def_path = Path.expand Path.join(path_parts)
    unless File.exists?(def_path) do
      raise "No such plugin definition file: #{def_path}"
    end
    def_path
  end

  defp resolve_config(num, config) do
    alias Lotsa.LuaHelpers, as: LH

    setup_lib = LH.load_library("universe_def_setup", [
      get_plugin_path: fn [name] -> get_plugin_path(name) end
    ])

    universe_def = LH.call_library_func(setup_lib, "setup", [num, config])
    validate_universe_def(universe_def)
    universe_def
  end
end
