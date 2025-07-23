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
  - `BTx.JRPC.Wallets.SendToAddress`
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
  alias BTx.JRPC.Response

  alias BTx.JRPC.Wallets.{
    CreateWallet,
    CreateWalletResult,
    GetBalance,
    GetNewAddress,
    GetTransaction,
    GetTransactionResult,
    ListWallets,
    SendToAddress,
    SendToAddressResult,
    UnloadWallet,
    UnloadWalletResult
  }

  @typedoc "Params for wallet-related RPC calls"
  @type params() :: keyword() | %{optional(atom()) => any()}

  @typedoc "Response from wallet-related RPC calls"
  @type response() :: JRPC.rpc_response() | {:error, Ecto.Changeset.t()}

  @typedoc "Response from wallet-related RPC calls"
  @type response(t) :: {:ok, t} | {:error, Ecto.Changeset.t()} | JRPC.rpc_error()

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
      {:ok, %BTx.JRPC.Wallets.CreateWalletResult{
        name: "my_wallet",
        warning: nil
      }}

      # Create a new wallet with a custom path
      iex> BTx.JRPC.Wallets.create_wallet(client,
      ...>   name: "my_wallet",
      ...>   passphrase: "my_passphrase",
      ...>   path: "/custom/path"
      ...> )
      {:ok, %BTx.JRPC.Wallets.CreateWalletResult{
        name: "my_wallet",
        warning: nil
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
      {:ok, %BTx.JRPC.Wallets.CreateWalletResult{
        name: "my_wallet",
        warning: nil
      }}

  """
  @spec create_wallet(JRPC.client(), params(), keyword()) :: response(CreateWalletResult.t())
  def create_wallet(client, params, opts \\ []) do
    with {:ok, request} <- CreateWallet.new(params),
         {:ok, %Response{result: result}} <- JRPC.call(client, request, opts) do
      CreateWalletResult.new(result)
    end
  end

  @doc """
  Same as `create_wallet/3` but raises on error.
  """
  @spec create_wallet!(JRPC.client(), params(), keyword()) :: CreateWalletResult.t()
  def create_wallet!(client, params, opts \\ []) do
    client
    |> JRPC.call!(CreateWallet.new!(params), opts)
    |> Map.fetch!(:result)
    |> CreateWalletResult.new!()
  end

  @doc """
  Unloads the wallet referenced by the request endpoint or unloads the wallet
  specified in the argument.

  ## Arguments

  - `client` - Same as `BTx.JRPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.JRPC.Wallets.UnloadWallet` for more information about the
    available parameters.
  - `opts` - Same as `BTx.JRPC.call/3`.

  ## Options

  See `BTx.JRPC.call/3`.

  ## Examples

      # Unload wallet by name (parameter approach)
      iex> BTx.JRPC.Wallets.unload_wallet(client,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.JRPC.Wallets.UnloadWalletResult{
        warning: nil
      }}

      # Unload wallet via endpoint (endpoint approach)
      iex> BTx.JRPC.Wallets.unload_wallet(client,
      ...>   endpoint_wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.JRPC.Wallets.UnloadWalletResult{
        warning: nil
      }}

      # Unload wallet and remove from startup list
      iex> BTx.JRPC.Wallets.unload_wallet(client,
      ...>   wallet_name: "my_wallet",
      ...>   load_on_startup: false
      ...> )
      {:ok, %BTx.JRPC.Wallets.UnloadWalletResult{
        warning: nil
      }}

      # Unload wallet with warning
      iex> BTx.JRPC.Wallets.unload_wallet(client,
      ...>   endpoint_wallet_name: "problematic_wallet"
      ...> )
      {:ok, %BTx.JRPC.Wallets.UnloadWalletResult{
        warning: "Wallet was not unloaded cleanly"
      }}

  """
  @spec unload_wallet(JRPC.client(), params(), keyword()) :: response(UnloadWalletResult.t())
  def unload_wallet(client, params, opts \\ []) do
    with {:ok, request} <- UnloadWallet.new(params),
         {:ok, %Response{result: result}} <- JRPC.call(client, request, opts) do
      UnloadWalletResult.new(result)
    end
  end

  @doc """
  Same as `unload_wallet/3` but raises on error.
  """
  @spec unload_wallet!(JRPC.client(), params(), keyword()) :: UnloadWalletResult.t()
  def unload_wallet!(client, params, opts \\ []) do
    client
    |> JRPC.call!(UnloadWallet.new!(params), opts)
    |> Map.fetch!(:result)
    |> UnloadWalletResult.new!()
  end

  @doc """
  Returns a list of currently loaded wallets.

  For full information on the wallet, use "getwalletinfo".

  ## Arguments

  - `client` - Same as `BTx.JRPC.call/3`.
  - `opts` - Same as `BTx.JRPC.call/3`.

  ## Options

  See `BTx.JRPC.call/3`.

  ## Examples

      # List all currently loaded wallets
      iex> BTx.JRPC.Wallets.list_wallets(client)
      {:ok, ["wallet1", "wallet2", "my_test_wallet"]}

      # When no wallets are loaded
      iex> BTx.JRPC.Wallets.list_wallets(client)
      {:ok, []}

      # List wallets with custom request ID
      iex> BTx.JRPC.Wallets.list_wallets(client, id: "list-wallets-001")
      {:ok, ["main_wallet"]}

  """
  @spec list_wallets(JRPC.client(), keyword()) :: response([String.t()])
  def list_wallets(client, opts \\ []) do
    with {:ok, request} <- ListWallets.new(),
         {:ok, %Response{result: result}} <- JRPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `list_wallets/2` but raises on error.
  """
  @spec list_wallets!(JRPC.client(), keyword()) :: [String.t()]
  def list_wallets!(client, opts \\ []) do
    client
    |> JRPC.call!(ListWallets.new!(), opts)
    |> Map.fetch!(:result)
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
      {:ok, "bc1q..."}

      # Get a new address with a custom label
      iex> BTx.JRPC.Wallets.get_new_address(client,
      ...>   wallet_name: "my_wallet",
      ...>   label: "Customer Payment"
      ...> )
      {:ok, "bc1q..."}

  """
  @spec get_new_address(JRPC.client(), params(), keyword()) :: response(String.t())
  def get_new_address(client, params, opts \\ []) do
    with {:ok, request} <- GetNewAddress.new(params),
         {:ok, %Response{result: result}} <- JRPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `get_new_address/3` but raises on error.
  """
  @spec get_new_address!(JRPC.client(), params(), keyword()) :: String.t()
  def get_new_address!(client, params, opts \\ []) do
    client
    |> JRPC.call!(GetNewAddress.new!(params), opts)
    |> Map.fetch!(:result)
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
      {:ok, 1.50000000}

      # Get balance with minimum confirmations
      iex> BTx.JRPC.Wallets.get_balance(client,
      ...>   wallet_name: "my_wallet",
      ...>   minconf: 6
      ...> )
      {:ok, 1.25000000}

      # Get balance excluding watch-only addresses
      iex> BTx.JRPC.Wallets.get_balance(client,
      ...>   wallet_name: "my_wallet",
      ...>   include_watchonly: false
      ...> )
      {:ok, 1.00000000}

      # Get balance excluding dirty outputs (avoid reuse)
      iex> BTx.JRPC.Wallets.get_balance(client,
      ...>   wallet_name: "my_wallet",
      ...>   avoid_reuse: true
      ...> )
      {:ok, 0.75000000}

  """
  @spec get_balance(JRPC.client(), params(), keyword()) :: response(number())
  def get_balance(client, params \\ %{}, opts \\ []) do
    with {:ok, request} <- GetBalance.new(params),
         {:ok, %Response{result: result}} <- JRPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `get_balance/3` but raises on error.
  """
  @spec get_balance!(JRPC.client(), params(), keyword()) :: number()
  def get_balance!(client, params \\ %{}, opts \\ []) do
    client
    |> JRPC.call!(GetBalance.new!(params), opts)
    |> Map.fetch!(:result)
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
      {:ok, %BTx.JRPC.Wallets.GetTransactionResult{
        txid: "txid",
        amount: 0.05000000,
        confirmations: 6,
        ...
      }}

      # Get transaction information with verbose option
      iex> BTx.JRPC.Wallets.get_transaction(client, txid: "txid", verbose: true)
      {:ok, %BTx.JRPC.Wallets.GetTransactionResult{
        txid: "txid",
        amount: 0.05000000,
        decoded: %{"txid" => "txid", "version" => 2, ...},
        ...
      }}

      # Get transaction information with wallet-specific RPC call
      iex> BTx.JRPC.Wallets.get_transaction(client,
      ...>   txid: "txid",
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.JRPC.Wallets.GetTransactionResult{...}}

  """
  @spec get_transaction(JRPC.client(), params(), keyword()) :: response(GetTransactionResult.t())
  def get_transaction(client, params, opts \\ []) do
    with {:ok, request} <- GetTransaction.new(params),
         {:ok, %Response{result: result}} <- JRPC.call(client, request, opts) do
      GetTransactionResult.new(result)
    end
  end

  @doc """
  Same as `get_transaction/3` but raises on error.
  """
  @spec get_transaction!(JRPC.client(), params(), keyword()) :: GetTransactionResult.t()
  def get_transaction!(client, params, opts \\ []) do
    client
    |> JRPC.call!(GetTransaction.new!(params), opts)
    |> Map.fetch!(:result)
    |> GetTransactionResult.new!()
  end

  @doc """
  Send an amount to a given address.

  Requires wallet passphrase to be set with walletpassphrase call if wallet is
  encrypted.

  ## Arguments

  - `client` - Same as `BTx.JRPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.JRPC.Wallets.SendToAddress` for more information about the
    available parameters.
  - `opts` - Same as `BTx.JRPC.call/3`.

  ## Options

  See `BTx.JRPC.call/3`.

  ## Examples

      # Send 0.1 BTC to an address
      iex> BTx.JRPC.Wallets.send_to_address(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      ...>   amount: 0.1,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.JRPC.Wallets.SendToAddressResult{
        txid: "1234567890abcdef...",
        fee_reason: nil
      }}

      # Send with comment and fee deduction
      iex> BTx.JRPC.Wallets.send_to_address(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      ...>   amount: 0.05,
      ...>   comment: "Payment for services",
      ...>   comment_to: "Alice",
      ...>   subtractfeefromamount: true,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.JRPC.Wallets.SendToAddressResult{...}}

      # Send with verbose output for fee details
      iex> BTx.JRPC.Wallets.send_to_address(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      ...>   amount: 0.2,
      ...>   verbose: true,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.JRPC.Wallets.SendToAddressResult{
        txid: "1234567890abcdef...",
        fee_reason: "Fallback fee"
      }}

  """
  @spec send_to_address(JRPC.client(), params(), keyword()) :: response(SendToAddressResult.t())
  def send_to_address(client, params, opts \\ []) do
    with {:ok, request} <- SendToAddress.new(params),
         {:ok, %Response{result: result}} <- JRPC.call(client, request, opts) do
      SendToAddressResult.new(result)
    end
  end

  @doc """
  Same as `send_to_address/3` but raises on error.
  """
  @spec send_to_address!(JRPC.client(), params(), keyword()) :: SendToAddressResult.t()
  def send_to_address!(client, params, opts \\ []) do
    client
    |> JRPC.call!(SendToAddress.new!(params), opts)
    |> Map.fetch!(:result)
    |> SendToAddressResult.new!()
  end
end
