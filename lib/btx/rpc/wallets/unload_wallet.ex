defmodule BTx.RPC.Wallets.UnloadWallet do
  @moduledoc """
  Unloads the wallet referenced by the request endpoint otherwise unloads the
  wallet specified in the argument.

  Specifying the wallet name on a wallet endpoint is invalid.

  ## Schema fields (a.k.a "Arguments")

  - `:wallet_name` - (optional) The name of the wallet to unload. Must be
    provided in the RPC endpoint or this parameter (but not both). When not
    provided, uses the wallet name from the RPC endpoint.

  - `:load_on_startup` - (optional) Save wallet name to persistent settings and
    load on startup. True to add wallet to startup list, false to remove, null
    to leave unchanged. Defaults to `nil`.

  - `:endpoint_wallet_name` - (optional) When present, the `:endpoint_wallet_name`
    is used to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.
    Note: You cannot specify both `:wallet_name` and `:endpoint_wallet_name`.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `unloadwallet`][unloadwallet].
  [unloadwallet]: https://developer.bitcoin.org/reference/rpc/unloadwallet.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import BTx.Helpers, only: [trim_trailing_nil: 1]
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "UnloadWallet request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          load_on_startup: boolean() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "unloadwallet"

    # Method fields
    field :wallet_name, :string
    field :load_on_startup, Ecto.Enum, values: [true, false, nil], default: nil
  end

  @required_fields ~w(wallet_name)a
  @optional_fields ~w(load_on_startup)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          wallet_name: wallet_name,
          load_on_startup: load_on_startup
        }) do
      Request.new(
        method: method,
        params: trim_trailing_nil([wallet_name, load_on_startup])
      )
    end
  end

  ## API

  @doc """
  Creates a new `UnloadWallet` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:unloadwallet)
  end

  @doc """
  Creates a new `UnloadWallet` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:unloadwallet)
  end

  @doc """
  Creates a changeset for the `UnloadWallet` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_wallet_name()
  end
end
