defmodule BTx.RPC.Blockchain.GetMempoolEntryResult do
  @moduledoc """
  Result from the `getmempoolentry` JSON RPC API.

  Returns mempool data for given transaction.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Blockchain.GetMempoolEntryFees
  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "GetMempoolEntryResult"
  @type t() :: %__MODULE__{
          vsize: non_neg_integer() | nil,
          weight: non_neg_integer() | nil,
          fee: float() | nil,
          modifiedfee: float() | nil,
          time: non_neg_integer() | nil,
          height: non_neg_integer() | nil,
          descendantcount: non_neg_integer() | nil,
          descendantsize: non_neg_integer() | nil,
          descendantfees: float() | nil,
          ancestorcount: non_neg_integer() | nil,
          ancestorsize: non_neg_integer() | nil,
          ancestorfees: float() | nil,
          wtxid: String.t() | nil,
          fees: GetMempoolEntryFees.t() | nil,
          depends: [String.t()],
          spentby: [String.t()],
          bip125_replaceable: boolean() | nil,
          unbroadcast: boolean() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :vsize, :integer
    field :weight, :integer
    field :fee, :float
    field :modifiedfee, :float
    field :time, :integer
    field :height, :integer
    field :descendantcount, :integer
    field :descendantsize, :integer
    field :descendantfees, :float
    field :ancestorcount, :integer
    field :ancestorsize, :integer
    field :ancestorfees, :float
    field :wtxid, :string
    embeds_one :fees, GetMempoolEntryFees
    field :depends, {:array, :string}, default: []
    field :spentby, {:array, :string}, default: []
    field :bip125_replaceable, :boolean
    field :unbroadcast, :boolean
  end

  @required_fields ~w(vsize weight time height descendantcount descendantsize
                      ancestorcount ancestorsize wtxid)a
  @optional_fields ~w(fee modifiedfee descendantfees ancestorfees depends
                      spentby bip125_replaceable unbroadcast)a

  ## API

  @doc """
  Creates a new `GetMempoolEntryResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action(:getmempoolentry_result)
  end

  @doc """
  Creates a new `GetMempoolEntryResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action!(:getmempoolentry_result)
  end

  @doc """
  Creates a changeset for the `GetMempoolEntryResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:fees, with: &GetMempoolEntryFees.changeset/2)
    |> validate_required(@required_fields)
    |> validate_number(:vsize, greater_than: 0)
    |> validate_number(:weight, greater_than: 0)
    |> validate_number(:fee, greater_than_or_equal_to: 0)
    |> validate_number(:modifiedfee, greater_than_or_equal_to: 0)
    |> validate_number(:time, greater_than: 0)
    |> validate_number(:height, greater_than_or_equal_to: 0)
    |> validate_number(:descendantcount, greater_than: 0)
    |> validate_number(:descendantsize, greater_than: 0)
    |> validate_number(:descendantfees, greater_than_or_equal_to: 0)
    |> validate_number(:ancestorcount, greater_than: 0)
    |> validate_number(:ancestorsize, greater_than: 0)
    |> validate_number(:ancestorfees, greater_than_or_equal_to: 0)
    |> validate_length(:wtxid, is: 64)
    |> validate_format(:wtxid, ~r/^[a-fA-F0-9]{64}$/)
  end
end
