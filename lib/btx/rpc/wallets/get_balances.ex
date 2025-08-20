defmodule BTx.RPC.Wallets.GetBalances do
  @moduledoc """
  Returns an object with all balances in BTC.

  ## Schema fields (a.k.a "Arguments")

  This method takes no parameters.

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `getbalances`][getbalances].
  [getbalances]: https://developer.bitcoin.org/reference/rpc/getbalances.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetBalances request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getbalances"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string
  end

  @optional_fields ~w(wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: []
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetBalances` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getbalances)
  end

  @doc """
  Creates a new `GetBalances` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getbalances)
  end

  @doc """
  Creates a changeset for the `GetBalances` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @optional_fields)
    |> validate_wallet_name()
  end
end
