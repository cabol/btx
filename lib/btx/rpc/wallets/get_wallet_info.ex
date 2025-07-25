defmodule BTx.RPC.Wallets.GetWalletInfo do
  @moduledoc """
  Returns an object containing various wallet state info.

  ## Schema fields (a.k.a "Arguments")

  This method takes no parameters.

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.RPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `getwalletinfo`][getwalletinfo].
  [getwalletinfo]: https://developer.bitcoin.org/reference/rpc/getwalletinfo.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Types & Schema

  @typedoc "GetWalletInfo request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "getwalletinfo"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string
  end

  @optional_fields ~w(wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: []
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetWalletInfo` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getwalletinfo)
  end

  @doc """
  Creates a new `GetWalletInfo` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getwalletinfo)
  end

  @doc """
  Creates a changeset for the `GetWalletInfo` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @optional_fields)
    |> validate_length(:wallet_name, min: 1, max: 64)
  end
end
