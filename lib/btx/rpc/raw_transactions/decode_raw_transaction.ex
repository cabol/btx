defmodule BTx.RPC.RawTransactions.DecodeRawTransaction do
  @moduledoc """
  Return a JSON object representing the serialized, hex-encoded transaction.

  ## Schema fields (a.k.a "Arguments")

  - `:hexstring` - (required) The transaction hex string.

  - `:iswitness` - (optional) Whether the transaction hex is a serialized witness
    transaction. If iswitness is not present, heuristic tests will be used in
    decoding. If true, only witness deserialization will be tried. If false,
    only non-witness deserialization will be tried. This boolean should reflect
    whether the transaction has inputs (e.g. fully valid, or on-chain transactions),
    if known by the caller.

  See [Bitcoin RPC API Reference `decoderawtransaction`][decoderawtransaction].
  [decoderawtransaction]: https://developer.bitcoin.org/reference/rpc/decoderawtransaction.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import BTx.Helpers, only: [trim_trailing_nil: 1]
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Constants

  @method "decoderawtransaction"

  ## Types & Schema

  @typedoc "DecodeRawTransaction request"
  @type t() :: %__MODULE__{
          method: String.t(),
          hexstring: String.t() | nil,
          iswitness: boolean() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: @method

    # Method fields
    field :hexstring, :string
    field :iswitness, :boolean
  end

  @required_fields ~w(hexstring)a
  @optional_fields ~w(iswitness)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          hexstring: hexstring,
          iswitness: iswitness
        }) do
      Request.new(
        method: method,
        path: "/",
        params: trim_trailing_nil([hexstring, iswitness])
      )
    end
  end

  ## API

  @doc """
  Creates a new `DecodeRawTransaction` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:decoderawtransaction)
  end

  @doc """
  Creates a new `DecodeRawTransaction` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:decoderawtransaction)
  end

  @doc """
  Creates a changeset for the `DecodeRawTransaction` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:hexstring, min: 1)
    |> validate_hexstring(:hexstring)
  end
end
