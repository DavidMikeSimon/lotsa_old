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
        IO.puts("Testing plugin \"#{plugin}\"")
        universe_def = setup_test_universe(plugin)
        IO.inspect(universe_def)
        testset = Lotsa.LuaHelpers.run_script(test_path)
        Enum.each testset["tests"], fn {name, test} ->
          run_test(universe_def, testset, "#{plugin}::#{name}", test)
        end
      else
        IO.puts("No tests provided for plugin \"#{plugin}\"")
      end
    end
  end

  defp setup_test_universe(plugin) do
    Lotsa.UniverseDef.new(0, %{plugins: [[plugin, "*"]]})
  end

  defp run_test(universe_def, testset, test_name, test) do
    initial_chunk = Lotsa.Chunk.new(
      {0,0,0,0},
      string_to_block_types(testset, test, "start")
    )
    {:ok, sim} = Lotsa.Simulator.start(universe_def, %{chunks: [initial_chunk]})
    try do
      {:ok, chunk} = Lotsa.Simulator.get_chunk(sim, {0,0,0,0})
    after
      Lotsa.Simulator.stop(sim)
    end
  end

  def string_to_block_types(testset, test, state_name) do
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
