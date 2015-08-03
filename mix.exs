defmodule Werld.Mixfile do
  use Mix.Project

  def project do
    [
        app: :werld,
        version: "0.0.1",
        elixir: "~> 1.0",
        compilers: [:exprotoc, :elixir, :app],
        exprotoc: [
          paths: ["proto"],
          files: ["werld.proto"],
          prefix: "Werld"
        ],
        deps: deps,
        aliases: aliases
    ]
  end

  def application do
    [
        applications: [:logger, :cowboy],
        mod: {Werld.Cowboy, []}
    ]
  end

  defp deps do
    [
        {:cowboy, "~> 1.0.0"},
        {:exprotoc, github: "2all/exprotoc"}
    ]
  end

  defp aliases do
    [
        #compile: ["exprotoc.build proto --prefix Werld", "compile"],
        clean: ["clean", "exprotoc.clean"]
    ]
  end
end
