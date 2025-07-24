defmodule BTx.JRPC.Wallets.CreateWallet do
  @moduledoc """
  Creates and loads a new wallet.

  ## Schema fields (a.k.a "Arguments")

  - `:wallet_name` - (required) The name for the new wallet. If this is a path,
    the wallet will be created at the path location. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  - `:disable_private_keys` - (optional) Disable the possibility of private
    keys (only watchonlys are possible in this mode). Defaults to `false`.

  - `:blank` - (optional) Create a blank wallet. A blank wallet has no keys or
    HD seed. One can be set using sethdseed. Defaults to `false`.

  - `:passphrase` - (required) Encrypt the wallet with this passphrase.

  - `:avoid_reuse` - (optional) Keep track of coin reuse, and treat dirty and
    clean coins differently with privacy considerations in mind. Defaults to
    `false`.

  - `:descriptors` - (optional) Create a native descriptor wallet. The wallet
    will use descriptors internally to handle address creation. Defaults to
    `false`.

  - `:load_on_startup` - (optional) Save wallet name to persistent settings and
    load on startup. True to add wallet to startup list, false to remove, null
    to leave unchanged. Defaults to `nil`.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.JRPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `createwallet`][createwallet].
  [createwallet]: https://developer.bitcoin.org/reference/rpc/createwallet.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Request

  ## Types & Schema

  @typedoc "CreateWallet request"
  @type t() :: %__MODULE__{
          method: String.t(),
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
    # Predefined fields
    field :method, :string, default: "createwallet"

    # Method fields
    field :wallet_name, :string
    field :disable_private_keys, :boolean, default: false
    field :blank, :boolean, default: false
    field :passphrase, :string
    field :avoid_reuse, :boolean, default: false
    field :descriptors, :boolean, default: false
    field :load_on_startup, Ecto.Enum, values: [true, false, nil], default: nil
  end

  @required_fields ~w(wallet_name)a
  @optional_fields ~w(disable_private_keys blank passphrase avoid_reuse descriptors load_on_startup)a

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
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

      Request.new(
        method: method,
        params: params
      )
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
