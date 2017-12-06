defmodule LotsaTest do
  use ExUnit.Case

  def universe_js_pid() do
    # FIXME: Maybe should start UniverseJS in test, not in app
    :gproc.lookup_pid({:n, :l, :universe_js})
  end

  test "connecting to UniverseJS" do
    assert "pong" == Lotsa.UniverseJS.ping(universe_js_pid())
  end

  test "creating a UniverseDef from a minimal config with UniverseJS" do
    config = JSON.encode!([
      url: "http://example.com/lotsa/1",
      plugins: [ ["basis", "*"] ]
    ])

    expected = %Lotsa.Proto.UniverseDef{
      url: "http://example.com/lotsa/1",
      block_types: %{
        "basis:unknown" => %Lotsa.Proto.BlockTypeDef{
          plugin_name: "basis",
          name: "unknown",
          index: 0,
          client_hints: %{
            color: "#000",
          }
        },
        "basis:empty" => %Lotsa.Proto.BlockTypeDef{
          plugin_name: "basis",
          name: "empty",
          index: 1,
          client_hints: %{
            color: "#fff",
          }
        }
      }
    }

    assert expected == Lotsa.UniverseJS.load_config(universe_js_pid(), config)
  end
end
