defmodule Chunkosm.Chunk do
  defstruct [
    :coord,
    :block_types
  ]

  @chunk_size 16

  def new(coord) do
    %Chunkosm.Chunk{
      coord: coord,
      block_types: List.duplicate(0, @chunk_size*@chunk_size)
    }
  end

  def get_universe_number(chunk) do
    chunk.coord[0]
  end

  def get_grid_number(chunk) do
    chunk.coord[1]
  end

  def get_x(chunk) do
    chunk.coord[2]
  end

  def get_y(chunk) do
    chunk.coord[3]
  end

  def to_proto(chunk) do
    %Chunkosm.Proto.Chunk{
      pos: %Chunkosm.Proto.Coord{
        universe: get_universe_number(chunk),
        grid: get_grid_number(chunk),
        x: get_x(chunk),
        y: get_y(chunk)
      },
      ver: 50,
      block_runs: calc_runs(chunk.block_types)
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
