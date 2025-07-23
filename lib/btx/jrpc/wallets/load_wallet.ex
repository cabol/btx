defmodule BTx.JRPC.Wallets.LoadWallet do
  @moduledoc """
  Loads a wallet from a wallet file or directory.

  Note that all wallet command-line options used when starting bitcoind will be
  applied to the new wallet (eg -rescan, etc).

  ## Schema fields (a.k.a "Arguments")

  - `:filename` - (required) The wallet directory or .dat file.

  - `:load_on_startup` - (optional) Save wallet name to persistent settings and
    load on startup. True to add wallet to startup list, false to remove, null
    to leave unchanged. Defaults to `nil`.

  See [Bitcoin RPC API Reference `loadwallet`][loadwallet].
  [loadwallet]: https://developer.bitcoin.org/reference/rpc/loadwallet.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Request

  ## Types & Schema

  @typedoc "LoadWallet request"
  @type t() :: %__MODULE__{
          method: String.t(),
          filename: String.t() | nil,
          load_on_startup: boolean() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "loadwallet"

    # Method fields
    field :filename, :string
    field :load_on_startup, Ecto.Enum, values: [true, false, nil], default: nil
  end

  @required_fields ~w(filename)a
  @optional_fields ~w(load_on_startup)a

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          filename: filename,
          load_on_startup: load_on_startup
        }) do
      Request.new(
        method: method,
        params: [filename, load_on_startup]
      )
    end
  end

  ## API

  @doc """
  Creates a new `LoadWallet` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:loadwallet)
  end

  @doc """
  Creates a new `LoadWallet` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:loadwallet)
  end

  @doc """
  Creates a changeset for the `LoadWallet` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:filename, min: 1, max: 255)
  end
end
