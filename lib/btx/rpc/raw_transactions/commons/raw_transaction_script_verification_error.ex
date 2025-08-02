defmodule BTx.RPC.RawTransactions.RawTransaction.ScriptVerificationError do
  @moduledoc """
  Represents a script verification error from the `signrawtransactionwithkey`
  JSON RPC API.

  This schema describes verification or signing errors related to transaction
  inputs.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "ScriptVerificationError"
  @type t() :: %__MODULE__{
          txid: String.t() | nil,
          vout: non_neg_integer() | nil,
          script_sig: String.t() | nil,
          sequence: non_neg_integer() | nil,
          error: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :txid, :string
    field :vout, :integer
    field :script_sig, :string
    field :sequence, :integer
    field :error, :string
  end

  @optional_fields ~w(txid vout script_sig sequence error)a

  ## API

  @doc """
  Creates a changeset for the `ScriptVerificationError` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(error_schema, attrs) do
    error_schema
    |> cast(normalize_attrs(attrs), @optional_fields)
    |> validate_txid()
    |> validate_number(:vout, greater_than_or_equal_to: 0)
    |> validate_hexstring(:script_sig)
    |> validate_number(:sequence, greater_than_or_equal_to: 0)
  end
end
