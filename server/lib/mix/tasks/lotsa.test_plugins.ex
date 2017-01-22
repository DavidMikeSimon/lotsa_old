defmodule Mix.Tasks.Lotsa.TestPlugins do
  use Mix.Task

  @shortdoc "Runs Lua tests for Lotsa plugins"

  def run(args) do
    :gproc.start_link()

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
        tests_def = Lua.eval_file!(Lua.State.new(), test_path)
          |> hd
          |> Lotsa.LuaHelpers.elixirify
        Enum.each tests_def["tests"], fn {name, test} ->
          run_test(universe, tests_def, "#{plugin}::#{name}", test)
        end
      else
        IO.puts("No tests provided for plugin #{plugin}")
      end
    end
  end

  defp setup_test_universe(plugin) do
    Lotsa.Universe.new(0) |> Lotsa.Universe.add_plugin(plugin)
  end

  defp run_test(universe, tests_def, test_name, test) do
    initial_chunk = Lotsa.Chunk.new(
      {0,0,0,0},
      string_to_block_types(tests_def, test, "start")
    )
    {:ok, sim} = Lotsa.Simulator.start(universe, %{chunks: [initial_chunk]})
    try do
      IO.inspect(Lotsa.Simulator.get_chunk_proto(sim, {0,0,0,0}))
    after
      Lotsa.Simulator.stop(sim)
    end
  end

  def string_to_block_types(tests_def, test, state_name) do
    str = test[state_name]
    Enum.map String.split(str), fn(line) ->
      Enum.map String.codepoints(line), fn(char) ->
        case char do
          "-" -> 1
          "S" -> 2
        end
      end
    end
  end
end
