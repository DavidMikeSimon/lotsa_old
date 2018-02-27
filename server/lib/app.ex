defmodule Lotsa.App do
  use Application

  def start(_type, _args) do
    Lotsa.SimulatorSupervisor.start_link()
    Lotsa.HingePort.start_link()

    {:ok, _} = :cowboy.start_http(:http, 100, [port: 3300], [env: [
      dispatch: :cowboy_router.compile([
        {:_, [
          {"/websocket", Lotsa.Cowboy.WebSocketHandler, []}
        ]}
      ])
    ]])
  end
end
