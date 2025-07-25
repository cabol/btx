defmodule BTx.RPC.Blockchain.GetMempoolEntryFees do
  @moduledoc """
  Embedded schema for the fees object in GetMempoolEntry result.
  """

  use Ecto.Schema

  import Ecto.Changeset

  ## Types & Schema

  @typedoc "GetMempoolEntryFees"
  @type t() :: %__MODULE__{
          base: float() | nil,
          modified: float() | nil,
          ancestor: float() | nil,
          descendant: float() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :base, :float
    field :modified, :float
    field :ancestor, :float
    field :descendant, :float
  end

  @required_fields ~w(base modified ancestor descendant)a

  ## API

  @doc """
  Creates a changeset for the `GetMempoolEntryFees` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(fees, attrs) do
    fees
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:base, greater_than_or_equal_to: 0)
    |> validate_number(:modified, greater_than_or_equal_to: 0)
    |> validate_number(:ancestor, greater_than_or_equal_to: 0)
    |> validate_number(:descendant, greater_than_or_equal_to: 0)
  end
end
