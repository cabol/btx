defmodule BTx.RPC.RawTransactions.RawTransaction.Vin.ScriptSig do
  @moduledoc """
  Represents the script signature from a transaction input (vin) in the
  `getrawtransaction` JSON RPC API.
  """

  use Ecto.Schema

  import Ecto.Changeset

  ## Types & Schema

  @typedoc "Script signature"
  @type t() :: %__MODULE__{
          asm: String.t() | nil,
          hex: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :asm, :string
    field :hex, :string
  end

  @optional_fields ~w(asm hex)a

  ## API

  @doc """
  Creates a changeset for the `ScriptSig` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(script_sig, attrs) do
    script_sig
    |> cast(attrs, @optional_fields)
  end
end

defmodule BTx.RPC.RawTransactions.RawTransaction.Vin do
  @moduledoc """
  Represents a transaction input (vin) from the `getrawtransaction`
  JSON RPC API.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset
  alias __MODULE__.ScriptSig

  ## Types & Schema

  @typedoc "Transaction input (vin)"
  @type t() :: %__MODULE__{
          txid: String.t() | nil,
          vout: non_neg_integer() | nil,
          script_sig: ScriptSig.t() | nil,
          sequence: non_neg_integer() | nil,
          txinwitness: [String.t()]
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :txid, :string
    field :vout, :integer
    embeds_one :script_sig, ScriptSig
    field :sequence, :integer
    field :txinwitness, {:array, :string}, default: []
  end

  @optional_fields ~w(txid vout sequence txinwitness)a

  ## API

  @doc """
  Creates a changeset for the `Vin` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(vin, attrs) do
    vin
    |> cast(normalize_attrs(attrs), @optional_fields)
    |> cast_embed(:script_sig)
    |> validate_txid()
    |> validate_number(:vout, greater_than_or_equal_to: 0)
    |> validate_number(:sequence, greater_than_or_equal_to: 0)
  end
end
