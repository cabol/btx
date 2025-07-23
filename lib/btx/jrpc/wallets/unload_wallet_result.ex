defmodule BTx.JRPC.Wallets.UnloadWalletResult do
  @moduledoc """
  Result from the `unloadwallet` JSON RPC API.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Response

  ## Types & Schema

  @typedoc "UnloadWalletResult"
  @type t() :: %__MODULE__{
          warning: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :warning, :string
  end

  @optional_fields ~w(warning)a

  ## API

  @doc """
  Creates a new `UnloadWalletResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:unloadwallet_result)
  end

  @doc """
  Creates a new `UnloadWalletResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:unloadwallet_result)
  end

  @doc """
  Creates a changeset for the `UnloadWalletResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @optional_fields)
  end
end
