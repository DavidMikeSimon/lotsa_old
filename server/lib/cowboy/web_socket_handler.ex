defmodule Chunkosm.Cowboy.WebSocketHandler do
  @behaviour :cowboy_websocket_handler

  alias Chunkosm.Proto.MessageToServer
  alias Chunkosm.Proto.MessageToClient

  def init({:tcp, :http}, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_transport_name, req, _opts) do
    {:ok, req, :undefined_state, 60000}
  end

  def websocket_handle({:binary, data}, req, state) do
    client_req = MessageToServer.decode(data)
    case client_req.msg do
      {:chunk_request, chunk_request} ->
        Enum.each chunk_request.coords, fn(coord) ->
          send self(), {:send_chunk, get_chunk(coord)}
        end
        {:ok, req, state}
      {:heartbeat, heartbeat} ->
        response = %MessageToClient{msg: {:heartbeat_ack, heartbeat}}
        response_enc = MessageToClient.encode(response)
        {:reply, {:binary, response_enc}, req, state}
    end
  end

  def websocket_handle(_data, req, state) do
    # Ignore text data and pings/pongs
    {:ok, req, state}
  end

  def websocket_info({:send_chunk, chunk}, req, state) do
    msg = %MessageToClient{msg: {:chunk, chunk}}
    msg_enc = MessageToClient.encode(msg)
    {:reply, {:binary, msg_enc}, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

  defp get_chunk(coord) do
    chunk_server = :gproc.lookup_pid({:n, :l, :simulator}) # FIXME temporary name
    Chunkosm.Simulator.get_chunk_proto(chunk_server, coord)
  end
end
