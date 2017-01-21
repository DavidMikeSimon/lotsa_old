defmodule Chunkosm.Sim.Simulator do
  use GenServer

  defmodule State do
    defstruct [
      :universe,
      :loaded_chunks
    ]
  end

  ####
  ## Client API
  ####

  def start_link(universe) do
    GenServer.start_link(__MODULE__, {universe}, [])
  end

  def get_chunk_proto(simulator, coord) do
    GenServer.call(simulator, {:get_chunk_proto, coord})
  end

  def step(simulator) do
    GenServer.cast(simulator, :step)
  end

  def stop(simulator) do
    GenServer.stop(simulator)
  end

  ####
  ## Server Callbacks
  ####

  def init(universe) do
    {:ok, %State{
      universe: universe,
      loaded_chunks: %{}
    }}
    :gproc.reg({:n, :l, :simulator}) # FIXME temporary
  end

  def handle_call({:get_chunk_proto, coord}, _from, state) do
    case Map.get(state.loaded_chunks, coord) do
      nil -> {:reply, :chunk_not_found, state}
      chunk -> {:reply, {:ok, Chunkosm.Chunk.to_proto(chunk)}, state}
    end
  end

  def handle_cast(:step, state) do
    # Do a thing!
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
