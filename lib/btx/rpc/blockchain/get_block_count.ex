defmodule BTx.RPC.Blockchain.GetBlockCount do
  @moduledoc """
  Returns the height of the most-work fully-validated chain.

  The genesis block has height 0.

  ## Schema fields (a.k.a "Arguments")

  This method takes no arguments.

  See [Bitcoin RPC API Reference `getblockcount`][getblockcount].
  [getblockcount]: https://developer.bitcoin.org/reference/rpc/getblockcount.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetBlockCount request"
  @type t() :: %__MODULE__{
          method: String.t()
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getblockcount"
  end

  @required_fields []
  @optional_fields []

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{method: method}) do
      Request.new(
        method: method,
        path: "/",
        params: []
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetBlockCount` request.
  """
  @spec new() :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new do
    %__MODULE__{}
    |> changeset(%{})
    |> apply_action(:getblockcount)
  end

  @doc """
  Creates a new `GetBlockCount` request.
  """
  @spec new!() :: t()
  def new! do
    %__MODULE__{}
    |> changeset(%{})
    |> apply_action!(:getblockcount)
  end

  @doc """
  Creates a changeset for the `GetBlockCount` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
  end
end
