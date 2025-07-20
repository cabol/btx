defmodule BTx.JRPC.Wallets.GetNewAddress do
  @moduledoc """
  Returns a new Bitcoin address for receiving payments.

  If `label` is specified, it is added to the address book so that payments
  received with the address will be associated with `label`.

  See [Bitcoin RPC API Reference `getnewaddress`][getnewaddress].
  [getnewaddress]: https://developer.bitcoin.org/reference/rpc/getnewaddress.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Request

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
    field :address_type, :string, default: "bech32"
  end

  @optional_fields ~w(label address_type wallet_name)a

  # Valid address types in Bitcoin Core
  @valid_address_types ~w(legacy p2sh-segwit bech32 bech32m)

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          label: label,
          address_type: address_type,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        params: [label, address_type],
        path: path
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
