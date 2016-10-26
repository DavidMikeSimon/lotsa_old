defmodule Werld.Proto do
  @external_resource "../proto/werld.proto"
  use Protobuf, from: Path.expand("../proto/werld.proto", __DIR__)
end
