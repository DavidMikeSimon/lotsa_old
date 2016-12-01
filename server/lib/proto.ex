defmodule Werld.Proto do
  @external_resource Path.expand("../../proto/werld.proto", __DIR__)
  use Protobuf, from: Path.expand("../../proto/werld.proto", __DIR__)
end
