defmodule BTx.RPC.Wallets.WalletLock do
  @moduledoc """
  Removes the wallet encryption key from memory, locking the wallet.

  After calling this method, you will need to call walletpassphrase again
  before being able to call any methods which require the wallet to be unlocked.

  ## Schema fields (a.k.a "Arguments")

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `walletlock`][walletlock].
  [walletlock]: https://developer.bitcoin.org/reference/rpc/walletlock.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "WalletLock request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "walletlock"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string
  end

  @required_fields []
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
  Creates a new `WalletLock` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:walletlock)
  end

  @doc """
  Creates a new `WalletLock` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:walletlock)
  end

  @doc """
  Creates a changeset for the `WalletLock` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_wallet_name()
  end
end
