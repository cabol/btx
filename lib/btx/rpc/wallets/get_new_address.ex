defmodule BTx.RPC.Wallets.GetNewAddress do
  @moduledoc """
  Returns a new Bitcoin address for receiving payments.

  ## Schema fields (a.k.a "Arguments")

  - `:label` - (optional) The label name for the address to be linked to.
    It can also be set to the empty string “” to represent the default label.
    The label does not need to exist, it will be created if there is no label
    by the given name. Defaults to `""`.

  - `:address_type` - (optional) The type of address to use.
    The default is "bech32".

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `getnewaddress`][getnewaddress].
  [getnewaddress]: https://developer.bitcoin.org/reference/rpc/getnewaddress.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetNewAddress request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          label: String.t() | nil,
          address_type: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getnewaddress"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :label, :string, default: ""
    field :address_type, :string
  end

  @optional_fields ~w(label address_type wallet_name)a

  # Valid address types in Bitcoin Core
  @valid_address_types ~w(legacy p2sh-segwit bech32 bech32m)

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          label: label,
          address_type: address_type,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: [label, address_type]
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetNewAddress` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getnewaddress)
  end

  @doc """
  Creates a new `GetNewAddress` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getnewaddress)
  end

  @doc """
  Creates a changeset for the `GetNewAddress` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @optional_fields)
    |> validate_length(:label, max: 255)
    |> validate_inclusion(:address_type, @valid_address_types)
    |> validate_length(:wallet_name, min: 1, max: 64)
  end
end
