defmodule BTx.RPC.Wallets.ListTransactions do
  @moduledoc """
  If a label name is provided, this will return only incoming transactions
  paying to addresses with the specified label.

  Returns up to 'count' most recent transactions skipping the first 'skip' transactions.

  ## Schema fields (a.k.a "Arguments")

  - `:label` - (optional) If set, should be a valid label name to return only
    incoming transactions with the specified label, or "*" to disable filtering
    and return all transactions.

  - `:count` - (optional) The number of transactions to return. Defaults to `10`.

  - `:skip` - (optional) The number of transactions to skip. Defaults to `0`.

  - `:include_watchonly` - (optional) Include transactions to watch-only addresses
    (see 'importaddress'). Defaults to `true` for watch-only wallets, otherwise `false`.

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `listtransactions`][listtransactions].
  [listtransactions]: https://developer.bitcoin.org/reference/rpc/listtransactions.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "ListTransactions request"
  @type t() :: %__MODULE__{
          method: String.t(),
          label: String.t() | nil,
          count: integer() | nil,
          skip: integer() | nil,
          include_watchonly: boolean() | nil,
          wallet_name: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "listtransactions"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :label, :string
    field :count, :integer, default: 10
    field :skip, :integer, default: 0
    field :include_watchonly, :boolean
  end

  @optional_fields ~w(label count skip include_watchonly wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          label: label,
          count: count,
          skip: skip,
          include_watchonly: include_watchonly,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: [label, count, skip, include_watchonly]
      )
    end
  end

  ## API

  @doc """
  Creates a new `ListTransactions` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:listtransactions)
  end

  @doc """
  Creates a new `ListTransactions` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:listtransactions)
  end

  @doc """
  Creates a changeset for the `ListTransactions` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @optional_fields)
    |> validate_number(:count, greater_than: 0)
    |> validate_number(:skip, greater_than_or_equal_to: 0)
    |> validate_length(:label, max: 255)
    |> validate_wallet_name()
  end
end
