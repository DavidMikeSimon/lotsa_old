defmodule Werld.Sim.Chunk do
  use GenServer

  ####
  ## Internals
  ####

  defmodule State do
    defstruct [:block_types]
  end

  @chunk_size 16

  defp initial_state do
    block_types = :array.new([
      size: @chunk_size*@chunk_size,
      default: 0,
      fixed: true
    ])
    block_types = :array.set(3, 1, block_types)
    block_types = :array.set(4, 1, block_types)
    block_types = :array.set(9, 1, block_types)

    %Werld.Sim.Chunk.State{
      block_types: block_types
    }
  end

  defp to_chunk_proto(state) do
    Werld.Proto.Chunk.new(
      pos: Werld.Proto.Coord.new(
        instance: 0,
        grid: 0,
        x: 0,
        y: 0
      ),
      ver: 50,
      block_runs: block_types_array_to_runs(state.block_types)
    )
  end

  defp block_types_array_to_runs(arr, idx \\ 0) do
    if idx > :array.size(arr) do
      []
    else
      cur = :array.get(idx, arr)
      case block_types_array_to_runs(arr, idx+1) do
        [] ->
          [Werld.Proto.Chunk.BlockRun.new(count: 1, block_type: cur)]
        [next_run | rest] ->
          if next_run.block_type == cur do
            [Werld.Proto.Chunk.BlockRun.new(count: next_run.count+1, block_type: cur) | rest]
          else
            [Werld.Proto.Chunk.BlockRun.new(count: 1, block_type: cur) | [ next_run | rest ]]
          end
      end
    end
  end

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
    {:ok, initial_state}
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

end
