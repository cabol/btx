defmodule BTx.RPC.Wallets.SignRawTransactionWithWallet do
  @moduledoc """
  Sign inputs for raw transaction (serialized, hex-encoded).

  The second optional argument (may be null) is an array of previous transaction
  outputs that this transaction depends on but may not yet be in the block chain.

  Requires wallet passphrase to be set with walletpassphrase call if wallet is
  encrypted.

  ## Schema fields (a.k.a "Arguments")

  - `:hexstring` - (required) The transaction hex string.

  - `:prevtxs` - (optional) Array of previous dependent transaction outputs.

  - `:sighashtype` - (optional) The signature hash type. Must be one of:
    "ALL", "NONE", "SINGLE", "ALL|ANYONECANPAY", "NONE|ANYONECANPAY",
    "SINGLE|ANYONECANPAY". Default: "ALL".

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `signrawtransactionwithwallet`][signrawtransactionwithwallet].
  [signrawtransactionwithwallet]: https://developer.bitcoin.org/reference/rpc/signrawtransactionwithwallet.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import BTx.Helpers, only: [trim_trailing_nil: 1]
  import Ecto.Changeset

  alias BTx.RPC.RawTransactions.RawTransaction.PrevTx
  alias BTx.RPC.Request

  ## Constants

  @method "signrawtransactionwithwallet"

  # Valid signature hash types
  @valid_sighash_types ~w(ALL NONE SINGLE ALL|ANYONECANPAY NONE|ANYONECANPAY SINGLE|ANYONECANPAY)

  ## Types & Schema

  @typedoc "SignRawTransactionWithWallet request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          hexstring: String.t() | nil,
          prevtxs: [PrevTx.t()] | nil,
          sighashtype: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: @method

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :hexstring, :string
    embeds_many :prevtxs, PrevTx
    field :sighashtype, :string, default: "ALL"
  end

  @required_fields ~w(hexstring)a
  @optional_fields ~w(sighashtype wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          wallet_name: wallet_name,
          hexstring: hexstring,
          prevtxs: prevtxs,
          sighashtype: sighashtype
        }) do
      # Convert prevtxs to simple maps for JSON encoding
      prevtxs_params = if prevtxs, do: Enum.map(prevtxs, &PrevTx.to_map/1), else: nil

      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"
      params = [hexstring, prevtxs_params, sighashtype]

      Request.new(
        method: method,
        path: path,
        params: trim_trailing_nil(params)
      )
    end
  end

  ## API

  @doc """
  Creates a new `SignRawTransactionWithWallet` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:signrawtransactionwithwallet)
  end

  @doc """
  Creates a new `SignRawTransactionWithWallet` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:signrawtransactionwithwallet)
  end

  @doc """
  Creates a changeset for the `SignRawTransactionWithWallet` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:prevtxs)
    |> validate_length(:hexstring, min: 1)
    |> validate_hexstring(:hexstring)
    |> validate_inclusion(:sighashtype, @valid_sighash_types)
    |> validate_wallet_name()
  end
end
