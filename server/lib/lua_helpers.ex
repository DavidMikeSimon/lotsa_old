defmodule Lotsa.LuaHelpers do
  def load_library(name, provided_functions \\ []) do
    lib_path = Path.expand Path.join([
      Mix.Project.build_path, "..", "..", "lua", "#{name}.lua"
    ])
    wrap_lua_call fn(_) ->
      {lua_state, lua_chunk} = Lua.load_file!(initial_state(), lib_path)
      lua_state = insert_global_functions(lua_state, provided_functions)
      {_, result} = Lua.call_chunk!(lua_state, lua_chunk)
      result
    end
  end

  def call_library_func(library, function, args \\ []) do
    library[function].(args)
  end

  def run_script(path) do
    wrap_lua_call fn(_) ->
      Lua.eval_file!(initial_state(), path)
    end
  end

  def assume_map(:none), do: %{}
  def assume_map(term), do: term

  def assume_map(:none, _fun), do: %{}
  def assume_map(map, fun) do
    Enum.map(map, fn({k,v}) -> { k, fun.(v) } end) |> Map.new
  end

  def assume_list(:none), do: []
  def assume_list(term), do: term

  def assume_list(:none, _fun), do: []
  def assume_list(term, fun) do Enum.map(term, fun) end

  defp initial_state do
    lua_path = Path.expand(Path.join([Mix.Project.build_path, "..", "..", "lua"]))
    Lua.State.new()
      |> Lua.set_table([:debug], fn(st, [term]) -> IO.inspect(elixirify(term)); {st, []} end)
      |> Lua.set_table([:package, :path], lua_path <> "/?.lua")
      |> Lua.set_table([:Lotsa], [])
  end


  defp insert_global_functions(state, funcs) do
    Enum.reduce funcs, state, fn({name, func}, cur_state) ->
      Lua.set_table cur_state, [:Lotsa, name], fn(st, args) ->
        args = Enum.map args, &elixirify/1
        {st, [func.(args)]}
      end
    end
  end

  defp elixirify([]), do: :none # Prevent ambiguity about empty arrays vs. empty maps
  defp elixirify({:function, fun}), do: elixirify(fun)
  defp elixirify({k,v}), do: {elixirify(k), elixirify(v)}
  defp elixirify(num) when is_float(num) do
    int = round(num)
    if abs(num - int) < 0.000001, do: int, else: num
  end
  defp elixirify(fun) when is_function(fun) do
    fn(args) -> wrap_lua_call(fun, args) end
  end
  defp elixirify(term) when is_list(term) do
    if Enum.all?(term, fn {k,_v} -> is_integer(k) end) do 
      # Regular list, discard the index keys
      Enum.map(term, &(elixirify(elem(&1, 1))))
    else
      map = Map.new(term, &elixirify/1)
      case map do
        %{"get_desc" => fun} when is_function(fun) -> fun.([])
        other -> other
      end
    end
  end
  defp elixirify(term), do: term

  defp wrap_lua_call(fun, args \\ []) do
    try do
      fun.(args) |> hd |> elixirify
    rescue
      e -> case e do
        %ErlangError{original: {:lua_error, lua_err, _}} ->
          raise RuntimeError, inspect({:lua_error, lua_err})
        other ->
          reraise other, System.stacktrace
      end
    end
  end
end
