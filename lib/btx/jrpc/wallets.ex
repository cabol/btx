defmodule BTx.JRPC.Wallets do
  @moduledoc """
  Wallet-related RPC calls.
  """

  alias BTx.JRPC
  alias BTx.JRPC.Wallets.{CreateWallet, GetNewAddress, GetTransaction}

  @typedoc "Params for wallet-related RPC calls"
  @type params() :: keyword() | %{optional(atom()) => any()}

  @typedoc "Response from wallet-related RPC calls"
  @type response() :: BTx.JRPC.rpc_response() | {:error, Ecto.Changeset.t()}

  ## API

  @doc """
  Creates and loads a new wallet.
  """
  @spec create_wallet(JRPC.client(), params(), keyword()) :: response()
  def create_wallet(client, params, opts \\ []) do
    with {:ok, request} <- CreateWallet.new(params) do
      JRPC.call(client, request, opts)
    end
  end

  @doc """
  Returns a new Bitcoin address for receiving payments.
  """
  @spec get_new_address(JRPC.client(), params(), keyword()) :: response()
  def get_new_address(client, params, opts \\ []) do
    with {:ok, request} <- GetNewAddress.new(params) do
      JRPC.call(client, request, opts)
    end
  end

  @doc """
  Get detailed information about in-wallet transaction `txid`.
  """
  @spec get_transaction(JRPC.client(), params(), keyword()) :: response()
  def get_transaction(client, params, opts \\ []) do
    with {:ok, request} <- GetTransaction.new(params) do
      JRPC.call(client, request, opts)
    end
  end
end
