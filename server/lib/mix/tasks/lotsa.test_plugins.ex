require ExUnit.Assertions
import ExUnit.Assertions

defmodule Mix.Tasks.Lotsa.TestPlugins do
  use Mix.Task

  @shortdoc "Runs Lua tests for Lotsa plugins"

  defp hinge_port_pid() do
    # FIXME: Maybe should start HingePort in test, not in app
    :gproc.lookup_pid({:n, :l, :hinge_port})
  end

  def run(args) do
    :gproc.start_link()
    Lotsa.HingePort.start_link()

    plugins_dir = [Mix.Project.build_path, "..", "..", "..", "plugins"] |> Path.join |> Path.expand
    target_plugins = case args do
      [] -> File.ls!(plugins_dir)
      targets -> targets
    end

    Enum.each target_plugins, fn plugin ->
      IO.puts("Testing plugin \"#{plugin}\"")
      test_plugin(plugin)
    end
  end

  defp test_plugin(plugin) do
    testset = Lotsa.HingePort.load_tests(hinge_port_pid(), plugin)
    if Map.has_key?(testset, "tests") do
      universe_def = setup_test_universe(plugin)
      Enum.each testset["tests"], fn {name, test} ->
        run_test(universe_def, testset, "#{plugin}::#{name}", test)
      end
    else
      # TODO Complain if the plugin doesn't exist at all
      IO.puts("No tests provided for plugin \"#{plugin}\"")
    end
  end

  defp setup_test_universe(plugin) do
    Lotsa.HingePort.load_config(
      hinge_port_pid(),
      %{
        url: "test://#{plugin}",
        plugins: [ [plugin, "*"] ]
      }
    )
  end

  defp run_test(universe_def, testset, test_name, test) do
    IO.puts("Running test #{test_name}")

    initial_chunk = Lotsa.Chunk.new(
      {0,0,0,0},
      string_to_block_types(universe_def, testset, Enum.at(test, 0))
    )

    {:ok, sim} = Lotsa.Simulator.start(universe_def, %{chunks: [initial_chunk]})

    try do
      Enum.map 1..(length(test)-1), fn(step_num) ->
        IO.puts("Step #{step_num}")

        {:ok, got_chunk} = Lotsa.Simulator.get_chunk(sim, {0,0,0,0})

        expected_str = expected_chunk_str(test, step_num)
        expected_chunk = Lotsa.Chunk.new(
          {0,0,0,0},
          string_to_block_types(universe_def, testset, expected_str)
        )

        ExUnit.Assertions.assert got_chunk == expected_chunk;
      end
    after
      Lotsa.Simulator.stop(sim)
    end
  end

  defp expected_chunk_str(test, step_num) do
    case Enum.at(test, step_num) do
      %{"sameAs" => "start"} -> Enum.at(test, 0)
      %{"sameAs" => "prev"} -> expected_chunk_str(test, step_num - 1)
      chunk_str -> chunk_str
    end
  end

  defp string_to_block_types(universe_def, testset, str) do
    Enum.map String.split(str), fn(line) ->
      Enum.map String.codepoints(line), fn(char) ->
        block_type = Map.fetch!(testset["aliases"], char)
        block = Map.fetch!(universe_def.block_types, block_type)
        block.index
      end
    end
  end
end
