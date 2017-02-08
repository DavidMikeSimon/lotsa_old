defmodule Lotsa.UniverseDef do
  defstruct [
    :num,
    :plugin_load_order,
    :plugins,
    :block_type_indexes
  ]

  def new(num, config) do
    rc = resolve_config(config)
    # TODO Assert that unknown bt is 0 and empty bt is 1
    IO.inspect(rc)

    %Lotsa.UniverseDef{
      num: num,
      plugin_load_order: rc["plugin_load_order"],
      plugins: rc["plugins"],
      block_type_indexes: rc["block_type_indexes"]
    }
  end

  def has_plugin?(universe, plugin_name) do
    Map.has_key?(universe.plugins, plugin_name)
  end

  defp resolve_config(config) do
    setup_lib = Lotsa.LuaHelpers.load_library("universe_def_setup", [
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

    Lotsa.LuaHelpers.call_library_func(setup_lib, "setup", [config])
  end
end
