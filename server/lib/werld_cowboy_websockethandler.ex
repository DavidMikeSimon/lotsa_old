defmodule Werld.Cowboy.WebSocketHandler do
    @behaviour :cowboy_websocket_handler

    def init({:tcp, :http}, _req, _opts) do
        {:upgrade, :protocol, :cowboy_websocket}
    end

    def websocket_init(_transport_name, req, _opts) do
        {:ok, req, :undefined_state, 60000}
    end

    def websocket_handle({:binary, data}, req, state) do
        client_req = Werld.Proto.MessageToServer.decode(data)
        case client_req.msg do
            {:chunk_request, chunk_request} ->
                Enum.each chunk_request.coords, fn(coord) ->
                    send self(), {:send_chunk, get_chunk(coord)}
                end
                {:ok, req, state}
            {:heartbeat, heartbeat} ->
                response = Werld.Proto.MessageToClient.new(msg: {:heartbeat_ack, heartbeat})
                response_enc = Werld.Proto.MessageToClient.encode(response)
                {:reply, {:binary, response_enc}, req, state}
        end
    end

    def websocket_handle(_data, req, state) do
        # Ignore text data and pings/pongs
        {:ok, req, state}
    end

    def websocket_info({:send_chunk, chunk}, req, state) do
        msg = Werld.Proto.MessageToClient.new(msg: {:chunk, chunk})
        msg_enc = Werld.Proto.MessageToClient.encode(msg)
        {:reply, {:binary, msg_enc}, req, state}
    end

    def websocket_terminate(_reason, _req, _state) do
        :ok
    end

    defp get_chunk(coord) do
        Werld.Proto.Chunk.new(
            pos: Werld.Proto.Coord.new(
                instance: coord.instance,
                grid: coord.grid,
                x: coord.x,
                y: coord.y
            ),
            ver: 50,
            block_runs: [
                Werld.Proto.Chunk.BlockRun.new(
                    count: 20,
                    block_type: 0
                ),
                Werld.Proto.Chunk.BlockRun.new(
                    count: 50,
                    block_type: 1
                ),
                Werld.Proto.Chunk.BlockRun.new(
                    count: 186,
                    block_type: 0
                ),
            ]
        )
    end
end
