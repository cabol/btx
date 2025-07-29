defmodule BTx.RPC.Blockchain.GetBlock do
  @moduledoc """
  Returns block data by block hash.

  - If verbosity is 0, returns a string that is serialized, hex-encoded data
    for block.
  - If verbosity is 1, returns an Object with information about block.
  - If verbosity is 2, returns an Object with information about block and
    information about each transaction.

  ## Schema fields (a.k.a "Arguments")

  - `:blockhash` - (required) The block hash.
  - `:verbosity` - (optional) 0 for hex-encoded data, 1 for a json object,
    and 2 for json object with transaction data. Default: 1.

  See [Bitcoin RPC API Reference `getblock`][getblock].
  [getblock]: https://developer.bitcoin.org/reference/rpc/getblock.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetBlock request"
  @type t() :: %__MODULE__{
          method: String.t(),
          blockhash: String.t() | nil,
          verbosity: non_neg_integer() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getblock"

    # Method fields
    field :blockhash, :string
    field :verbosity, :integer, default: 1
  end

  @required_fields ~w(blockhash)a
  @optional_fields ~w(verbosity)a

  # Valid verbosity levels
  @valid_verbosity [0, 1, 2]

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          blockhash: blockhash,
          verbosity: verbosity
        }) do
      Request.new(
        method: method,
        path: "/",
        params: [blockhash, verbosity]
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetBlock` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getblock)
  end

  @doc """
  Creates a new `GetBlock` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getblock)
  end

  @doc """
  Creates a changeset for the `GetBlock` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_hex64(:blockhash)
    |> validate_inclusion(:verbosity, @valid_verbosity)
  end
end
