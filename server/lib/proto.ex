defmodule Lotsa.Proto do
  @external_resource Path.expand("../../proto/lotsa.proto", __DIR__)
  use Protobuf, from: Path.expand("../../proto/lotsa.proto", __DIR__)
end
