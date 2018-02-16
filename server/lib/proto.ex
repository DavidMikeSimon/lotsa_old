defmodule Lotsa.Proto do
  @external_resource Path.expand("../../proto/lotsa.proto", __DIR__)

  use Protox, files: [ "./../proto/lotsa.proto" ], namespace: Lotsa.Proto
end
