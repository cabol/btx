defmodule BTx.RPC.Blockchain.GetBlockResultV1 do
  @moduledoc """
  Result from the `getblock` JSON RPC API when verbosity is set to 1.

  Returns block information with transaction IDs as strings.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "GetBlockResultV1"
  @type t() :: %__MODULE__{
          hash: String.t() | nil,
          confirmations: integer() | nil,
          size: non_neg_integer() | nil,
          strippedsize: non_neg_integer() | nil,
          weight: non_neg_integer() | nil,
          height: non_neg_integer() | nil,
          version: non_neg_integer() | nil,
          version_hex: String.t() | nil,
          merkleroot: String.t() | nil,
          tx: [String.t()],
          time: non_neg_integer() | nil,
          mediantime: non_neg_integer() | nil,
          nonce: non_neg_integer() | nil,
          bits: String.t() | nil,
          difficulty: float() | nil,
          chainwork: String.t() | nil,
          n_tx: non_neg_integer() | nil,
          previousblockhash: String.t() | nil,
          nextblockhash: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :hash, :string
    field :confirmations, :integer
    field :size, :integer
    field :strippedsize, :integer
    field :weight, :integer
    field :height, :integer
    field :version, :integer
    field :version_hex, :string
    field :merkleroot, :string
    field :tx, {:array, :string}, default: []
    field :time, :integer
    field :mediantime, :integer
    field :nonce, :integer
    field :bits, :string
    field :difficulty, :float
    field :chainwork, :string
    field :n_tx, :integer
    field :previousblockhash, :string
    field :nextblockhash, :string
  end

  @optional_fields ~w(hash confirmations size strippedsize weight height version
                      version_hex merkleroot tx time mediantime nonce bits difficulty
                      chainwork n_tx previousblockhash nextblockhash)a

  ## API

  @doc """
  Creates a new `GetBlockResultV1` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:getblock_result_v1)
  end

  @doc """
  Creates a new `GetBlockResultV1` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:getblock_result_v1)
  end

  @doc """
  Creates a changeset for the `GetBlockResultV1` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(normalize_attrs(attrs), @optional_fields)
    |> validate_hex64(:hash)
    |> validate_hex64(:merkleroot)
    |> validate_hex64(:previousblockhash)
    |> validate_hex64(:nextblockhash)
    |> validate_hex64(:chainwork)
    |> validate_hex8(:version_hex)
    |> validate_hex8(:bits)
    |> validate_positive_numbers()
  end

  ## Private functions

  # Validate that numeric fields are positive when present
  defp validate_positive_numbers(changeset) do
    changeset
    |> validate_number(:size, greater_than: 0)
    |> validate_number(:strippedsize, greater_than: 0)
    |> validate_number(:weight, greater_than: 0)
    |> validate_number(:height, greater_than_or_equal_to: 0)
    |> validate_number(:version, greater_than_or_equal_to: 0)
    |> validate_number(:time, greater_than_or_equal_to: 0)
    |> validate_number(:mediantime, greater_than_or_equal_to: 0)
    |> validate_number(:nonce, greater_than_or_equal_to: 0)
    |> validate_number(:difficulty, greater_than_or_equal_to: 0)
    |> validate_number(:n_tx, greater_than_or_equal_to: 0)
  end
end

defmodule BTx.RPC.Blockchain.GetBlockResultV2 do
  @moduledoc """
  Result from the `getblock` JSON RPC API when verbosity is set to 2.

  Returns block information with full transaction details using the
  `BTx.RPC.RawTransactions.GetRawTransactionResult` schema.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.RawTransactions.GetRawTransactionResult
  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "GetBlockResultV2"
  @type t() :: %__MODULE__{
          hash: String.t() | nil,
          confirmations: integer() | nil,
          size: non_neg_integer() | nil,
          strippedsize: non_neg_integer() | nil,
          weight: non_neg_integer() | nil,
          height: non_neg_integer() | nil,
          version: non_neg_integer() | nil,
          version_hex: String.t() | nil,
          merkleroot: String.t() | nil,
          tx: [GetRawTransactionResult.t()],
          time: non_neg_integer() | nil,
          mediantime: non_neg_integer() | nil,
          nonce: non_neg_integer() | nil,
          bits: String.t() | nil,
          difficulty: float() | nil,
          chainwork: String.t() | nil,
          n_tx: non_neg_integer() | nil,
          previousblockhash: String.t() | nil,
          nextblockhash: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :hash, :string
    field :confirmations, :integer
    field :size, :integer
    field :strippedsize, :integer
    field :weight, :integer
    field :height, :integer
    field :version, :integer
    field :version_hex, :string
    field :merkleroot, :string
    embeds_many :tx, GetRawTransactionResult
    field :time, :integer
    field :mediantime, :integer
    field :nonce, :integer
    field :bits, :string
    field :difficulty, :float
    field :chainwork, :string
    field :n_tx, :integer
    field :previousblockhash, :string
    field :nextblockhash, :string
  end

  @optional_fields ~w(hash confirmations size strippedsize weight height version
                      version_hex merkleroot time mediantime nonce bits difficulty
                      chainwork n_tx previousblockhash nextblockhash)a

  ## API

  @doc """
  Creates a new `GetBlockResultV2` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:getblock_result_v2)
  end

  @doc """
  Creates a new `GetBlockResultV2` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:getblock_result_v2)
  end

  @doc """
  Creates a changeset for the `GetBlockResultV2` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(normalize_attrs(attrs), @optional_fields)
    |> cast_embed(:tx, with: &GetRawTransactionResult.changeset/2)
    |> validate_hex64(:hash)
    |> validate_hex64(:merkleroot)
    |> validate_hex64(:previousblockhash)
    |> validate_hex64(:nextblockhash)
    |> validate_hex64(:chainwork)
    |> validate_hex8(:version_hex)
    |> validate_hex8(:bits)
    |> validate_positive_numbers()
  end

  ## Private functions

  # Validate that numeric fields are positive when present
  defp validate_positive_numbers(changeset) do
    changeset
    |> validate_number(:size, greater_than: 0)
    |> validate_number(:strippedsize, greater_than: 0)
    |> validate_number(:weight, greater_than: 0)
    |> validate_number(:height, greater_than_or_equal_to: 0)
    |> validate_number(:version, greater_than_or_equal_to: 0)
    |> validate_number(:time, greater_than_or_equal_to: 0)
    |> validate_number(:mediantime, greater_than_or_equal_to: 0)
    |> validate_number(:nonce, greater_than_or_equal_to: 0)
    |> validate_number(:difficulty, greater_than_or_equal_to: 0)
    |> validate_number(:n_tx, greater_than_or_equal_to: 0)
  end
end
