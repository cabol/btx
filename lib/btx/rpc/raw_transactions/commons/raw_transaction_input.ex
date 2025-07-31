defmodule BTx.RPC.RawTransactions.RawTransaction.Input do
  @moduledoc """
  Represents an input for the `createrawtransaction` JSON RPC API.

  Each input specifies a transaction output to spend as an input.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "RawTransactions Input"
  @type t() :: %__MODULE__{
          txid: String.t() | nil,
          vout: non_neg_integer() | nil,
          sequence: non_neg_integer() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :txid, :string
    field :vout, :integer
    field :sequence, :integer
  end

  @required_fields ~w(txid vout)a
  @optional_fields ~w(sequence)a

  ## API

  @doc """
  Creates a changeset for the `Input` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(input, attrs) do
    input
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_txid()
    |> validate_number(:vout, greater_than_or_equal_to: 0)
    |> validate_number(:sequence, greater_than_or_equal_to: 0)
  end
end
