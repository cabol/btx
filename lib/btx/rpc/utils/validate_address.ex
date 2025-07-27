defmodule BTx.RPC.Utils.ValidateAddress do
  @moduledoc """
  Return information about the given bitcoin address.

  ## Schema fields (a.k.a "Arguments")

  - `:address` - (required) The bitcoin address to validate.

  See [Bitcoin RPC API Reference `validateaddress`][validateaddress].
  [validateaddress]: https://developer.bitcoin.org/reference/rpc/validateaddress.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "ValidateAddress request"
  @type t() :: %__MODULE__{
          method: String.t(),
          address: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "validateaddress"

    # Method fields
    field :address, :string
  end

  @required_fields ~w(address)a
  @optional_fields []

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          address: address
        }) do
      Request.new(
        method: method,
        path: "/",
        params: [address]
      )
    end
  end

  ## API

  @doc """
  Creates a new `ValidateAddress` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:validateaddress)
  end

  @doc """
  Creates a new `ValidateAddress` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:validateaddress)
  end

  @doc """
  Creates a changeset for the `ValidateAddress` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> valid_address_format()
  end
end
