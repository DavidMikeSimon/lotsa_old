defmodule Lotsa.Plugin do
  defstruct [
    :name,
    :version,
    :dependencies,
    :setup_fn
  ]

  def load("basis") do
    %Lotsa.Plugin{
      name: "basis",
      version: "0.0.1",
      dependencies: [],
      setup_fn: nil
    }
  end

  def load(name) do
    path_parts = [
      Mix.Project.build_path, "..", "..", "..", "plugins", name, "definition.lua"
    ]
    def_path = Path.expand Path.join(path_parts)
    unless File.exists?(def_path) do
      raise "No such plugin definition file: #{def_path}"
    end

    plugin_def = Lua.eval_file!(Lua.State.new(), def_path)
      |> hd
      |> Lotsa.LuaHelpers.elixirify
    %Lotsa.Plugin{
      name: name,
      version: plugin_def["version"],
      dependencies: plugin_def["dependencies"],
      setup_fn: plugin_def["setup"]
    }
  end

  def calc_plugin_changes(universe, plugin) do
    []
  end

  def dependency_names(plugin) do
    Enum.map(plugin.dependencies, &hd/1)
  end
end
