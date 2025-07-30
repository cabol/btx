defmodule BTx.RPC.RawTransactions.DecodeRawTransactionResult do
  @moduledoc """
  Result from the `decoderawtransaction` JSON RPC API.

  Returns a JSON object representing the serialized, hex-encoded transaction.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.RawTransactions.RawTransaction.{Vin, Vout}
  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "DecodeRawTransactionResult"
  @type t() :: %__MODULE__{
          txid: String.t() | nil,
          hash: String.t() | nil,
          size: non_neg_integer() | nil,
          vsize: non_neg_integer() | nil,
          weight: non_neg_integer() | nil,
          version: non_neg_integer() | nil,
          locktime: non_neg_integer() | nil,
          vin: [Vin.t()],
          vout: [Vout.t()]
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :txid, :string
    field :hash, :string
    field :size, :integer
    field :vsize, :integer
    field :weight, :integer
    field :version, :integer
    field :locktime, :integer
    embeds_many :vin, Vin
    embeds_many :vout, Vout
  end

  @optional_fields ~w(txid hash size vsize weight version locktime)a

  ## API

  @doc """
  Creates a new `DecodeRawTransactionResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:decoderawtransaction_result)
  end

  @doc """
  Creates a new `DecodeRawTransactionResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:decoderawtransaction_result)
  end

  @doc """
  Creates a changeset for the `DecodeRawTransactionResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(attrs, @optional_fields)
    |> cast_embed(:vin, with: &Vin.changeset/2)
    |> cast_embed(:vout, with: &Vout.changeset/2)
    |> validate_number(:size, greater_than: 0)
    |> validate_number(:vsize, greater_than: 0)
    |> validate_number(:weight, greater_than: 0)
    |> validate_number(:version, greater_than_or_equal_to: 0)
    |> validate_number(:locktime, greater_than_or_equal_to: 0)
  end
end
