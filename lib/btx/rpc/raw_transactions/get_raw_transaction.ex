defmodule BTx.RPC.RawTransactions.GetRawTransaction do
  @moduledoc """
  Return the raw transaction data.

  By default this function only works for mempool transactions. When called with
  a blockhash argument, getrawtransaction will return the transaction if the
  specified block is available and the transaction is found in that block.
  When called without a blockhash argument, `getrawtransaction` will return the
  transaction if it is in the mempool, or if `-txindex` is enabled and the
  transaction is in a block in the blockchain.

  If `verbose` is `true`, returns an Object with information about `txid`.
  If `verbose` is `false` or omitted, returns a string that is serialized,
  hex-encoded data for `txid`.

  ## Schema fields (a.k.a "Arguments")

  - `:txid` - (required) The transaction id.
  - `:verbose` - (optional) If `false`, return a string, otherwise return a
    json object. Default: `false`.
  - `:blockhash` - (optional) The block in which to look for the transaction.

  See [Bitcoin RPC API Reference `getrawtransaction`][getrawtransaction].
  [getrawtransaction]: https://developer.bitcoin.org/reference/rpc/getrawtransaction.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import BTx.Helpers, only: [trim_trailing_nil: 1]
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetRawTransaction request"
  @type t() :: %__MODULE__{
          method: String.t(),
          txid: String.t() | nil,
          verbose: boolean() | nil,
          blockhash: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getrawtransaction"

    # Method fields
    field :txid, :string
    field :verbose, :boolean, default: false
    field :blockhash, :string
  end

  @required_fields ~w(txid)a
  @optional_fields ~w(verbose blockhash)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          txid: txid,
          verbose: verbose,
          blockhash: blockhash
        }) do
      Request.new(
        method: method,
        path: "/",
        params: trim_trailing_nil([txid, verbose, blockhash])
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetRawTransaction` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getrawtransaction)
  end

  @doc """
  Creates a new `GetRawTransaction` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getrawtransaction)
  end

  @doc """
  Creates a changeset for the `GetRawTransaction` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_txid()
    |> validate_hex64(:blockhash)
  end
end
