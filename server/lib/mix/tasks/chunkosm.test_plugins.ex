defmodule Mix.Tasks.Chunkosm.TestPlugins do
  use Mix.Task

  @shortdoc "Runs Lua tests for Chunkosm plugins"

  def run(args) do
    path_parts = [Mix.Project.build_path, "..", "..", "..", "plugins"]
    plugins_dir = Path.expand Path.join(path_parts)
    target_plugins = case args do
      [] -> File.ls!(plugins_dir)
      targets -> targets
    end

    Enum.each target_plugins, fn plugin ->
      test_path = Path.join([plugins_dir, plugin, "tests.lua"])
      if File.exists?(test_path) do
        IO.puts("Testing plugin #{plugin}")
        universe = setup_test_universe(plugin)
        [tests_def] = Lua.eval_file!(Lua.State.new(), test_path)
        tests_def = Chunkosm.LuaHelpers.elixirify(tests_def)
        IO.inspect(tests_def)
      else
        IO.puts("No tests provided for plugin #{plugin}")
      end
    end
  end

  defp setup_test_universe(plugin) do
    Chunkosm.Universe.new(0, %{plugins: [plugin]})
  end
end
