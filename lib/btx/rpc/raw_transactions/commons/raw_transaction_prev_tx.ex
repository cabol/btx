defmodule BTx.RPC.RawTransactions.RawTransaction.PrevTx do
  @moduledoc """
  Represents a previous transaction output for the `signrawtransactionwithkey`
  JSON RPC API.

  This schema describes previous dependent transaction outputs that the
  transaction depends on but may not yet be in the block chain.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "RawTransaction PrevTx"
  @type t() :: %__MODULE__{
          txid: String.t() | nil,
          vout: non_neg_integer() | nil,
          script_pub_key: String.t() | nil,
          redeem_script: String.t() | nil,
          witness_script: String.t() | nil,
          amount: float() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :txid, :string
    field :vout, :integer
    field :script_pub_key, :string
    field :redeem_script, :string
    field :witness_script, :string
    field :amount, :float
  end

  @required_fields ~w(txid vout script_pub_key)a
  @optional_fields ~w(redeem_script witness_script amount)a

  ## API

  @doc """
  Creates a changeset for the `PrevTx` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(prevtx, attrs) do
    prevtx
    |> cast(normalize_attrs(attrs), @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_txid()
    |> validate_number(:vout, greater_than_or_equal_to: 0)
    |> validate_hexstring(:script_pub_key)
    |> validate_hexstring(:redeem_script)
    |> validate_hexstring(:witness_script)
    |> validate_number(:amount, greater_than: 0)
  end

  @doc """
  Converts a `PrevTx` schema to a map.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = prevtx) do
    prevtx
    |> Map.take(__schema__(:fields))
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case {key, value} do
        {:script_pub_key, val} when not is_nil(val) -> Map.put(acc, "scriptPubKey", val)
        {:redeem_script, val} when not is_nil(val) -> Map.put(acc, "redeemScript", val)
        {:witness_script, val} when not is_nil(val) -> Map.put(acc, "witnessScript", val)
        {key, val} when not is_nil(val) -> Map.put(acc, to_string(key), val)
        _ -> acc
      end
    end)
  end
end
