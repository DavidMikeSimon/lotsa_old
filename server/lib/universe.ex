defmodule Lotsa.Universe do
  defstruct [
    :num,
    :plugins,
    :block_types
  ]

  def new(universe_num) do
    %Lotsa.Universe{
      num: universe_num,
      plugins: [],
      block_types: %{}
    }
  end

  def has_plugin?(universe, plugin_name) do
    Enum.any?(universe.plugins, fn{k,_v} -> k == plugin_name end)
  end

  def add_plugin(universe, plugin_name) do
    if has_plugin?(universe, plugin_name) do
      universe
    else
      new_plugins = load_resolved_plugins([plugin_name], [], [])
        |> Enum.reject(fn(%Lotsa.Plugin{name: name}) -> has_plugin?(universe, name) end)
      Enum.reduce new_plugins, universe, fn(plugin, universe) ->
        universe = run_plugin_setup(universe, plugin)
        universe = %{universe | plugins: universe.plugins ++ [plugin]}
      end
    end
  end

  # TODO : plugin version restrictions in deps should mean something
  defp load_resolved_plugins([], _stack, acc), do: acc
  defp load_resolved_plugins([plugin_name|rest], stack, acc) do
    plugin = Lotsa.Plugin.load(plugin_name)

    dep_plugin_names = Lotsa.Plugin.dependency_names(plugin)
    if Enum.any?(dep_plugin_names, fn(a) -> Enum.any?(stack, &(&1 == a)) end) do
      raise "Loop in \"#{plugin_name}\" deps: #{inspect(Enum.reverse(stack))}"
    end

    dep_plugins = load_resolved_plugins(dep_plugin_names, [plugin_name|stack], [])
    load_resolved_plugins(rest, stack, acc ++ dep_plugins ++ [plugin])
  end

  defp run_plugin_setup(universe, plugin) do
    changes = Lotsa.Plugin.calc_plugin_changes(universe, plugin)
    universe
  end

#  defp allocate_bt_nums(plugins), do: allocate_bt_nums(%{}, 0, plugins)
#  defp allocate_bt_nums(acc, _, []), do: acc
#  defp allocate_bt_nums(acc, next_num, [plugin|rest]) do
#    bt_names = Lotsa.Plugin.block_types_defined(plugin)
#    bts_count = Enum.count(bt_names)
#    bt_nums = Enum.zip(bt_names, next_num..(next_num+bts_count)) |> Map.new
#    acc = Map.merge(acc, bt_nums)
#    allocate_bt_nums(acc, next_num + bts_count, rest)
#  end
end
