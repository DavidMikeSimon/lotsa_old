defmodule Lotsa.Chunk do
  defstruct [
    :coord,
    :block_types
  ]

  @chunk_size 16
  def chunk_size, do: @chunk_size

  def new(coord, block_types \\ []) do
    empty_block_types = Enum.map 0..(@chunk_size-1), fn(_) ->
      List.duplicate(0, @chunk_size)
    end
    %Lotsa.Chunk{
      coord: coord,
      block_types: merge_data(empty_block_types, block_types)
    }
  end

  def get_coord(chunk) do
    chunk.coord
  end

  def to_proto(chunk = %Lotsa.Chunk{coord: {u, g, x, y}}) do
    %Lotsa.Proto.Chunk{
      pos: %Lotsa.Proto.Coord{
        universe: u,
        grid: g,
        x: x,
        y: y
      },
      ver: 50,
      block_runs: calc_runs(chunk.block_types)
    }
  end

  defp calc_runs(block_types) do
    alias Lotsa.Proto.Chunk.BlockRun

    List.foldr Enum.concat(block_types), [], fn(cur_bt, acc) ->
      case acc do
        [%BlockRun{count: n, block_type: ^cur_bt} | rest] ->
          [%BlockRun{count: n+1, block_type: cur_bt} | rest]
        others ->
          [%BlockRun{count: 1, block_type: cur_bt} | others]
      end
    end
  end

  defp merge_data(a, b) do
    b = Stream.concat(b, Stream.cycle([[]]))
    Enum.zip(a, b) |> Enum.map(fn({a_row, b_row}) ->
      b_row = Stream.concat(b_row, Stream.cycle([nil]))
      Enum.zip(a_row, b_row) |> Enum.map(fn({a_cell, b_cell}) ->
        case b_cell do
          nil -> a_cell
          0 -> a_cell
          _ -> b_cell
        end
      end)
    end)
  end
end
