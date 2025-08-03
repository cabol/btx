defmodule BTx.RPC.RawTransactions.SendRawTransaction do
  @moduledoc """
  Submit a raw transaction (serialized, hex-encoded) to local node and network.

  Note that the transaction will be sent unconditionally to all peers, so using
  this for manual rebroadcast may degrade privacy by leaking the transaction's
  origin, as nodes will normally not rebroadcast non-wallet transactions already
  in their mempool.

  Also see createrawtransaction and signrawtransactionwithkey calls.

  ## Schema fields (a.k.a "Arguments")

  - `:hexstring` - (required) The hex string of the raw transaction.

  - `:maxfeerate` - (optional) Reject transactions whose fee rate is higher than
    the specified value, expressed in BTC/kB. Set to `0` to accept any fee rate.
    Default: `0.10`.

  See [Bitcoin RPC API Reference `sendrawtransaction`][sendrawtransaction].
  [sendrawtransaction]: https://developer.bitcoin.org/reference/rpc/sendrawtransaction.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import BTx.Helpers, only: [trim_trailing_nil: 1]
  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Constants

  @method "sendrawtransaction"

  ## Types & Schema

  @typedoc "SendRawTransaction request"
  @type t() :: %__MODULE__{
          method: String.t(),
          hexstring: String.t() | nil,
          maxfeerate: float() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: @method

    # Method fields
    field :hexstring, :string
    field :maxfeerate, :float, default: 0.10
  end

  @required_fields ~w(hexstring)a
  @optional_fields ~w(maxfeerate)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          hexstring: hexstring,
          maxfeerate: maxfeerate
        }) do
      params = [hexstring, maxfeerate]

      Request.new(
        method: method,
        path: "/",
        params: trim_trailing_nil(params)
      )
    end
  end

  ## API

  @doc """
  Creates a new `SendRawTransaction` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:sendrawtransaction)
  end

  @doc """
  Creates a new `SendRawTransaction` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:sendrawtransaction)
  end

  @doc """
  Creates a changeset for the `SendRawTransaction` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:hexstring, min: 1)
    |> validate_hexstring(:hexstring)
    |> validate_number(:maxfeerate, greater_than_or_equal_to: 0)
  end
end
