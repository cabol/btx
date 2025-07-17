defmodule BTx.JRPC.Helpers do
  @moduledoc """
  Helpers for the JSON RPC API.
  """

  alias Ecto.UUID

  # Common params
  @common_params %{
    jsonrpc: "1.0",
    id: "btx-1"
  }

  # Inline common instructions
  @compile {:inline, common_params: 0}

  @doc """
  Returns the common parameters for the JSON RPC API.
  """
  @spec common_params() :: map()
  def common_params, do: %{@common_params | id: "btx-" <> UUID.generate()}
end
