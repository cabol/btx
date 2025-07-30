defmodule BTx.RPC.RawTransactions.RawTransaction.Vout.ScriptPubKey do
  @moduledoc """
  Represents the script public key from a transaction output (vout) in the `getrawtransaction` JSON RPC API.
  """

  use Ecto.Schema

  import Ecto.Changeset

  ## Types & Schema

  @typedoc "Script public key"
  @type t() :: %__MODULE__{
          asm: String.t() | nil,
          hex: String.t() | nil,
          req_sigs: non_neg_integer() | nil,
          type: String.t() | nil,
          addresses: [String.t()]
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :asm, :string
    field :hex, :string
    field :req_sigs, :integer
    field :type, :string
    field :addresses, {:array, :string}, default: []
  end

  @optional_fields ~w(asm hex req_sigs type addresses)a

  # Valid script types
  @valid_script_types ~w(nonstandard pubkey pubkeyhash scripthash multisig nulldata
                         witness_v0_keyhash witness_v0_scripthash witness_v1_taproot
                         witness_unknown)

  ## API

  @doc """
  Creates a changeset for the `ScriptPubKey` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(script_pub_key, attrs) do
    script_pub_key
    |> cast(attrs, @optional_fields)
    |> validate_inclusion(:type, @valid_script_types)
    |> validate_number(:req_sigs, greater_than_or_equal_to: 0)
  end
end

defmodule BTx.RPC.RawTransactions.RawTransaction.Vout do
  @moduledoc """
  Represents a transaction output (vout) from the `getrawtransaction` JSON RPC API.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias __MODULE__.ScriptPubKey

  ## Types & Schema

  @typedoc "Transaction output (vout)"
  @type t() :: %__MODULE__{
          value: float() | nil,
          n: non_neg_integer() | nil,
          script_pub_key: ScriptPubKey.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :value, :float
    field :n, :integer
    embeds_one :script_pub_key, ScriptPubKey
  end

  @optional_fields ~w(value n)a

  ## API

  @doc """
  Creates a changeset for the `Vout` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(vout, attrs) do
    vout
    |> cast(normalize_attrs(attrs), @optional_fields)
    |> cast_embed(:script_pub_key, with: &ScriptPubKey.changeset/2)
    |> validate_number(:value, greater_than_or_equal_to: 0)
    |> validate_number(:n, greater_than_or_equal_to: 0)
  end
end
