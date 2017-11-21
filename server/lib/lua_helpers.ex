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

  def call_library_func(library, func, args \\ []) do
    library[func].(args)
  end

  def run_script(path) do
    wrap_lua_call fn(_) ->
      Lua.eval_file!(initial_state(), path)
    end
  end

  defp initial_state do
    lua_path = Path.expand(Path.join([Mix.Project.build_path, "..", "..", "lua"]))
    Lua.State.new()
      |> Lua.set_table([:debug], fn(st, [term]) -> {st, []} end)
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
    map = Map.new(term, &elixirify/1)
    case map do
      %{"_table_type" => %{"proto" => _}} -> lua_table_to_proto_struct(map)
      %{"_table_type" => "map"} -> lua_table_to_map(map)
      other -> lua_table_to_list(map)
    end
  end
  defp elixirify(term), do: term

  defp lua_table_to_proto_struct(table) do
    map = Map.new(table, fn {key, val} -> {String.to_existing_atom(key), val} end)
    {%{"proto" => proto_name}, map} = Map.pop(map, "_table_type")
    struct("Lotsa.Proto.#{proto_name}", map)
  end

  defp lua_table_to_map(table) do
    {_, map} = Map.pop(table, "_table_type")
    map
  end

  defp lua_table_to_list(table) do
    pairs = Map.to_list(table)
      |>  Enum.sort_by(fn {k, _} -> k end)

    Stream.map(pairs, fn {k, _} -> k end)
      |> Stream.zip(Stream.iterate(0, &(&1+1)))
      |> Enum.each(fn {k1, k2} ->
        if k1 != k2, do: raise RuntimeError, "Invalid lua table key sequence for list, need #{k2}, got #{inspect k1}"
      end)

    Enum.map pairs, fn({_, v}) -> v end
  end

  defp wrap_lua_call(fun, args \\ []) do
    try do
      fun.(args) |> hd |> elixirify
    rescue
      e -> case e do
        %ErlangError{original: {:lua_error, lua_err, _state}} ->
          reraise "Lua Error: " <> to_string(:luerl_lib.format_error(lua_err)), System.stacktrace
        other ->
          reraise other, System.stacktrace
      end
    end
  end
end
