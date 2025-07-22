defmodule BTx.JRPC.Mining.GenerateToAddress do
  @moduledoc """
  Mine blocks immediately to a specified address (before the RPC call returns).

  ## Schema fields (a.k.a "Arguments")

  - `:nblocks` - (required) How many blocks are generated immediately.

  - `:address` - (required) The address to send the newly generated bitcoin to.

  - `:maxtries` - (optional) How many iterations to try. Defaults to `1000000`.

  See [Bitcoin RPC API Reference `generatetoaddress`][generatetoaddress].
  [generatetoaddress]: https://developer.bitcoin.org/reference/rpc/generatetoaddress.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.JRPC.Request

  ## Types & Schema

  @typedoc "GenerateToAddress request"
  @type t() :: %__MODULE__{
          method: String.t(),
          nblocks: non_neg_integer() | nil,
          address: String.t() | nil,
          maxtries: non_neg_integer()
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "generatetoaddress"

    # Method fields
    field :nblocks, :integer
    field :address, :string
    field :maxtries, :integer, default: 1_000_000
  end

  @required_fields ~w(nblocks address)a
  @optional_fields ~w(maxtries)a

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          nblocks: nblocks,
          address: address,
          maxtries: maxtries
        }) do
      Request.new(
        method: method,
        params: [nblocks, address, maxtries]
      )
    end
  end

  ## API

  @doc """
  Creates a new `GenerateToAddress` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:generatetoaddress)
  end

  @doc """
  Creates a new `GenerateToAddress` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:generatetoaddress)
  end

  @doc """
  Creates a changeset for the `GenerateToAddress` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:nblocks, greater_than: 0)
    |> validate_number(:maxtries, greater_than: 0)
    |> validate_length(:address, min: 26, max: 90)
    |> valid_address_format()
  end
end
