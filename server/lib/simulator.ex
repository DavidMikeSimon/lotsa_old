defmodule Lotsa.Simulator do
  use GenServer

  defmodule State do
    defstruct [
      :universe_def,
      :loaded_chunks
    ]
  end

  ####
  ## Client API
  ####
  
  def start(universe_def, options \\ %{}) do
    GenServer.start(__MODULE__, {universe_def, options}, [])
  end

  def start_link(universe_def, options \\ %{}) do
    GenServer.start_link(__MODULE__, {universe_def, options}, [])
  end

  def get_chunk(simulator, coord) do
    GenServer.call(simulator, {:get_chunk, coord})
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

  def init({universe_def, options}) do
    :gproc.reg({:n, :l, :simulator}) # FIXME temporary
    chunks = if Map.has_key?(options, :chunks) do
      Map.new options.chunks, fn chunk -> {chunk.coord, chunk} end
    else
      %{}
    end
    {:ok, %State{
      universe_def: universe_def,
      loaded_chunks: chunks
    }}
  end

  def handle_call({:get_chunk, coord}, _from, state) do
    case Map.get(state.loaded_chunks, coord) do
      nil -> {:reply, {:error, :chunk_not_found}, state}
      chunk -> {:reply, {:ok, chunk}, state}
    end
  end

  def handle_call({:get_chunk_proto, coord}, _from, state) do
    case Map.get(state.loaded_chunks, coord) do
      nil -> {:reply, {:error, :chunk_not_found}, state}
      chunk -> {:reply, {:ok, Lotsa.Chunk.to_proto(chunk)}, state}
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
