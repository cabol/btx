defmodule BTx.RPC.Wallets.GetAddressInfo do
  @moduledoc """
  Return information about the given bitcoin address.

  Some of the information will only be present if the address is in the active wallet.

  ## Schema fields (a.k.a "Arguments")

  - `:address` - (required) The bitcoin address for which to get information.

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `getaddressinfo`][getaddressinfo].
  [getaddressinfo]: https://developer.bitcoin.org/reference/rpc/getaddressinfo.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetAddressInfo request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          address: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getaddressinfo"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :address, :string
  end

  @required_fields ~w(address)a
  @optional_fields ~w(wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          address: address,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: [address]
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetAddressInfo` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getaddressinfo)
  end

  @doc """
  Creates a new `GetAddressInfo` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getaddressinfo)
  end

  @doc """
  Creates a changeset for the `GetAddressInfo` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:address, min: 26, max: 90)
    |> valid_address_format()
    |> validate_length(:wallet_name, min: 1, max: 64)
  end
end
