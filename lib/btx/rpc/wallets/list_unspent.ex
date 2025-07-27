defmodule BTx.RPC.Wallets.ListUnspent do
  @moduledoc """
  Returns array of unspent transaction outputs with between minconf and maxconf
  (inclusive) confirmations.

  Optionally filter to only include txouts paid to specified addresses.

  ## Schema fields (a.k.a "Arguments")

  - `:minconf` - (optional, default=1) The minimum confirmations to filter.

  - `:maxconf` - (optional, default=9999999) The maximum confirmations to filter.

  - `:addresses` - (optional, default=empty array) The bitcoin addresses to filter.

  - `:include_unsafe` - (optional, default=true) Include outputs that are not safe
    to spend. See description of "safe" attribute below.

  - `:query_options` - (optional) JSON with query options for filtering UTXOs.

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `listunspent`][listunspent].
  [listunspent]: https://developer.bitcoin.org/reference/rpc/listunspent.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request
  alias BTx.RPC.Wallets.ListUnspentQueryOptions

  ## Constants

  @default_minconf 1
  @default_maxconf 9_999_999

  ## Types & Schema

  @typedoc "ListUnspent request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          minconf: non_neg_integer() | nil,
          maxconf: non_neg_integer() | nil,
          addresses: [String.t()],
          include_unsafe: boolean() | nil,
          query_options: ListUnspentQueryOptions.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "listunspent"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :minconf, :integer, default: @default_minconf
    field :maxconf, :integer, default: @default_maxconf
    field :addresses, {:array, :string}, default: []
    field :include_unsafe, :boolean, default: true
    embeds_one :query_options, ListUnspentQueryOptions
  end

  @required_fields []
  @optional_fields ~w(wallet_name minconf maxconf addresses include_unsafe)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          minconf: minconf,
          maxconf: maxconf,
          addresses: addresses,
          include_unsafe: include_unsafe,
          query_options: query_options,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: [
          minconf,
          maxconf,
          addresses,
          include_unsafe,
          encode_query_options(query_options)
        ]
      )
    end

    defp encode_query_options(%ListUnspentQueryOptions{} = options) do
      ListUnspentQueryOptions.to_map(options)
    end

    defp encode_query_options(nil) do
      nil
    end
  end

  ## API

  @doc """
  Creates a new `ListUnspent` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:listunspent)
  end

  @doc """
  Creates a new `ListUnspent` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:listunspent)
  end

  @doc """
  Creates a changeset for the `ListUnspent` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:query_options)
    |> validate_number(:minconf, greater_than_or_equal_to: 0)
    |> validate_number(:maxconf, greater_than_or_equal_to: 0)
    |> validate_addresses_format()
    |> validate_wallet_name()
  end

  ## Private functions

  # Validate address format in the addresses array
  defp validate_addresses_format(changeset) do
    validate_change(changeset, :addresses, fn :addresses, addresses ->
      if Enum.all?(addresses, &valid_address?/1) do
        []
      else
        [addresses: "contains invalid Bitcoin addresses"]
      end
    end)
  end
end
