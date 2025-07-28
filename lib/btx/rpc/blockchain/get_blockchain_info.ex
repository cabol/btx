defmodule BTx.RPC.Blockchain.GetBlockchainInfo do
  @moduledoc """
  Returns an object containing various state info regarding blockchain processing.

  ## Schema fields (a.k.a "Arguments")

  This method takes no arguments.

  See [Bitcoin RPC API Reference `getblockchaininfo`][getblockchaininfo].
  [getblockchaininfo]: https://developer.bitcoin.org/reference/rpc/getblockchaininfo.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetBlockchainInfo request"
  @type t() :: %__MODULE__{
          method: String.t()
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getblockchaininfo"
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
  Creates a new `GetBlockchainInfo` request.
  """
  @spec new() :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new do
    %__MODULE__{}
    |> changeset(%{})
    |> apply_action(:getblockchaininfo)
  end

  @doc """
  Creates a new `GetBlockchainInfo` request.
  """
  @spec new!() :: t()
  def new! do
    %__MODULE__{}
    |> changeset(%{})
    |> apply_action!(:getblockchaininfo)
  end

  @doc """
  Creates a changeset for the `GetBlockchainInfo` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
  end
end
