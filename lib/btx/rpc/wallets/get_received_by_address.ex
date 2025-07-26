defmodule BTx.RPC.Wallets.GetReceivedByAddress do
  @moduledoc """
  Returns the total amount received by the given address in transactions with
  at least minconf confirmations.

  ## Schema fields (a.k.a "Arguments")

  - `:address` - (required) The bitcoin address for transactions.

  - `:minconf` - (optional) Only include transactions confirmed at least this
    many times. Defaults to `1`.

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `getreceivedbyaddress`][getreceivedbyaddress].
  [getreceivedbyaddress]: https://developer.bitcoin.org/reference/rpc/getreceivedbyaddress.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetReceivedByAddress request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          address: String.t() | nil,
          minconf: non_neg_integer()
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getreceivedbyaddress"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :address, :string
    field :minconf, :integer, default: 1
  end

  @required_fields ~w(address)a
  @optional_fields ~w(minconf wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          address: address,
          minconf: minconf,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: [address, minconf]
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetReceivedByAddress` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getreceivedbyaddress)
  end

  @doc """
  Creates a new `GetReceivedByAddress` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getreceivedbyaddress)
  end

  @doc """
  Creates a changeset for the `GetReceivedByAddress` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> valid_address_format(:address)
    |> validate_number(:minconf, greater_than_or_equal_to: 0)
    |> validate_length(:wallet_name, min: 1, max: 64)
  end
end
