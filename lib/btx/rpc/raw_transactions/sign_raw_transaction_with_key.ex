defmodule BTx.RPC.RawTransactions.SignRawTransactionWithKey do
  @moduledoc """
  Sign inputs for raw transaction (serialized, hex-encoded).

  The second argument is an array of base58-encoded private keys that will be
  the only keys used to sign the transaction.

  The third optional argument (may be null) is an array of previous transaction
  outputs that this transaction depends on but may not yet be in the block chain.

  ## Schema fields (a.k.a "Arguments")

  - `:hexstring` - (required) The transaction hex string.

  - `:privkeys` - (required) Array of base58-encoded private keys for signing.

  - `:prevtxs` - (optional) Array of previous dependent transaction outputs.

  - `:sighashtype` - (optional) The signature hash type. Must be one of:
    "ALL", "NONE", "SINGLE", "ALL|ANYONECANPAY", "NONE|ANYONECANPAY",
    "SINGLE|ANYONECANPAY". Default: "ALL".

  See [Bitcoin RPC API Reference `signrawtransactionwithkey`][signrawtransactionwithkey].
  [signrawtransactionwithkey]: https://developer.bitcoin.org/reference/rpc/signrawtransactionwithkey.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import BTx.Helpers, only: [trim_trailing_nil: 1]
  import Ecto.Changeset

  alias BTx.RPC.RawTransactions.RawTransaction.PrevTx
  alias BTx.RPC.Request

  ## Constants

  @method "signrawtransactionwithkey"

  # Valid signature hash types
  @valid_sighash_types ~w(ALL NONE SINGLE ALL|ANYONECANPAY NONE|ANYONECANPAY SINGLE|ANYONECANPAY)

  ## Types & Schema

  @typedoc "SignRawTransactionWithKey request"
  @type t() :: %__MODULE__{
          method: String.t(),
          hexstring: String.t() | nil,
          privkeys: [String.t()] | nil,
          prevtxs: [PrevTx.t()] | nil,
          sighashtype: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: @method

    # Method fields
    field :hexstring, :string
    field :privkeys, {:array, :string}
    embeds_many :prevtxs, PrevTx
    field :sighashtype, :string, default: "ALL"
  end

  @required_fields ~w(hexstring privkeys)a
  @optional_fields ~w(sighashtype)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          hexstring: hexstring,
          privkeys: privkeys,
          prevtxs: prevtxs,
          sighashtype: sighashtype
        }) do
      # Convert prevtxs to simple maps for JSON encoding
      prevtxs_params = Enum.map(prevtxs, &prevtx_to_map/1)

      params = [hexstring, privkeys, prevtxs_params, sighashtype]

      Request.new(
        method: method,
        path: "/",
        params: trim_trailing_nil(params)
      )
    end

    defp prevtx_to_map(%PrevTx{} = prevtx) do
      prevtx
      |> Map.take([:txid, :vout, :script_pub_key, :redeem_script, :witness_script, :amount])
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        case {key, value} do
          {:script_pub_key, val} when not is_nil(val) -> Map.put(acc, "scriptPubKey", val)
          {:redeem_script, val} when not is_nil(val) -> Map.put(acc, "redeemScript", val)
          {:witness_script, val} when not is_nil(val) -> Map.put(acc, "witnessScript", val)
          {key, val} -> Map.put(acc, to_string(key), val)
        end
      end)
      |> Map.filter(fn {_key, value} -> not is_nil(value) end)
    end
  end

  ## API

  @doc """
  Creates a new `SignRawTransactionWithKey` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:signrawtransactionwithkey)
  end

  @doc """
  Creates a new `SignRawTransactionWithKey` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:signrawtransactionwithkey)
  end

  @doc """
  Creates a changeset for the `SignRawTransactionWithKey` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:prevtxs)
    |> validate_length(:hexstring, min: 1)
    |> validate_hexstring(:hexstring)
    |> validate_length(:privkeys, min: 1)
    |> validate_privkeys()
    |> validate_inclusion(:sighashtype, @valid_sighash_types)
  end

  ## Private functions

  # Basic validation for base58-encoded private keys
  # This is a simple check - Bitcoin Core will do comprehensive validation
  defp validate_privkeys(changeset) do
    validate_change(changeset, :privkeys, fn :privkeys, privkeys ->
      if Enum.all?(privkeys, &valid_privkey?/1) do
        []
      else
        [privkeys: "contains invalid private keys"]
      end
    end)
  end
end
