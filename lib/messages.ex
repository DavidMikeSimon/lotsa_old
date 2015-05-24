defmodule Werld.Messages do
  use Protobuf, from: Path.expand("../proto/werld.proto", __DIR__)
end