defmodule Lotsa.UniverseDef do
  alias Lotsa.LuaHelpers, as: LH

  defstruct [
    :num,
    :plugin_load_order,
    :plugins,
    :block_type_indexes,
    :block_property_indexes,
    :block_input_indexes,
    :block_rule_indexes,
    :block_updater_indexes
  ]

  defmodule BlockTypePropertySourceDef do
    def from_lua(source) do
      case source do
        %{"fixed_value" => v} -> {:fixed_value, v}
      end
    end
  end

  defmodule BlockTypeDef do
    defstruct [
      properties_provided: []
    ]

    def from_lua(bt) do
      %BlockTypeDef{
        properties_provided:
          LH.assume_list(bt["properties"])
          |> Enum.map(fn %{"prop" => %{"index" => index}, "source" => source} ->
            {index, BlockTypePropertySourceDef.from_lua(source)}
          end)
          |> Map.new
      }
    end
  end

  defmodule BlockPropertyDef do
    defstruct [ :type, :default_value ]

    def from_lua(prop) do
      %BlockPropertyDef{
        type: case prop["prop_type"] do
          "boolean" -> :boolean
        end,
        default_value: case prop["options"] do
          %{"default_value" => value} -> value
          _else -> nil # TODO: Appropriate default value for type?
        end
      }
    end
  end

  defmodule BlockInputDef do
    defstruct [
      targets: %{},
      expression: %{}
    ]

    def from_lua(input) do
      %BlockInputDef{
        targets: LH.assume_map(input["targets"]),
        expression: LH.assume_map(input["expression"])
      }
    end
  end

  defmodule BlockRuleDef do
    defstruct [
      prereqs: [],
      calls: []
    ]

    def from_lua(rule) do
      %BlockRuleDef{
        prereqs: LH.assume_list(rule["prereqs"]),
        calls: LH.assume_list(rule["calls"])
      }
    end
  end

  defmodule BlockUpdaterDef do
    defstruct []

    def from_lua(updater) do
      %BlockUpdaterDef{}
    end
  end

  defmodule PluginDef do
    def from_lua(plugin) do
      %{
        block_types: LH.assume_map(plugin["block_types"], &BlockTypeDef.from_lua/1),
        block_properties: LH.assume_map(plugin["block_properties"], &BlockPropertyDef.from_lua/1),
        block_inputs: LH.assume_map(plugin["block_inputs"], &BlockInputDef.from_lua/1),
        block_rules: LH.assume_map(plugin["block_rules"], &BlockRuleDef.from_lua/1),
        block_updaters: LH.assume_map(plugin["block_updaters"], &BlockUpdaterDef.from_lua/1)
      }
    end
  end

  def new(num, config) do
    rc = resolve_config(config)
    unless rc["block_type_indexes"][0] == ["basis", "unknown"] do
      raise "Block type index 0 must be basis:unknown"
    end
    unless rc["block_type_indexes"][1] == ["basis", "empty"] do
      raise "Block type index 1 must be basis:empty"
    end

    %Lotsa.UniverseDef{
      num: num,
      plugin_load_order: rc["plugin_load_order"],
      plugins: LH.assume_map(rc["plugins"], &PluginDef.from_lua/1),
      block_type_indexes: LH.assume_map(rc["block_type_indexes"]),
      block_property_indexes: LH.assume_map(rc["block_property_indexes"]),
      block_input_indexes: LH.assume_map(rc["block_input_indexes"]),
      block_rule_indexes: LH.assume_map(rc["block_rule_indexes"]),
      block_updater_indexes: LH.assume_map(rc["block_updater_indexes"])
    }
  end

  def has_plugin?(universe, plugin_name) do
    Map.has_key?(universe.plugins, plugin_name)
  end

  defp resolve_config(config) do
    setup_lib = LH.load_library("universe_def_setup", [
      get_plugin_path: fn([name]) ->
        path_parts = [
          Mix.Project.build_path, "..", "..", "..", "plugins", name, "definition.lua"
        ]
        def_path = Path.expand Path.join(path_parts)
        unless File.exists?(def_path) do
          raise "No such plugin definition file: #{def_path}"
        end
        def_path
      end
    ])

    LH.call_library_func(setup_lib, "setup", [config])
  end
end
