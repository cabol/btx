defmodule BTx.JRPC.Wallets.GetWalletInfoResult do
  @moduledoc """
  Result from the `getwalletinfo` JSON RPC API.

  Contains various wallet state information.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Response

  ## Types & Schema

  @typedoc "GetWalletInfoResult"
  @type t() :: %__MODULE__{
          walletname: String.t() | nil,
          walletversion: integer() | nil,
          format: String.t() | nil,
          balance: float() | nil,
          unconfirmed_balance: float() | nil,
          immature_balance: float() | nil,
          txcount: integer() | nil,
          keypoololdest: integer() | nil,
          keypoolsize: integer() | nil,
          keypoolsize_hd_internal: integer() | nil,
          unlocked_until: integer() | nil,
          paytxfee: float() | nil,
          hdseedid: String.t() | nil,
          private_keys_enabled: boolean() | nil,
          avoid_reuse: boolean() | nil,
          scanning: map() | boolean() | nil,
          descriptors: boolean() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :walletname, :string
    field :walletversion, :integer
    field :format, :string
    field :balance, :float
    field :unconfirmed_balance, :float
    field :immature_balance, :float
    field :txcount, :integer
    field :keypoololdest, :integer
    field :keypoolsize, :integer
    field :keypoolsize_hd_internal, :integer
    field :unlocked_until, :integer
    field :paytxfee, :float
    field :hdseedid, :string
    field :private_keys_enabled, :boolean
    field :avoid_reuse, :boolean
    field :scanning, BTx.Ecto.Types.Scanning
    field :descriptors, :boolean
  end

  @required_fields ~w(walletname walletversion format txcount keypoolsize
                      private_keys_enabled avoid_reuse descriptors)a
  @optional_fields ~w(balance unconfirmed_balance immature_balance keypoololdest
                      keypoolsize_hd_internal unlocked_until paytxfee hdseedid
                      scanning)a

  ## API

  @doc """
  Creates a new `GetWalletInfoResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:getwalletinfo_result)
  end

  @doc """
  Creates a new `GetWalletInfoResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:getwalletinfo_result)
  end

  @doc """
  Creates a changeset for the `GetWalletInfoResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:walletversion, greater_than: 0)
    |> validate_number(:txcount, greater_than_or_equal_to: 0)
    |> validate_number(:keypoolsize, greater_than_or_equal_to: 0)
    |> validate_number(:keypoolsize_hd_internal, greater_than_or_equal_to: 0)
    |> validate_number(:keypoololdest, greater_than: 0)
    |> validate_number(:unlocked_until, greater_than_or_equal_to: 0)
    |> validate_number(:paytxfee, greater_than_or_equal_to: 0)
    |> validate_inclusion(:format, ["bdb", "sqlite"])
  end
end
