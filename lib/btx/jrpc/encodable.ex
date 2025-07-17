defprotocol BTx.JRPC.Encodable do
  @moduledoc """
  Encodable protocol for the Bitcoin JSON RPC API.
  """

  @typedoc "Encodable type"
  @type t(_element) :: t()

  @doc """
  Encodes the given value to a JSON-RPC request.
  """
  @spec encode(t()) :: map()
  def encode(value)
end
