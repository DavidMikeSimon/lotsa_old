defmodule Werld.Cowboy.WebSocketHandler do
    @behaviour :cowboy_websocket_handler

    def init({:tcp, :http}, _req, _opts) do
        {:upgrade, :protocol, :cowboy_websocket}
    end

    def websocket_init(_transport_name, req, _opts) do
        :erlang.start_timer(1000, self(), :send_chunk)
        :erlang.start_timer(2000, self(), :send_message)
        {:ok, req, :undefined_state}
    end

    def websocket_handle(_data, req, state) do
        {:ok, req, state}
    end

    def websocket_info({:timeout, _ref, :send_chunk}, req, state) do
        :erlang.start_timer(2000, self(), :send_chunk)
        chunk = Werld.Proto.Chunk.new(x: 1, y: 2, z: 3, ver: 50)
        msg = Werld.Proto.MessageToClient.new(msg: {:chunk, chunk})
        enc = Werld.Proto.MessageToClient.encode(msg)
        {:reply, {:binary, enc}, req, state}
    end

    def websocket_info({:timeout, _ref, :send_message}, req, state) do
        :erlang.start_timer(5000, self(), :send_message)
        msg = Werld.Proto.MessageToClient.new(msg: {:global_notice, "Stuff is happening"})
        enc = Werld.Proto.MessageToClient.encode(msg)
        {:reply, {:binary, enc}, req, state}
    end

    def websocket_info(_info, req, state) do
        {:ok, req, state}
    end

    def websocket_terminate(_reason, _req, _state) do
        :ok
    end
end
