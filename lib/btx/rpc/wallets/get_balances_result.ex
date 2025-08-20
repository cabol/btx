defmodule BTx.RPC.Wallets.GetBalancesResult do
  @moduledoc """
  Result from the `getbalances` JSON RPC API.

  Returns an object with all balances in BTC, including both "mine" (balances
  from outputs that the wallet can sign) and optionally "watchonly" balances
  (not present if wallet does not watch anything).
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.{Response, Wallets.GetBalancesDetail}

  ## Types & Schema

  @typedoc "GetBalancesResult"
  @type t() :: %__MODULE__{
          mine: GetBalancesDetail.t() | nil,
          watchonly: GetBalancesDetail.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    embeds_one :mine, GetBalancesDetail
    embeds_one :watchonly, GetBalancesDetail
  end

  @required_fields ~w()a
  @optional_fields ~w()a

  ## API

  @doc """
  Creates a new `GetBalancesResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:getbalances_result)
  end

  @doc """
  Creates a new `GetBalancesResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:getbalances_result)
  end

  @doc """
  Creates a changeset for the `GetBalancesResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:mine, required: false)
    |> cast_embed(:watchonly, required: false)
  end
end
