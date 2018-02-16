defmodule Lotsa.Mixfile do
  use Mix.Project

  def project do
    [
      app: :lotsa,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps()
    ]
  end

  def application do
    [
      applications: [
        :logger, :cowboy, :gproc, :protox, :runtime_tools
      ],
      mod: {Lotsa.App, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:protox, "~> 0.16.1"},
      {:gproc, "0.6.1"},
      {:json, "~> 1.0"}
    ]
  end
end
