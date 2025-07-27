defmodule BTx.RPC.Wallets.GetAddressesByLabel do
  @moduledoc """
  Returns the list of addresses assigned the specified label.

  ## Schema fields (a.k.a "Arguments")

  - `:label` - (required) The label.

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `getaddressesbylabel`][getaddressesbylabel].
  [getaddressesbylabel]: https://developer.bitcoin.org/reference/rpc/getaddressesbylabel.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetAddressesByLabel request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          label: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getaddressesbylabel"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :label, :string
  end

  @required_fields ~w(label)a
  @optional_fields ~w(wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          label: label,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: [label]
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetAddressesByLabel` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getaddressesbylabel)
  end

  @doc """
  Creates a new `GetAddressesByLabel` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getaddressesbylabel)
  end

  @doc """
  Creates a changeset for the `GetAddressesByLabel` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields, empty_values: [])
    |> validate_required_label()
    |> validate_length(:label, max: 64)
    |> validate_wallet_name()
  end

  ## Private functions

  defp validate_required_label(changeset) do
    case fetch_change(changeset, :label) do
      {:ok, _label} -> changeset
      :error -> add_error(changeset, :label, "can't be blank", validation: :required)
    end
  end
end
