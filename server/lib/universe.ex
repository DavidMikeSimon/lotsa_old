defmodule Chunkosm.Universe do
  defstruct [
    :num,
    :plugins
  ]

  def new(universe_num, config) do
    %Chunkosm.Universe{
      num: universe_num,
      plugins: Map.get(config, :plugins)
    }
  end
end
