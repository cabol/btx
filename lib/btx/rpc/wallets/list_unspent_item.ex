defmodule BTx.RPC.Wallets.ListUnspentItem do
  @moduledoc """
  Represents a single unspent transaction output from the `listunspent` JSON RPC API.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "ListUnspentItem"
  @type t() :: %__MODULE__{
          txid: String.t() | nil,
          vout: non_neg_integer() | nil,
          address: String.t() | nil,
          label: String.t() | nil,
          script_pub_key: String.t() | nil,
          amount: float() | nil,
          confirmations: integer() | nil,
          redeem_script: String.t() | nil,
          witness_script: String.t() | nil,
          spendable: boolean() | nil,
          solvable: boolean() | nil,
          reused: boolean() | nil,
          desc: String.t() | nil,
          safe: boolean() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :txid, :string
    field :vout, :integer
    field :address, :string
    field :label, :string
    field :script_pub_key, :string
    field :amount, :float
    field :confirmations, :integer
    field :redeem_script, :string
    field :witness_script, :string
    field :spendable, :boolean
    field :solvable, :boolean
    field :reused, :boolean
    field :desc, :string
    field :safe, :boolean
  end

  @required_fields ~w(txid vout amount confirmations spendable solvable safe)a
  @optional_fields ~w(address label script_pub_key redeem_script witness_script
                      reused desc)a

  ## API

  @doc """
  Creates a new `ListUnspentItem` schema.
  """
  @spec new(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action(:listunspent_item)
  end

  @doc """
  Creates a new `ListUnspentItem` schema.
  """
  @spec new!(map()) :: t()
  def new!(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action!(:listunspent_item)
  end

  @doc """
  Creates a changeset for the `ListUnspentItem` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(item, attrs) do
    item
    |> cast(attrs, @required_fields ++ @optional_fields, empty_values: [])
    |> validate_required(@required_fields)
  end
end
