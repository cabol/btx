defmodule BTx.JRPC.Request do
  @moduledoc """
  A request to the JSON RPC API.
  """

  use Ecto.Schema

  alias Ecto.UUID

  @typedoc "Response from the JSON RPC API"
  @type t() :: %__MODULE__{
          id: String.t(),
          jsonrpc: String.t(),
          method: String.t(),
          params: list(),
          path: String.t()
        }

  @derive {JSON.Encoder, only: [:id, :jsonrpc, :method, :params]}
  @enforce_keys ~w(method params)a
  defstruct id: nil, jsonrpc: "1.0", method: nil, params: [], path: "/"

  ## API

  @doc """
  Creates a new `Request` struct.
  """
  @spec new(keyword() | map()) :: t()
  def new(params) do
    params
    |> Enum.into(%{})
    |> Map.put_new(:id, "btx-" <> UUID.generate())
    |> then(&struct!(__MODULE__, &1))
  end
end
