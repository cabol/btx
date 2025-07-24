defmodule BTx.JRPC.Blockchain.GetMempoolEntry do
  @moduledoc """
  Returns mempool data for given transaction.

  ## Schema fields (a.k.a "Arguments")

  - `:txid` - (required) The transaction id (must be in mempool).

  See [Bitcoin RPC API Reference `getmempoolentry`][getmempoolentry].
  [getmempoolentry]: https://developer.bitcoin.org/reference/rpc/getmempoolentry.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Request

  ## Types & Schema

  @typedoc "GetMempoolEntry request"
  @type t() :: %__MODULE__{
          method: String.t(),
          txid: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getmempoolentry"

    # Method fields
    field :txid, :string
  end

  @required_fields ~w(txid)a

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          txid: txid
        }) do
      Request.new(
        method: method,
        params: [txid]
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetMempoolEntry` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getmempoolentry)
  end

  @doc """
  Creates a new `GetMempoolEntry` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getmempoolentry)
  end

  @doc """
  Creates a changeset for the `GetMempoolEntry` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:txid, is: 64)
    |> validate_format(:txid, ~r/^[a-fA-F0-9]{64}$/)
  end
end
