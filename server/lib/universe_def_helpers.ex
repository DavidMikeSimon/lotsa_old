defmodule Lotsa.UniverseDefHelpers do
  def new_from_config(num, config) do
    rc = resolve_config(config)
    unless rc["block_type_indexes"][0] == ["basis", "unknown"] do
      raise "Block type index 0 must be basis:unknown"
    end
    unless rc["block_type_indexes"][1] == ["basis", "empty"] do
      raise "Block type index 1 must be basis:empty"
    end

    IO.inspect(rc)
    # TODO Validation on structs created, maybe with Vex or similar library

    %Lotsa.Proto.UniverseDef{
      num: num,
      #plugins: LH.assume_map(rc["plugins"], &PluginDef.from_lua/1),
      #block_type_indexes: LH.assume_map(rc["block_type_indexes"]),
      #block_property_indexes: LH.assume_map(rc["block_property_indexes"]),
      #block_input_indexes: LH.assume_map(rc["block_input_indexes"]),
      #block_rule_indexes: LH.assume_map(rc["block_rule_indexes"]),
      #block_updater_indexes: LH.assume_map(rc["block_updater_indexes"])
    }
  end

  def has_plugin?(universe, plugin_name) do
    Map.has_key?(universe.plugins, plugin_name)
  end

  defp resolve_config(config) do
    alias Lotsa.LuaHelpers, as: LH

    setup_lib = LH.load_library("universe_def_setup", [
      get_plugin_path: fn([name]) ->
        path_parts = [
          Mix.Project.build_path, "..", "..", "..", "plugins", name, "definition.lua"
        ]
        def_path = Path.expand Path.join(path_parts)
        unless File.exists?(def_path) do
          raise "No such plugin definition file: #{def_path}"
        end
        def_path
      end
    ])

    LH.call_library_func(setup_lib, "setup", [config])
  end
end
