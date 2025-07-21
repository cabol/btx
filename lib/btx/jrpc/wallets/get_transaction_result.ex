defmodule BTx.JRPC.Wallets.GetTransactionResult do
  @moduledoc """
  Result from the `gettransaction` JSON RPC API.

  Represents detailed information about an in-wallet transaction.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Response

  ## Types & Schema

  @typedoc "GetTransactionResult"
  @type t() :: %__MODULE__{
          amount: number() | nil,
          fee: number() | nil,
          confirmations: integer() | nil,
          generated: boolean() | nil,
          trusted: boolean() | nil,
          blockhash: String.t() | nil,
          blockheight: non_neg_integer() | nil,
          blockindex: non_neg_integer() | nil,
          blocktime: non_neg_integer() | nil,
          txid: String.t() | nil,
          walletconflicts: [String.t()],
          time: non_neg_integer() | nil,
          timereceived: non_neg_integer() | nil,
          comment: String.t() | nil,
          bip125_replaceable: String.t() | nil,
          details: [map()],
          hex: String.t() | nil,
          decoded: map() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :amount, :float
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
    field :details, {:array, :map}, default: []
    field :hex, :string
    field :decoded, :map
  end

  @required_fields ~w(amount confirmations txid time timereceived hex)a
  @optional_fields ~w(fee generated trusted blockhash blockheight blockindex blocktime
                      walletconflicts comment bip125_replaceable details decoded)a

  ## API

  @doc """
  Creates a new `GetTransactionResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action(:gettransaction)
  end

  @doc """
  Creates a new `GetTransactionResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action!(:gettransaction)
  end

  @doc """
  Creates a changeset for the `GetTransactionResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:txid, is: 64)
    |> validate_format(:txid, ~r/^[a-fA-F0-9]{64}$/)
    |> validate_number(:blockheight, greater_than_or_equal_to: 0)
    |> validate_number(:blockindex, greater_than_or_equal_to: 0)
    |> validate_number(:blocktime, greater_than_or_equal_to: 0)
    |> validate_number(:time, greater_than_or_equal_to: 0)
    |> validate_number(:timereceived, greater_than_or_equal_to: 0)
    |> validate_inclusion(:bip125_replaceable, ["yes", "no", "unknown"])
  end

  # Private functions

  # Normalize attributes from Bitcoin Core JSON response format to our schema format
  defp normalize_attrs(attrs) when is_map(attrs) do
    attrs
    |> Enum.map(&normalize_field/1)
    |> Enum.into(%{})
  end

  # Handle field name mapping from Bitcoin Core JSON to our schema
  defp normalize_field({"bip125-replaceable", value}), do: {"bip125_replaceable", value}
  defp normalize_field({key, value}), do: {key, value}
end
