defmodule LotsaTest do
  use ExUnit.Case

  defp hinge_port_pid() do
    # FIXME: Maybe should start HingePort in test, not in app
    :gproc.lookup_pid({:n, :l, :hinge_port})
  end

  test "connecting to HingePort" do
    assert "pong" == Lotsa.HingePort.ping(hinge_port_pid())
  end

  test "creating a UniverseDef from a minimal config with HingePort" do
    config = %{
      url: "http://example.com/lotsa/1",
      plugins: [ ["basis", "*"] ]
    }

    expected = %Lotsa.Proto.UniverseDef{
      url: "http://example.com/lotsa/1",
      block_types: %{
        "basis:unknown" => %Lotsa.Proto.BlockTypeDef{
          plugin_name: "basis",
          name: "unknown",
          index: 0,
          client_hints: %{
            "color" => "#000",
          }
        },
        "basis:empty" => %Lotsa.Proto.BlockTypeDef{
          plugin_name: "basis",
          name: "empty",
          index: 1,
          client_hints: %{
            "color" => "#fff",
          }
        }
      }
    }

    assert expected == Lotsa.HingePort.load_config(hinge_port_pid(), config)
  end
end
