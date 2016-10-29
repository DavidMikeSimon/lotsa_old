defmodule Werld.Cowboy do
    @behaviour :application
    
    def start(_type, _args) do
        dispatch = :cowboy_router.compile([
          {:_, [
            {"/websocket", Werld.Cowboy.WebSocketHandler, []}
          ]}
        ])
        {:ok, _} = :cowboy.start_http(:http, 100, [{:port, 3000}],
                                      [{:env, [{:dispatch, dispatch}]}])

        Werld.Cowboy.Supervisor.start_link
    end

    def stop(_state) do
        :ok
    end
end