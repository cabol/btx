defmodule BTx.JRPC.Wallets.GetTransaction do
  @moduledoc """
  Get detailed information about in-wallet transaction `txid`.

  See [Bitcoin RPC API Reference `gettransaction`][gettransaction].
  [gettransaction]: https://developer.bitcoin.org/reference/rpc/gettransaction.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Request

  ## Types & Schema

  @typedoc "GetTransaction request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          txid: String.t() | nil,
          include_watchonly: boolean(),
          verbose: boolean()
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "gettransaction"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :txid, :string
    field :include_watchonly, :boolean, default: true
    field :verbose, :boolean, default: false
  end

  @required_fields ~w(txid)a
  @optional_fields ~w(include_watchonly verbose wallet_name)a

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          txid: txid,
          include_watchonly: include_watchonly,
          verbose: verbose,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        params: [txid, include_watchonly, verbose],
        path: path
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetTransaction` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:gettransaction)
  end

  @doc """
  Creates a new `GetTransaction` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:gettransaction)
  end

  @doc """
  Creates a changeset for the `GetTransaction` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:txid, is: 64)
    |> validate_length(:wallet_name, min: 1, max: 64)
  end
end
