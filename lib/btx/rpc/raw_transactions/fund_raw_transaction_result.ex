defmodule BTx.RPC.RawTransactions.FundRawTransactionResult do
  @moduledoc """
  Result from the `fundrawtransaction` JSON RPC API.

  Returns the funded raw transaction with fee information and change position.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "FundRawTransactionResult"
  @type t() :: %__MODULE__{
          hex: String.t() | nil,
          fee: float() | nil,
          changepos: integer() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :hex, :string
    field :fee, :float
    field :changepos, :integer
  end

  @optional_fields ~w(hex fee changepos)a

  ## API

  @doc """
  Creates a new `FundRawTransactionResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:fundrawtransaction_result)
  end

  @doc """
  Creates a new `FundRawTransactionResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:fundrawtransaction_result)
  end

  @doc """
  Creates a changeset for the `FundRawTransactionResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(attrs, @optional_fields)
    |> validate_hexstring(:hex)
    |> validate_number(:fee, greater_than_or_equal_to: 0)
    |> validate_changepos()
  end

  ## Private functions

  defp validate_changepos(changeset) do
    validate_change(changeset, :changepos, fn :changepos, changepos ->
      if changepos >= -1 do
        []
      else
        [changepos: "must be -1 (no change) or a non-negative integer"]
      end
    end)
  end
end
