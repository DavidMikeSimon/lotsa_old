defmodule Lotsa.UniverseDefHelpers do
  # TODO Adapt this to Hinge and use it
  def validate_universe_def(universe_def) do
    bt0 = universe_def.block_types[0]
    unless bt0.plugin_name == "basis" && bt0.name == "unknown" do
      raise "Block type at index 0 must be basis:unknown"
    end

    bt1 = universe_def.block_types[1]
    unless bt1.plugin_name == "basis" && bt1.name == "empty" do
      raise "Block type at index 1 must be basis:empty"
    end

    # TODO: Assert that actual list indexes and internal indexes match
    # TODO: Assert that all index references point at something real
    # TODO: ASsert that PluginDescription load_orders are contiguous from 0
  end
end
