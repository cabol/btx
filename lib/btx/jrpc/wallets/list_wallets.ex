defmodule BTx.JRPC.Wallets.ListWallets do
  @moduledoc """
  Returns a list of currently loaded wallets.

  For full information on the wallet, use "getwalletinfo".

  ## Schema fields (a.k.a "Arguments")

  This method takes no parameters.

  See [Bitcoin RPC API Reference `listwallets`][listwallets].
  [listwallets]: https://developer.bitcoin.org/reference/rpc/listwallets.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Request

  ## Types & Schema

  @typedoc "ListWallets request"
  @type t() :: %__MODULE__{
          method: String.t()
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "listwallets"
  end

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{method: method}) do
      Request.new(
        method: method,
        params: []
      )
    end
  end

  ## API

  @doc """
  Creates a new `ListWallets` request.
  """
  @spec new() :: {:ok, t()}
  def new do
    %__MODULE__{}
    |> changeset(%{})
    |> apply_action(:listwallets)
  end

  @doc """
  Creates a new `ListWallets` request.
  """
  @spec new!() :: t()
  def new! do
    %__MODULE__{}
    |> changeset(%{})
    |> apply_action!(:listwallets)
  end

  @doc """
  Creates a changeset for the `ListWallets` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    # No fields to validate, just return a valid changeset
    change(t, attrs)
  end
end
