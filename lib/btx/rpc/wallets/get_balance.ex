defmodule BTx.RPC.Wallets.GetBalance do
  @moduledoc """
  Returns the total available balance.

  The available balance is what the wallet considers currently spendable,
  and is thus affected by options which limit spendability such as
  `-spendzeroconfchange`.

  ## Schema fields (a.k.a "Arguments")

  - `:dummy` - (optional) Remains for backward compatibility. Must be excluded
    or set to "*". Defaults to "*".

  - `:minconf` - (optional) Only include transactions confirmed at least this
    many times. Defaults to `0`.

  - `:include_watchonly` - (optional) Also include balance in watch-only
    addresses (see `importaddress`). Defaults to `true` for watch-only wallets,
    otherwise `false`.

  - `:avoid_reuse` - (optional) (only available if `avoid_reuse` wallet flag
    is set) Do not include balance in dirty outputs; addresses are considered
    dirty if they have previously been used in a transaction. Defaults to
    `true`.

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `getbalance`][getbalance].
  [getbalance]: https://developer.bitcoin.org/reference/rpc/getbalance.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetBalance request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          dummy: String.t() | nil,
          minconf: non_neg_integer(),
          include_watchonly: boolean() | nil,
          avoid_reuse: boolean()
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getbalance"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :dummy, :string, default: "*"
    field :minconf, :integer, default: 0
    field :include_watchonly, :boolean, default: true
    field :avoid_reuse, :boolean, default: true
  end

  @optional_fields ~w(dummy minconf include_watchonly avoid_reuse wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          dummy: dummy,
          minconf: minconf,
          include_watchonly: include_watchonly,
          avoid_reuse: avoid_reuse,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: [dummy, minconf, include_watchonly, avoid_reuse]
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetBalance` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getbalance)
  end

  @doc """
  Creates a new `GetBalance` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getbalance)
  end

  @doc """
  Creates a changeset for the `GetBalance` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @optional_fields)
    |> validate_inclusion(:dummy, ["*"])
    |> validate_number(:minconf, greater_than_or_equal_to: 0)
    |> validate_length(:wallet_name, min: 1, max: 64)
  end
end
