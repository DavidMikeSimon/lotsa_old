defmodule Werld.Sim.Chunk do
  use GenServer

  ####
  ## Client API
  ####
  
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def get_chunk_proto(server) do
    GenServer.call(server, :get_chunk_proto)
  end

  ####
  ## Server Callbacks
  ####

  def init(:ok) do
    :gproc.reg({:n, :l, {:chunk, 0, 0, 0, 0}})
    {:ok, %{}}
  end

  def handle_call(:get_chunk_proto, _from, state) do
    {:reply, to_chunk_proto(state), state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ####
  ## Internals
  ####
  
  defp to_chunk_proto(state) do
    Werld.Proto.Chunk.new(
      pos: Werld.Proto.Coord.new(
        instance: 0,
        grid: 0,
        x: 0,
        y: 0 
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
