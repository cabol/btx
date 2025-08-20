defmodule BTx.RPC.Wallets.GetBalancesDetail do
  @moduledoc """
  Embedded schema for balance details in the `getbalances` JSON RPC API
  response.

  Contains detailed balance information for either "mine" or "watchonly"
  balances.
  """

  use Ecto.Schema

  import Ecto.Changeset

  ## Types & Schema

  @typedoc "GetBalancesDetail"
  @type t() :: %__MODULE__{
          trusted: float() | nil,
          untrusted_pending: float() | nil,
          immature: float() | nil,
          used: float() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :trusted, :float
    field :untrusted_pending, :float
    field :immature, :float
    field :used, :float
  end

  @required_fields ~w(trusted untrusted_pending immature)a
  @optional_fields ~w(used)a

  ## API

  @doc """
  Creates a new `GetBalancesDetail` schema.
  """
  @spec new(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:getbalances_detail)
  end

  @doc """
  Creates a new `GetBalancesDetail` schema.
  """
  @spec new!(map()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:getbalances_detail)
  end

  @doc """
  Creates a changeset for the `GetBalancesDetail` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:trusted, greater_than_or_equal_to: 0)
    |> validate_number(:untrusted_pending, greater_than_or_equal_to: 0)
    |> validate_number(:immature, greater_than_or_equal_to: 0)
    |> validate_number(:used, greater_than_or_equal_to: 0)
  end
end
