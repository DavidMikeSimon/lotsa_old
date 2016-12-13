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
    block_types = List.duplicate(0, @chunk_size*@chunk_size)
    block_types = List.replace_at(block_types, 3, 1)
    block_types = List.replace_at(block_types, 4, 1)
    block_types = List.replace_at(block_types, 9, 1)
    block_types = List.replace_at(block_types, 29, 1)

    %State{
      block_types: block_types
    }
  end

  defp to_chunk_proto(state) do
    alias Werld.Proto.Chunk.BlockRun

    Werld.Proto.Chunk.new(
      pos: Werld.Proto.Coord.new(
        instance: 0,
        grid: 0,
        x: 0,
        y: 0
      ),
      ver: 50,
      block_runs: Enum.map(calc_runs(state.block_types), fn({n, bt}) ->
        BlockRun.new(count: n, block_type: bt)
      end)
    )
  end

  defp calc_runs(block_types) do
    List.foldr(block_types, [], fn(cur_bt, acc) ->
      case acc do
        [{n, ^cur_bt} | rest] -> [{n+1, cur_bt} | rest]
        others -> [{1, cur_bt} | others]
      end
    end)
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
