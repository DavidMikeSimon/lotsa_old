defmodule Chunkosm.Proto do
  @external_resource Path.expand("../../proto/chunkosm.proto", __DIR__)
  use Protobuf, from: Path.expand("../../proto/chunkosm.proto", __DIR__)
end
