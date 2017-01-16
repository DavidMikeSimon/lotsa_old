defmodule Mix.Tasks.Chunkosm.TestPlugins do
  use Mix.Task

  @shortdoc "Runs Lua tests for Chunkosm plugins"

  def run(args) do
    plugins_dir = Path.expand Path.join([Mix.Project.build_path, "..", "..", "..", "plugins"])
    target_plugins = case args do
      [] -> File.ls!(plugins_dir)
      targets -> targets
    end

    Enum.each target_plugins, fn plugin ->
      IO.puts("Testing plugin #{plugin}")
    end
  end
end
