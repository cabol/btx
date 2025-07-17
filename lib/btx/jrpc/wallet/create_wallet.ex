defmodule BTx.JRPC.Wallet.CreateWallet do
  @moduledoc """
  Create a new wallet.
  """

  use Ecto.Schema

  import BTx.JRPC.Helpers
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "CreateWallet request"
  @type t() :: %__MODULE__{
          wallet_name: String.t() | nil,
          disable_private_keys: boolean(),
          blank: boolean(),
          passphrase: String.t() | nil,
          avoid_reuse: boolean(),
          descriptors: boolean(),
          load_on_startup: atom()
        }

  @primary_key false
  embedded_schema do
    field :wallet_name, :string
    field :disable_private_keys, :boolean, default: false
    field :blank, :boolean, default: false
    field :passphrase, :string
    field :avoid_reuse, :boolean, default: false
    field :descriptors, :boolean, default: false
    field :load_on_startup, Ecto.Enum, values: [true, false, nil], default: nil
  end

  @required_fields ~w(wallet_name passphrase)a
  @optional_fields ~w(disable_private_keys blank avoid_reuse descriptors load_on_startup)a

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{
          wallet_name: wallet_name,
          disable_private_keys: disable_private_keys,
          blank: blank,
          passphrase: passphrase,
          avoid_reuse: avoid_reuse,
          descriptors: descriptors,
          load_on_startup: load_on_startup
        }) do
      params = [
        wallet_name,
        disable_private_keys,
        blank,
        passphrase,
        avoid_reuse,
        descriptors,
        load_on_startup
      ]

      Map.merge(common_params(), %{
        method: "createwallet",
        params: params
      })
    end
  end

  ## API

  @doc """
  Creates a new `CreateWallet` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:createwallet)
  end

  @doc """
  Creates a new `CreateWallet` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:createwallet)
  end

  @doc """
  Creates a changeset for the `CreateWallet` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:wallet_name, min: 1, max: 64)
    |> validate_length(:passphrase, min: 1, max: 1024)
    |> validate_format(:wallet_name, ~r/^[a-zA-Z0-9\-_]{1,64}$/)
  end
end
