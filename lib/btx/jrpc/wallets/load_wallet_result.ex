defmodule BTx.JRPC.Wallets.LoadWalletResult do
  @moduledoc """
  Result from the `loadwallet` JSON RPC API.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Response

  ## Types & Schema

  @typedoc "LoadWalletResult"
  @type t() :: %__MODULE__{
          name: String.t() | nil,
          warning: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :name, :string
    field :warning, :string
  end

  @required_fields ~w(name)a
  @optional_fields ~w(warning)a

  ## API

  @doc """
  Creates a new `LoadWalletResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:loadwallet_result)
  end

  @doc """
  Creates a new `LoadWalletResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:loadwallet_result)
  end

  @doc """
  Creates a changeset for the `LoadWalletResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
