defmodule BTx.JRPC.Wallet.GetNewAddress do
  @moduledoc """
  Returns a new Bitcoin address for receiving payments.

  If `label` is specified, it is added to the address book so that payments
  received with the address will be associated with `label`.
  """

  use Ecto.Schema

  import BTx.JRPC.Helpers
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "GetNewAddress request"
  @type t() :: %__MODULE__{
          label: String.t() | nil,
          address_type: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    field :label, :string, default: ""
    field :address_type, :string, default: "bech32"
  end

  @required_fields []
  @optional_fields ~w(label address_type)a

  # Valid address types in Bitcoin Core
  @valid_address_types ~w(legacy p2sh-segwit bech32 bech32m)

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{
          label: label,
          address_type: address_type
        }) do
      Map.merge(common_params(), %{
        method: "getnewaddress",
        params: [label, address_type]
      })
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
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_length(:label, max: 255)
    |> validate_inclusion(:address_type, @valid_address_types)
  end
end
