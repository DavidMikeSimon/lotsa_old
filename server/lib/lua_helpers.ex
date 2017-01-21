defmodule Chunkosm.LuaHelpers do
  def elixirify([]) do
    []
  end

  def elixirify(term) when is_list(term) do
    if is_tuple(hd(term)) do
      Map.new(term, fn({k, v}) -> {k, elixirify(v) } end)
    else
      Enum.map(term, &elixirify/1)
    end
  end

  def elixirify(term) do
    term
  end
end
