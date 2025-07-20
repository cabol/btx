defmodule BTx.JRPC.Wallets do
  @moduledoc """
  High-level interface for Bitcoin Core wallet operations.

  This module provides convenient functions for common wallet operations like
  creating wallets, generating addresses, checking balances, and managing
  transactions. It wraps the lower-level `BTx.JRPC` functionality with
  wallet-specific conveniences.

  ## Wallet requests

  - `BTx.JRPC.Wallets.CreateWallet`
  - `BTx.JRPC.Wallets.GetNewAddress`
  - `BTx.JRPC.Wallets.GetTransaction`
  - **More coming soon**

  ## Wallet-specific RPC calls

  Bitcoin Core requires wallet-specific RPC calls to be made using the
  `/wallet/<wallet_name>` URI path, starting from v0.17.0+. However,
  wallet-specific RPC methods automatically build the correct path when their
  `:wallet_name` field is provided.

  > #### **Best Practice** {: .info}
  >
  > Always include the `:wallet_name` field or option for wallet-related RPCs
  > to avoid ambiguity and errors — even in single-wallet setups.
  """

  alias BTx.JRPC
  alias BTx.JRPC.Wallets.{CreateWallet, GetBalance, GetNewAddress, GetTransaction}

  @typedoc "Params for wallet-related RPC calls"
  @type params() :: keyword() | %{optional(atom()) => any()}

  @typedoc "Response from wallet-related RPC calls"
  @type response() :: BTx.JRPC.rpc_response() | {:error, Ecto.Changeset.t()}

  ## API

  @doc """
  Creates and loads a new wallet.

   ## Arguments

  - `client` - Same as `BTx.JRPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.JRPC.Wallets.CreateWallet` for more information about the
    available parameters.
  - `opts` - Same as `BTx.JRPC.call/3`.

  ## Options

  See `BTx.JRPC.call/3`.

  ## Examples

      # Create a new wallet
      iex> BTx.JRPC.Wallets.create_wallet(client,
      ...>   name: "my_wallet",
      ...>   passphrase: "my_passphrase"
      ...> )
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: %{"name" => "my_wallet"},
        status: :ok
      }}

      # Create a new wallet with a custom path
      iex> BTx.JRPC.Wallets.create_wallet(client,
      ...>   name: "my_wallet",
      ...>   passphrase: "my_passphrase",
      ...>   path: "/custom/path"
      ...> )
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: %{"name" => "my_wallet"},
        status: :ok
      }}

      # Create a new wallet with a custom path and custom options
      iex> BTx.JRPC.Wallets.create_wallet(client,
      ...>   name: "my_wallet",
      ...>   passphrase: "my_passphrase",
      ...>   path: "/custom/path",
      ...>   options: [
      ...>     "descriptors": true,
      ...>     "rescan": true
      ...>   ]
      ...> )
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: %{"name" => "my_wallet"},
        status: :ok
      }}

  """
  @spec create_wallet(JRPC.client(), params(), keyword()) :: response()
  def create_wallet(client, params, opts \\ []) do
    with {:ok, request} <- CreateWallet.new(params) do
      JRPC.call(client, request, opts)
    end
  end

  @doc """
  Same as `create_wallet/3` but raises on error.
  """
  @spec create_wallet!(JRPC.client(), params(), keyword()) :: BTx.JRPC.Response.t()
  def create_wallet!(client, params, opts \\ []) do
    JRPC.call!(client, CreateWallet.new!(params), opts)
  end

  @doc """
  Returns a new Bitcoin address for receiving payments.

  ## Arguments

  - `client` - Same as `BTx.JRPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.JRPC.Wallets.GetNewAddress` for more information about the
    available parameters.
  - `opts` - Same as `BTx.JRPC.call/3`.

  ## Options

  See `BTx.JRPC.call/3`.

  ## Examples

      # Get a new address
      iex> BTx.JRPC.Wallets.get_new_address(client, wallet_name: "my_wallet")
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: %"bc1q...",
        status: :ok
      }}

      # Get a new address with a custom label
      iex> BTx.JRPC.Wallets.get_new_address(client,
      ...>   wallet_name: "my_wallet",
      ...>   label: "Customer Payment"
      ...> )
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: "bc1q...",
        status: :ok
      }}

  """
  @spec get_new_address(JRPC.client(), params(), keyword()) :: response()
  def get_new_address(client, params, opts \\ []) do
    with {:ok, request} <- GetNewAddress.new(params) do
      JRPC.call(client, request, opts)
    end
  end

  @doc """
  Same as `get_new_address/3` but raises on error.
  """
  @spec get_new_address!(JRPC.client(), params(), keyword()) :: BTx.JRPC.Response.t()
  def get_new_address!(client, params, opts \\ []) do
    JRPC.call!(client, GetNewAddress.new!(params), opts)
  end

  @doc """
  Get detailed information about in-wallet transaction `txid`.

  ## Arguments

  - `client` - Same as `BTx.JRPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.JRPC.Wallets.GetTransaction` for more information about the
    available parameters.
  - `opts` - Same as `BTx.JRPC.call/3`.

  ## Options

  See `BTx.JRPC.call/3`.

  ## Examples

      # Get transaction information
      iex> BTx.JRPC.Wallets.get_transaction(client, txid: "txid")
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: %{"txid" => "txid", ...},
        status: :ok
      }}

      # Get transaction information with verbose option
      iex> BTx.JRPC.Wallets.get_transaction(client, txid: "txid", verbose: true)
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: %{"txid" => "txid", ...},
        status: :ok
      }}

      # Get transaction information with watch-only option
      iex> BTx.JRPC.Wallets.get_transaction(client,
      ...>   txid: "txid",
      ...>   include_watchonly: false
      ...> )
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: %{"txid" => "txid", ...},
        status: :ok
      }}

      # Get transaction information with wallet-specific RPC call
      iex> BTx.JRPC.Wallets.get_transaction(client,
      ...>   txid: "txid",
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: %{"txid" => "txid", ...},
        status: :ok
      }}

  """
  @spec get_transaction(JRPC.client(), params(), keyword()) :: response()
  def get_transaction(client, params, opts \\ []) do
    with {:ok, request} <- GetTransaction.new(params) do
      JRPC.call(client, request, opts)
    end
  end

  @doc """
  Same as `get_transaction/3` but raises on error.
  """
  @spec get_transaction!(JRPC.client(), params(), keyword()) :: BTx.JRPC.Response.t()
  def get_transaction!(client, params, opts \\ []) do
    JRPC.call!(client, GetTransaction.new!(params), opts)
  end

  @doc """
  Returns the total available balance.

  ## Arguments

  - `client` - Same as `BTx.JRPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.JRPC.Wallets.GetBalance` for more information about the
    available parameters.
  - `opts` - Same as `BTx.JRPC.call/3`.

  ## Options

  See `BTx.JRPC.call/3`.

  ## Examples

      # Get balance with default parameters
      iex> BTx.JRPC.Wallets.get_balance(client, wallet_name: "my_wallet")
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: 1.50000000,
        status: :ok
      }}

      # Get balance with minimum confirmations
      iex> BTx.JRPC.Wallets.get_balance(client,
      ...>   wallet_name: "my_wallet",
      ...>   minconf: 6
      ...> )
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: 1.25000000,
        status: :ok
      }}

      # Get balance excluding watch-only addresses
      iex> BTx.JRPC.Wallets.get_balance(client,
      ...>   wallet_name: "my_wallet",
      ...>   include_watchonly: false
      ...> )
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: 1.00000000,
        status: :ok
      }}

      # Get balance excluding dirty outputs (avoid reuse)
      iex> BTx.JRPC.Wallets.get_balance(client,
      ...>   wallet_name: "my_wallet",
      ...>   avoid_reuse: true
      ...> )
      {:ok, %BTx.JRPC.Response{
        id: 1,
        result: 0.75000000,
        status: :ok
      }}

  """
  @spec get_balance(JRPC.client(), params(), keyword()) :: response()
  def get_balance(client, params \\ %{}, opts \\ []) do
    with {:ok, request} <- GetBalance.new(params) do
      JRPC.call(client, request, opts)
    end
  end

  @doc """
  Same as `get_balance/3` but raises on error.
  """
  @spec get_balance!(JRPC.client(), params(), keyword()) :: BTx.JRPC.Response.t()
  def get_balance!(client, params \\ %{}, opts \\ []) do
    JRPC.call!(client, GetBalance.new!(params), opts)
  end
end
