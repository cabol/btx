defmodule BTx.RPC.Wallets.ImportDescriptors do
  @moduledoc """
  Import descriptors. This will trigger a rescan of the blockchain based on the
  earliest timestamp of all descriptors being imported. Requires a new wallet
  backup.

  Note: This call can take over an hour to complete if using an early timestamp;
  during that time, other rpc calls may report that the imported keys, addresses
  or scripts exist but related transactions are still missing.

  ## Schema fields (a.k.a "Arguments")

  - `:requests` - (required) Array of descriptor import requests.

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `importdescriptors`][importdescriptors].
  [importdescriptors]: https://developer.bitcoin.org/reference/rpc/importdescriptors.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Request
  alias BTx.RPC.Wallets.ImportDescriptorRequest

  ## Constants

  @method "importdescriptors"

  ## Types & Schema

  @typedoc "ImportDescriptors request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          requests: [ImportDescriptorRequest.t()] | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: @method

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    embeds_many :requests, ImportDescriptorRequest
  end

  @required_fields ~w()a
  @optional_fields ~w(wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          wallet_name: wallet_name,
          requests: requests
        }) do
      # Convert requests to simple maps for JSON encoding
      requests_params = Enum.map(requests, &ImportDescriptorRequest.to_map/1)

      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: [requests_params]
      )
    end
  end

  ## API

  @doc """
  Creates a new `ImportDescriptors` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:importdescriptors)
  end

  @doc """
  Creates a new `ImportDescriptors` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:importdescriptors)
  end

  @doc """
  Creates a changeset for the `ImportDescriptors` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:requests, required: true)
    |> validate_length(:requests, min: 1, message: "at least one request is required")
    |> validate_wallet_name()
  end
end
