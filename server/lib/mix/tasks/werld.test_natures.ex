defmodule Mix.Tasks.Werld.TestNatures do
  use Mix.Task

  @shortdoc "Runs Lua tests for Werld natures"

  def run(args) do
    natures_dir = Path.expand Path.join([Mix.Project.build_path, "..", "..", "..", "natures"])
    target_natures = case args do
      [] -> File.ls!(natures_dir)
      targets -> targets
    end

    Enum.each target_natures, fn nature ->
      IO.puts("Testing nature #{nature}")
    end
  end
end
