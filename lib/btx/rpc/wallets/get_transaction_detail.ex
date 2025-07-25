defmodule BTx.RPC.Wallets.GetTransactionDetail do
  @moduledoc """
  Represents a single transaction detail from the `gettransaction` JSON RPC API.

  Each detail represents an address involved in the transaction with its
  associated information like category, amount, and other metadata.

  ## Fields

  - `:involvesWatchonly` - Only returns true if imported addresses were involved in transaction.
  - `:address` - The bitcoin address involved in the transaction.
  - `:category` - The transaction category (send, receive, generate, immature, orphan).
  - `:amount` - The amount in BTC.
  - `:label` - A comment for the address/transaction, if any.
  - `:vout` - The vout value.
  - `:fee` - The amount of the fee in BTC (negative, only for 'send' category).
  - `:abandoned` - True if the transaction has been abandoned (only for 'send' category).
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "GetTransactionDetail"
  @type t() :: %__MODULE__{
          involves_watchonly: boolean() | nil,
          address: String.t() | nil,
          category: String.t() | nil,
          amount: float() | nil,
          label: String.t() | nil,
          vout: integer() | nil,
          fee: float() | nil,
          abandoned: boolean() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :involves_watchonly, :boolean
    field :address, :string
    field :category, :string
    field :amount, :float
    field :label, :string
    field :vout, :integer
    field :fee, :float
    field :abandoned, :boolean
  end

  @required_fields ~w(category amount)a
  @optional_fields ~w(involves_watchonly address label vout fee abandoned)a

  # Valid transaction categories
  @valid_categories ~w(send receive generate immature orphan)

  ## API

  @doc """
  Creates a changeset for the `GetTransactionDetail` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(normalize_attrs(attrs), @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:category, @valid_categories)
  end
end
