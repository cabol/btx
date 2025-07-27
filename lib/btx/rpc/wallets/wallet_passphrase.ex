defmodule BTx.RPC.Wallets.WalletPassphrase do
  @moduledoc """
  Stores the wallet decryption key in memory for 'timeout' seconds.

  This is needed prior to performing transactions related to private keys such as
  sending bitcoins.

  ## Schema fields (a.k.a "Arguments")

  - `:passphrase` - (required) The wallet passphrase.

  - `:timeout` - (required) The time to keep the decryption key in seconds.
    Capped at 100000000 (~3 years).

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  ## Notes

  Issuing the walletpassphrase command while the wallet is already unlocked will
  set a new unlock time that overrides the old one.

  See [Bitcoin RPC API Reference `walletpassphrase`][walletpassphrase].
  [walletpassphrase]: https://developer.bitcoin.org/reference/rpc/walletpassphrase.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Constants

  # Maximum timeout value (~3 years)
  @max_timeout 100_000_000

  ## Types & Schema

  @typedoc "WalletPassphrase request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          passphrase: String.t() | nil,
          timeout: non_neg_integer() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "walletpassphrase"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :passphrase, :string
    field :timeout, :integer
  end

  @required_fields ~w(passphrase timeout)a
  @optional_fields ~w(wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          passphrase: passphrase,
          timeout: timeout,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: [passphrase, timeout]
      )
    end
  end

  ## API

  @doc """
  Creates a new `WalletPassphrase` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:walletpassphrase)
  end

  @doc """
  Creates a new `WalletPassphrase` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:walletpassphrase)
  end

  @doc """
  Creates a changeset for the `WalletPassphrase` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:passphrase, min: 1, max: 1024)
    |> validate_number(:timeout, greater_than: 0, less_than_or_equal_to: @max_timeout)
    |> validate_wallet_name()
  end
end
