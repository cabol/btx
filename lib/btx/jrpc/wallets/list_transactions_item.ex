defmodule BTx.JRPC.Wallets.ListTransactionsItem do
  @moduledoc """
  Represents a single transaction item from the `listtransactions` JSON RPC API.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "ListTransactionsItem"
  @type t() :: %__MODULE__{
          involvesWatchonly: boolean() | nil,
          address: String.t() | nil,
          category: String.t() | nil,
          amount: float() | nil,
          label: String.t() | nil,
          vout: integer() | nil,
          fee: float() | nil,
          confirmations: integer() | nil,
          generated: boolean() | nil,
          trusted: boolean() | nil,
          blockhash: String.t() | nil,
          blockheight: integer() | nil,
          blockindex: integer() | nil,
          blocktime: integer() | nil,
          txid: String.t() | nil,
          walletconflicts: [String.t()],
          time: integer() | nil,
          timereceived: integer() | nil,
          comment: String.t() | nil,
          bip125_replaceable: String.t() | nil,
          abandoned: boolean() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :involvesWatchonly, :boolean
    field :address, :string
    field :category, :string
    field :amount, :float
    field :label, :string
    field :vout, :integer
    field :fee, :float
    field :confirmations, :integer
    field :generated, :boolean
    field :trusted, :boolean
    field :blockhash, :string
    field :blockheight, :integer
    field :blockindex, :integer
    field :blocktime, :integer
    field :txid, :string
    field :walletconflicts, {:array, :string}, default: []
    field :time, :integer
    field :timereceived, :integer
    field :comment, :string
    field :bip125_replaceable, :string
    field :abandoned, :boolean
  end

  @required_fields ~w(category amount txid time timereceived)a
  @optional_fields ~w(involvesWatchonly address label vout fee confirmations
                      generated trusted blockhash blockheight blockindex
                      blocktime walletconflicts comment bip125_replaceable
                      abandoned)a

  ## API

  @doc """
  Creates a new `ListTransactionsItem` schema.
  """
  @spec new(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action(:listtransactions_item)
  end

  @doc """
  Creates a new `ListTransactionsItem` schema.
  """
  @spec new!(map()) :: t()
  def new!(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action!(:listtransactions_item)
  end

  @doc """
  Creates a changeset for the `ListTransactionsItem` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:txid, is: 64)
    |> validate_format(:txid, ~r/^[a-fA-F0-9]{64}$/)
    |> validate_inclusion(:category, ["send", "receive", "generate", "immature", "orphan"])
    |> validate_number(:vout, greater_than_or_equal_to: 0)
    |> validate_number(:blockheight, greater_than_or_equal_to: 0)
    |> validate_number(:blockindex, greater_than_or_equal_to: 0)
    |> validate_number(:blocktime, greater_than_or_equal_to: 0)
    |> validate_number(:time, greater_than_or_equal_to: 0)
    |> validate_number(:timereceived, greater_than_or_equal_to: 0)
    |> validate_inclusion(:bip125_replaceable, ["yes", "no", "unknown"])
    |> validate_blockhash_format()
  end

  ## Private functions

  # Custom validation for blockhash format (64 character hex string)
  defp validate_blockhash_format(changeset) do
    validate_change(changeset, :blockhash, fn :blockhash, blockhash when is_binary(blockhash) ->
      if String.length(blockhash) == 64 and String.match?(blockhash, ~r/^[a-fA-F0-9]{64}$/) do
        []
      else
        [blockhash: "must be a 64-character hexadecimal string"]
      end
    end)
  end
end
