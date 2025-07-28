defmodule BTx.RPC.RawTransactions.GetRawTransaction.Vin do
  @moduledoc """
  Represents a transaction input (vin) from the `getrawtransaction`
  JSON RPC API.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "Transaction input (vin)"
  @type t() :: %__MODULE__{
          txid: String.t() | nil,
          vout: non_neg_integer() | nil,
          script_sig: map() | nil,
          sequence: non_neg_integer() | nil,
          txinwitness: [String.t()]
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :txid, :string
    field :vout, :integer
    field :script_sig, :map
    field :sequence, :integer
    field :txinwitness, {:array, :string}, default: []
  end

  @optional_fields ~w(txid vout script_sig sequence txinwitness)a

  ## API

  @doc """
  Creates a changeset for the `Vin` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(vin, attrs) do
    vin
    |> cast(attrs, @optional_fields)
    |> validate_txid()
    |> validate_number(:vout, greater_than_or_equal_to: 0)
    |> validate_number(:sequence, greater_than_or_equal_to: 0)
  end
end

defmodule BTx.RPC.RawTransactions.GetRawTransaction.Vout.ScriptPubKey do
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

defmodule BTx.RPC.RawTransactions.GetRawTransaction.Vout do
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

defmodule BTx.RPC.RawTransactions.GetRawTransactionResult do
  @moduledoc """
  Result from the `getrawtransaction` JSON RPC API when verbose is set to true.

  Returns detailed information about a transaction including inputs, outputs, and metadata.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.RawTransactions.GetRawTransaction.{Vin, Vout}
  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "GetRawTransactionResult"
  @type t() :: %__MODULE__{
          in_active_chain: boolean() | nil,
          hex: String.t() | nil,
          txid: String.t() | nil,
          hash: String.t() | nil,
          size: non_neg_integer() | nil,
          vsize: non_neg_integer() | nil,
          weight: non_neg_integer() | nil,
          version: non_neg_integer() | nil,
          locktime: non_neg_integer() | nil,
          vin: [Vin.t()],
          vout: [Vout.t()],
          blockhash: String.t() | nil,
          confirmations: integer() | nil,
          blocktime: non_neg_integer() | nil,
          time: non_neg_integer() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :in_active_chain, :boolean
    field :hex, :string
    field :txid, :string
    field :hash, :string
    field :size, :integer
    field :vsize, :integer
    field :weight, :integer
    field :version, :integer
    field :locktime, :integer
    embeds_many :vin, Vin
    embeds_many :vout, Vout
    field :blockhash, :string
    field :confirmations, :integer
    field :blocktime, :integer
    field :time, :integer
  end

  @optional_fields ~w(in_active_chain hex txid hash size vsize weight version
                      locktime blockhash confirmations blocktime time)a

  ## API

  @doc """
  Creates a new `GetRawTransactionResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:getrawtransaction_result)
  end

  @doc """
  Creates a new `GetRawTransactionResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:getrawtransaction_result)
  end

  @doc """
  Creates a changeset for the `GetRawTransactionResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(normalize_attrs(attrs), @optional_fields)
    |> cast_embed(:vin, with: &Vin.changeset/2)
    |> cast_embed(:vout, with: &Vout.changeset/2)
    |> validate_length(:hex, greater_than: 0)
    |> validate_format(:hex, ~r/^[a-fA-F0-9]*$/)
    |> validate_txid()
    |> validate_hex64(:hash)
    |> validate_hex64(:blockhash)
    |> validate_number(:size, greater_than: 0)
    |> validate_number(:vsize, greater_than: 0)
    |> validate_number(:weight, greater_than: 0)
    |> validate_number(:version, greater_than_or_equal_to: 0)
    |> validate_number(:locktime, greater_than_or_equal_to: 0)
    |> validate_number(:blocktime, greater_than_or_equal_to: 0)
    |> validate_number(:time, greater_than_or_equal_to: 0)
  end
end
