defmodule Lotsa.App do
  use Application

  def start(_type, _args) do
    Lotsa.SimulatorSupervisor.start_link()

    {:ok, _} = :cowboy.start_http(:http, 100, [port: 3000], [env: [
      dispatch: :cowboy_router.compile([
        {:_, [
          {"/websocket", Lotsa.Cowboy.WebSocketHandler, []}
        ]}
      ])
    ]])
  end
end
