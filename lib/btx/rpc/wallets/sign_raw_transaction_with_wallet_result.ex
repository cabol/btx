defmodule BTx.RPC.Wallets.SignRawTransactionWithWalletResult do
  @moduledoc """
  Result from the `signrawtransactionwithwallet` JSON RPC API.

  Returns the hex-encoded raw transaction with signatures and completion status.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.RawTransactions.RawTransaction.ScriptVerificationError
  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "SignRawTransactionWithWalletResult"
  @type t() :: %__MODULE__{
          hex: String.t() | nil,
          complete: boolean() | nil,
          errors: [ScriptVerificationError.t()]
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :hex, :string
    field :complete, :boolean
    embeds_many :errors, ScriptVerificationError
  end

  @optional_fields ~w(hex complete)a

  ## API

  @doc """
  Creates a new `SignRawTransactionWithWalletResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:signrawtransactionwithwallet_result)
  end

  @doc """
  Creates a new `SignRawTransactionWithWalletResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:signrawtransactionwithwallet_result)
  end

  @doc """
  Creates a changeset for the `SignRawTransactionWithWalletResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(attrs, @optional_fields)
    |> cast_embed(:errors, with: &ScriptVerificationError.changeset/2)
    |> validate_hexstring(:hex)
  end
end
