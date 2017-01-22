defmodule Lotsa.LuaHelpers do
  def elixirify([]), do: []
  def elixirify({k,v}), do: {elixirify(k), elixirify(v)}
  def elixirify(term) when is_list(term) do
    if Enum.all?(term, fn {k,_v} -> is_integer(k) end) do 
      # Regular list, discard the index keys
      Enum.map(term, &(elixirify(elem(&1, 1))))
    else
      Map.new(term, &elixirify/1)
    end
  end
  def elixirify(term), do: term
end
