defmodule BTx.RPC.Wallets.ListUnspentQueryOptions do
  @moduledoc """
  Embedded schema for query options in the `listunspent` JSON RPC API.

  JSON with query options for filtering unspent transaction outputs.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "ListUnspentQueryOptions"
  @type t() :: %__MODULE__{
          minimum_amount: float() | nil,
          maximum_amount: float() | nil,
          maximum_count: non_neg_integer() | nil,
          minimum_sum_amount: float() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :minimum_amount, :float
    field :maximum_amount, :float
    field :maximum_count, :integer
    field :minimum_sum_amount, :float
  end

  @optional_fields ~w(minimum_amount maximum_amount maximum_count minimum_sum_amount)a

  ## API

  @doc """
  Creates a changeset for the `ListUnspentQueryOptions` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(options, attrs) do
    options
    |> cast(normalize_attrs(attrs), @optional_fields)
    |> validate_number(:minimum_amount, greater_than_or_equal_to: 0)
    |> validate_number(:maximum_amount, greater_than_or_equal_to: 0)
    |> validate_number(:maximum_count, greater_than_or_equal_to: 1)
    |> validate_number(:minimum_sum_amount, greater_than_or_equal_to: 0)
  end

  @doc """
  Converts the `ListUnspentQueryOptions` schema to a map.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{
        minimum_amount: minimum_amount,
        maximum_amount: maximum_amount,
        maximum_count: maximum_count,
        minimum_sum_amount: minimum_sum_amount
      }) do
    %{
      "minimumAmount" => minimum_amount,
      "maximumAmount" => maximum_amount,
      "maximumCount" => maximum_count,
      "minimumSumAmount" => minimum_sum_amount
    }
  end
end
