defmodule Chunkosm.Mixfile do
  use Mix.Project

  def project do
    [
      app: :chunkosm,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps
    ]
  end

  def application do
    [
      applications: [
        :logger, :cowboy, :exprotobuf, :gproc, :runtime_tools
      ],
      mod: {Chunkosm.App, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:exprotobuf, "~> 1.2.0"},
      {:gproc, "0.6.1"},
      {:luerl, github: "bendiken/luerl", branch: "exlua",
        compile: "make && cp src/luerl.app.src ebin/luerl.app"},
      {:exlua, "~> 0.3.0"}
    ]
  end
end
