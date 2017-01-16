defmodule Chunkosm.Sim.Chunk do
  use GenServer

  defmodule State do
    defstruct [
      :simulator,
      :block_types
    ]
  end

  @chunk_size 16

  ####
  ## Client API
  ####

  def start_link(pos, simulator) do
    GenServer.start_link(__MODULE__, {pos, simulator}, [])
  end

  def get_chunk_proto(server) do
    GenServer.call(server, :get_chunk_proto)
  end

  def step(server) do
    GenServer.cast(server, :step)
  end

  ####
  ## Server Callbacks
  ####

  def init({pos, simulator}) do
    reg_pos = Tuple.insert_at(pos, 0, :chunk)
    :gproc.reg({:n, :l, reg_pos})

    {:ok, %State{
      simulator: simulator,
      block_types: List.duplicate(1, @chunk_size*@chunk_size)
    }}
  end

  def handle_call(:get_chunk_proto, _from, state) do
    {:reply, to_chunk_proto(state), state}
  end

  def handle_cast(:step, state) do
    # Do a thing!
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ####
  ## Internals
  ####

  defp to_chunk_proto(state) do
    %Chunkosm.Proto.Chunk{
      pos: %Chunkosm.Proto.Coord{
        universe: 0,
        grid: 0,
        x: 0,
        y: 0
      },
      ver: 50,
      block_runs: calc_runs(state.block_types)
    }
  end

  defp calc_runs(block_types) do
    alias Chunkosm.Proto.Chunk.BlockRun

    List.foldr(block_types, [], fn(cur_bt, acc) ->
      case acc do
        [%BlockRun{count: n, block_type: ^cur_bt} | rest] ->
          [%BlockRun{count: n+1, block_type: cur_bt} | rest]
        others ->
          [%BlockRun{count: 1, block_type: cur_bt} | others]
      end
    end)
  end
end
