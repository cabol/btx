defmodule BTx.RPC.Wallets do
  @moduledoc """
  High-level interface for Bitcoin Core wallet operations.

  This module provides convenient functions for common wallet operations like
  creating wallets, generating addresses, checking balances, and managing
  transactions. It wraps the lower-level `BTx.RPC` functionality with
  wallet-specific conveniences.

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

  alias BTx.RPC
  alias BTx.RPC.Response

  alias BTx.RPC.Wallets.{
    CreateWallet,
    CreateWalletResult,
    GetAddressesByLabel,
    GetAddressInfo,
    GetAddressInfoResult,
    GetBalance,
    GetNewAddress,
    GetReceivedByAddress,
    GetTransaction,
    GetTransactionResult,
    GetWalletInfo,
    GetWalletInfoResult,
    ListTransactions,
    ListTransactionsItem,
    ListUnspent,
    ListUnspentItem,
    ListWallets,
    LoadWallet,
    LoadWalletResult,
    SendToAddress,
    SendToAddressResult,
    SignRawTransactionWithWallet,
    SignRawTransactionWithWalletResult,
    UnloadWallet,
    UnloadWalletResult,
    WalletLock,
    WalletPassphrase
  }

  @typedoc "Params for wallet-related RPC calls"
  @type params() :: keyword() | %{optional(atom()) => any()}

  @typedoc "Response from wallet-related RPC calls"
  @type response() :: RPC.rpc_response() | {:error, Ecto.Changeset.t()}

  @typedoc "Response from wallet-related RPC calls"
  @type response(t) :: {:ok, t} | {:error, Ecto.Changeset.t()} | RPC.rpc_error()

  ## Wallet & Key Management

  @doc """
  Creates and loads a new wallet.

   ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.CreateWallet` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Create a new wallet
      iex> BTx.RPC.Wallets.create_wallet(client,
      ...>   name: "my_wallet",
      ...>   passphrase: "my_passphrase"
      ...> )
      {:ok, %BTx.RPC.Wallets.CreateWalletResult{
        name: "my_wallet",
        warning: nil
      }}

      # Create a new wallet with a custom path
      iex> BTx.RPC.Wallets.create_wallet(client,
      ...>   name: "my_wallet",
      ...>   passphrase: "my_passphrase",
      ...>   path: "/custom/path"
      ...> )
      {:ok, %BTx.RPC.Wallets.CreateWalletResult{
        name: "my_wallet",
        warning: nil
      }}

      # Create a new wallet with a custom path and custom options
      iex> BTx.RPC.Wallets.create_wallet(client,
      ...>   name: "my_wallet",
      ...>   passphrase: "my_passphrase",
      ...>   path: "/custom/path",
      ...>   options: [
      ...>     "descriptors": true,
      ...>     "rescan": true
      ...>   ]
      ...> )
      {:ok, %BTx.RPC.Wallets.CreateWalletResult{
        name: "my_wallet",
        warning: nil
      }}

  """
  @spec create_wallet(RPC.client(), params(), keyword()) :: response(CreateWalletResult.t())
  def create_wallet(client, params, opts \\ []) do
    with {:ok, request} <- CreateWallet.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      CreateWalletResult.new(result)
    end
  end

  @doc """
  Same as `create_wallet/3` but raises on error.
  """
  @spec create_wallet!(RPC.client(), params(), keyword()) :: CreateWalletResult.t()
  def create_wallet!(client, params, opts \\ []) do
    client
    |> RPC.call!(CreateWallet.new!(params), opts)
    |> Map.fetch!(:result)
    |> CreateWalletResult.new!()
  end

  @doc """
  Loads a wallet from a wallet file or directory.

  Note that all wallet command-line options used when starting bitcoind will be
  applied to the new wallet (eg -rescan, etc).

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.LoadWallet` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Load a wallet from file
      iex> BTx.RPC.Wallets.load_wallet(client,
      ...>   filename: "test.dat"
      ...> )
      {:ok, %BTx.RPC.Wallets.LoadWalletResult{
        name: "test",
        warning: nil
      }}

      # Load a wallet from directory
      iex> BTx.RPC.Wallets.load_wallet(client,
      ...>   filename: "wallet_directory"
      ...> )
      {:ok, %BTx.RPC.Wallets.LoadWalletResult{
        name: "wallet_directory",
        warning: nil
      }}

      # Load wallet and add to startup list
      iex> BTx.RPC.Wallets.load_wallet(client,
      ...>   filename: "production.dat",
      ...>   load_on_startup: true
      ...> )
      {:ok, %BTx.RPC.Wallets.LoadWalletResult{
        name: "production",
        warning: nil
      }}

      # Load wallet with warning
      iex> BTx.RPC.Wallets.load_wallet(client,
      ...>   filename: "old_wallet.dat"
      ...> )
      {:ok, %BTx.RPC.Wallets.LoadWalletResult{
        name: "old_wallet",
        warning: "Wallet was not loaded cleanly"
      }}

  """
  @spec load_wallet(RPC.client(), params(), keyword()) :: response(LoadWalletResult.t())
  def load_wallet(client, params, opts \\ []) do
    with {:ok, request} <- LoadWallet.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      LoadWalletResult.new(result)
    end
  end

  @doc """
  Same as `load_wallet/3` but raises on error.
  """
  @spec load_wallet!(RPC.client(), params(), keyword()) :: LoadWalletResult.t()
  def load_wallet!(client, params, opts \\ []) do
    client
    |> RPC.call!(LoadWallet.new!(params), opts)
    |> Map.fetch!(:result)
    |> LoadWalletResult.new!()
  end

  @doc """
  Unloads the wallet referenced by the request endpoint or unloads the wallet
  specified in the argument.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.UnloadWallet` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Unload wallet by name (parameter approach)
      iex> BTx.RPC.Wallets.unload_wallet(client,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.UnloadWalletResult{
        warning: nil
      }}

      # Unload wallet via endpoint (endpoint approach)
      iex> BTx.RPC.Wallets.unload_wallet(client,
      ...>   endpoint_wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.UnloadWalletResult{
        warning: nil
      }}

      # Unload wallet and remove from startup list
      iex> BTx.RPC.Wallets.unload_wallet(client,
      ...>   wallet_name: "my_wallet",
      ...>   load_on_startup: false
      ...> )
      {:ok, %BTx.RPC.Wallets.UnloadWalletResult{
        warning: nil
      }}

      # Unload wallet with warning
      iex> BTx.RPC.Wallets.unload_wallet(client,
      ...>   endpoint_wallet_name: "problematic_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.UnloadWalletResult{
        warning: "Wallet was not unloaded cleanly"
      }}

  """
  @spec unload_wallet(RPC.client(), params(), keyword()) :: response(UnloadWalletResult.t())
  def unload_wallet(client, params, opts \\ []) do
    with {:ok, request} <- UnloadWallet.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      UnloadWalletResult.new(result)
    end
  end

  @doc """
  Same as `unload_wallet/3` but raises on error.
  """
  @spec unload_wallet!(RPC.client(), params(), keyword()) :: UnloadWalletResult.t()
  def unload_wallet!(client, params, opts \\ []) do
    client
    |> RPC.call!(UnloadWallet.new!(params), opts)
    |> Map.fetch!(:result)
    |> UnloadWalletResult.new!()
  end

  @doc """
  Returns a list of currently loaded wallets.

  For full information on the wallet, use "getwalletinfo".

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # List all currently loaded wallets
      iex> BTx.RPC.Wallets.list_wallets(client)
      {:ok, ["wallet1", "wallet2", "my_test_wallet"]}

      # When no wallets are loaded
      iex> BTx.RPC.Wallets.list_wallets(client)
      {:ok, []}

      # List wallets with custom request ID
      iex> BTx.RPC.Wallets.list_wallets(client, id: "list-wallets-001")
      {:ok, ["main_wallet"]}

  """
  @spec list_wallets(RPC.client(), keyword()) :: response([String.t()])
  def list_wallets(client, opts \\ []) do
    with {:ok, request} <- ListWallets.new(),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `list_wallets/2` but raises on error.
  """
  @spec list_wallets!(RPC.client(), keyword()) :: [String.t()]
  def list_wallets!(client, opts \\ []) do
    client
    |> RPC.call!(ListWallets.new!(), opts)
    |> Map.fetch!(:result)
  end

  @doc """
  Returns an object containing various wallet state info.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.GetWalletInfo` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get wallet info for default wallet
      iex> BTx.RPC.Wallets.get_wallet_info(client)
      {:ok, %BTx.RPC.Wallets.GetWalletInfoResult{
        walletname: "default",
        walletversion: 169900,
        format: "sqlite",
        balance: 1.5,
        txcount: 42,
        descriptors: true,
        ...
      }}

      # Get wallet info for specific wallet
      iex> BTx.RPC.Wallets.get_wallet_info(client,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.GetWalletInfoResult{
        walletname: "my_wallet",
        ...
      }}

      # Check if wallet is encrypted and locked
      iex> {:ok, info} = BTx.RPC.Wallets.get_wallet_info(client, wallet_name: "encrypted_wallet")
      iex> if info.unlocked_until && info.unlocked_until > 0 do
      ...>   IO.puts("Wallet is unlocked until \#{info.unlocked_until}")
      ...> else
      ...>   IO.puts("Wallet is locked")
      ...> end

  """
  @spec get_wallet_info(RPC.client(), params(), keyword()) :: response(GetWalletInfoResult.t())
  def get_wallet_info(client, params \\ %{}, opts \\ []) do
    with {:ok, request} <- GetWalletInfo.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      GetWalletInfoResult.new(result)
    end
  end

  @doc """
  Same as `get_wallet_info/3` but raises on error.
  """
  @spec get_wallet_info!(RPC.client(), params(), keyword()) :: GetWalletInfoResult.t()
  def get_wallet_info!(client, params \\ %{}, opts \\ []) do
    client
    |> RPC.call!(GetWalletInfo.new!(params), opts)
    |> Map.fetch!(:result)
    |> GetWalletInfoResult.new!()
  end

  @doc """
  Returns the total available balance.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.GetBalance` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get balance with default parameters
      iex> BTx.RPC.Wallets.get_balance(client, wallet_name: "my_wallet")
      {:ok, 1.50000000}

      # Get balance with minimum confirmations
      iex> BTx.RPC.Wallets.get_balance(client,
      ...>   wallet_name: "my_wallet",
      ...>   minconf: 6
      ...> )
      {:ok, 1.25000000}

      # Get balance excluding watch-only addresses
      iex> BTx.RPC.Wallets.get_balance(client,
      ...>   wallet_name: "my_wallet",
      ...>   include_watchonly: false
      ...> )
      {:ok, 1.00000000}

      # Get balance excluding dirty outputs (avoid reuse)
      iex> BTx.RPC.Wallets.get_balance(client,
      ...>   wallet_name: "my_wallet",
      ...>   avoid_reuse: true
      ...> )
      {:ok, 0.75000000}

  """
  @spec get_balance(RPC.client(), params(), keyword()) :: response(number())
  def get_balance(client, params \\ %{}, opts \\ []) do
    with {:ok, request} <- GetBalance.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `get_balance/3` but raises on error.
  """
  @spec get_balance!(RPC.client(), params(), keyword()) :: number()
  def get_balance!(client, params \\ %{}, opts \\ []) do
    client
    |> RPC.call!(GetBalance.new!(params), opts)
    |> Map.fetch!(:result)
  end

  @doc """
  Stores the wallet decryption key in memory for 'timeout' seconds.

  This is needed prior to performing transactions related to private keys such as
  sending bitcoins.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.WalletPassphrase` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Unlock wallet for 60 seconds
      iex> BTx.RPC.Wallets.wallet_passphrase(client,
      ...>   passphrase: "my_secure_passphrase",
      ...>   timeout: 60,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, nil}

      # Unlock for 5 minutes
      iex> BTx.RPC.Wallets.wallet_passphrase(client,
      ...>   passphrase: "my_secure_passphrase",
      ...>   timeout: 300,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, nil}

      # Unlock for maximum time (~3 years)
      iex> BTx.RPC.Wallets.wallet_passphrase(client,
      ...>   passphrase: "my_secure_passphrase",
      ...>   timeout: 100_000_000,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, nil}

      # Handle wallet already unlocked (resets timeout)
      iex> BTx.RPC.Wallets.wallet_passphrase(client,
      ...>   passphrase: "my_secure_passphrase",
      ...>   timeout: 120,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, nil}

  > #### `walletpassphrase` {: .info}
  >
  > Issuing the `walletpassphrase` command while the wallet is already unlocked
  > will set a new unlock time that overrides the old one.
  """
  @spec wallet_passphrase(RPC.client(), params(), keyword()) :: response(nil)
  def wallet_passphrase(client, params, opts \\ []) do
    with {:ok, request} <- WalletPassphrase.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `wallet_passphrase/3` but raises on error.
  """
  @spec wallet_passphrase!(RPC.client(), params(), keyword()) :: nil
  def wallet_passphrase!(client, params, opts \\ []) do
    client
    |> RPC.call!(WalletPassphrase.new!(params), opts)
    |> Map.fetch!(:result)
  end

  @doc """
  Removes the wallet encryption key from memory, locking the wallet.

  After calling this method, you will need to call walletpassphrase again
  before being able to call any methods which require the wallet to be unlocked.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.WalletLock` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Lock the default wallet
      iex> BTx.RPC.Wallets.wallet_lock(client)
      {:ok, nil}

      # Lock a specific wallet
      iex> BTx.RPC.Wallets.wallet_lock(client, wallet_name: "my_wallet")
      {:ok, nil}

      # Lock after performing transactions
      iex> BTx.RPC.Wallets.wallet_passphrase(client,
      ...>   passphrase: "my_secure_passphrase",
      ...>   timeout: 120
      ...> )
      {:ok, nil}

      iex> # ... perform transactions that require unlocked wallet ...

      iex> BTx.RPC.Wallets.wallet_lock(client)
      {:ok, nil}

  ## Notes

  This method is only applicable to encrypted wallets. If the wallet is not
  encrypted, this method will return an error.
  """
  @spec wallet_lock(RPC.client(), params(), keyword()) :: response(nil)
  def wallet_lock(client, params \\ [], opts \\ []) do
    with {:ok, request} <- WalletLock.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `wallet_lock/3` but raises on error.
  """
  @spec wallet_lock!(RPC.client(), params(), keyword()) :: nil
  def wallet_lock!(client, params \\ [], opts \\ []) do
    client
    |> RPC.call!(WalletLock.new!(params), opts)
    |> Map.fetch!(:result)
  end

  ## Address & Key Generation

  @doc """
  Returns a new Bitcoin address for receiving payments.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.GetNewAddress` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get a new address
      iex> BTx.RPC.Wallets.get_new_address(client, wallet_name: "my_wallet")
      {:ok, "bc1q..."}

      # Get a new address with a custom label
      iex> BTx.RPC.Wallets.get_new_address(client,
      ...>   wallet_name: "my_wallet",
      ...>   label: "Customer Payment"
      ...> )
      {:ok, "bc1q..."}

  """
  @spec get_new_address(RPC.client(), params(), keyword()) :: response(String.t())
  def get_new_address(client, params, opts \\ []) do
    with {:ok, request} <- GetNewAddress.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `get_new_address/3` but raises on error.
  """
  @spec get_new_address!(RPC.client(), params(), keyword()) :: String.t()
  def get_new_address!(client, params, opts \\ []) do
    client
    |> RPC.call!(GetNewAddress.new!(params), opts)
    |> Map.fetch!(:result)
  end

  @doc """
  Return information about the given bitcoin address.

  Some of the information will only be present if the address is in the active wallet.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.GetAddressInfo` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get address information
      iex> BTx.RPC.Wallets.get_address_info(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl"
      ...> )
      {:ok, %BTx.RPC.Wallets.GetAddressInfoResult{
        address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
        script_pub_key: "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
        ismine: true,
        iswatchonly: false,
        solvable: true,
        isscript: false,
        ischange: false,
        iswitness: true,
        witness_version: 0,
        witness_program: "389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
        labels: [""]
      }}

      # Get info for wallet-specific address
      iex> BTx.RPC.Wallets.get_address_info(client,
      ...>   address: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.GetAddressInfoResult{
        address: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
        ismine: false,
        iswatchonly: false,
        solvable: true,
        isscript: false,
        ischange: false,
        iswitness: false,
        labels: []
      }}

      # Get info for multisig address
      iex> BTx.RPC.Wallets.get_address_info(client,
      ...>   address: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
      ...> )
      {:ok, %BTx.RPC.Wallets.GetAddressInfoResult{
        address: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
        isscript: true,
        script: "multisig",
        sigsrequired: 2,
        pubkeys: ["03abc...", "03def..."],
        ...
      }}

  """
  @spec get_address_info(RPC.client(), params(), keyword()) :: response(GetAddressInfoResult.t())
  def get_address_info(client, params, opts \\ []) do
    with {:ok, request} <- GetAddressInfo.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      GetAddressInfoResult.new(result)
    end
  end

  @doc """
  Same as `get_address_info/3` but raises on error.
  """
  @spec get_address_info!(RPC.client(), params(), keyword()) :: GetAddressInfoResult.t()
  def get_address_info!(client, params, opts \\ []) do
    client
    |> RPC.call!(GetAddressInfo.new!(params), opts)
    |> Map.fetch!(:result)
    |> GetAddressInfoResult.new!()
  end

  @doc """
  Returns the list of addresses assigned the specified label.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.GetAddressesByLabel` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Result

  Returns a map where each key is a Bitcoin address (string) and each value
  is a map containing the address purpose information:

  ```elixir
  %{
    "bc1qxyz8a7zv50vvv4cnz0g44ux6a6q7gfqq0w0uhx" => %{"purpose" => "receive"},
    "bc1qkl4c9j8f8vy4h9kk9pr5n7frwx30r9kvppnnxz" => %{"purpose" => "receive"}
  }
  ```

  ## Examples

      # Get addresses for a specific label
      iex> BTx.RPC.Wallets.get_addresses_by_label(client, label: "tabby")
      {:ok, %{
        "bc1qxyz8a7zv50vvv4cnz0g44ux6a6q7gfqq0w0uhx" => %{"purpose" => "receive"},
        "bc1qkl4c9j8f8vy4h9kk9pr5n7frwx30r9kvppnnxz" => %{"purpose" => "receive"}
      }}

      # Get addresses from specific wallet
      iex> BTx.RPC.Wallets.get_addresses_by_label(client,
      ...>   label: "savings",
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %{
        "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2" => %{"purpose" => "send"},
        "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl" => %{"purpose" => "receive"}
      }}

      # Label with no addresses returns empty map
      iex> BTx.RPC.Wallets.get_addresses_by_label(client, label: "nonexistent")
      {:ok, %{}}

  """
  @spec get_addresses_by_label(RPC.client(), params(), keyword()) :: response(map())
  def get_addresses_by_label(client, params, opts \\ []) do
    with {:ok, request} <- GetAddressesByLabel.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `get_addresses_by_label/3` but raises on error.
  """
  @spec get_addresses_by_label!(RPC.client(), params(), keyword()) :: map()
  def get_addresses_by_label!(client, params, opts \\ []) do
    client
    |> RPC.call!(GetAddressesByLabel.new!(params), opts)
    |> Map.fetch!(:result)
  end

  ## Sending & Receiving Funds

  @doc """
  Returns the total amount received by the given address in transactions with
  at least minconf confirmations.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.GetReceivedByAddress` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get amount received by address with default confirmations
      iex> BTx.RPC.Wallets.get_received_by_address(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, 0.05000000}

      # Get amount including unconfirmed transactions (zero confirmations)
      iex> BTx.RPC.Wallets.get_received_by_address(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      ...>   minconf: 0,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, 0.15000000}

      # Get amount with at least 6 confirmations
      iex> BTx.RPC.Wallets.get_received_by_address(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      ...>   minconf: 6,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, 0.02500000}

      # Address that has received no payments
      iex> BTx.RPC.Wallets.get_received_by_address(client,
      ...>   address: "bc1qnew0dd3ess4ge4y5r3zarvary0c5xw7kv8f3t4",
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, 0.00000000}

  """
  @spec get_received_by_address(RPC.client(), params(), keyword()) :: response(number())
  def get_received_by_address(client, params, opts \\ []) do
    with {:ok, request} <- GetReceivedByAddress.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `get_received_by_address/3` but raises on error.
  """
  @spec get_received_by_address!(RPC.client(), params(), keyword()) :: number()
  def get_received_by_address!(client, params, opts \\ []) do
    client
    |> RPC.call!(GetReceivedByAddress.new!(params), opts)
    |> Map.fetch!(:result)
  end

  @doc """
  Send an amount to a given address.

  Requires wallet passphrase to be set with walletpassphrase call if wallet is
  encrypted.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.SendToAddress` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Send 0.1 BTC to an address
      iex> BTx.RPC.Wallets.send_to_address(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      ...>   amount: 0.1,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.SendToAddressResult{
        txid: "1234567890abcdef...",
        fee_reason: nil
      }}

      # Send with comment and fee deduction
      iex> BTx.RPC.Wallets.send_to_address(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      ...>   amount: 0.05,
      ...>   comment: "Payment for services",
      ...>   comment_to: "Alice",
      ...>   subtractfeefromamount: true,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.SendToAddressResult{...}}

      # Send with verbose output for fee details
      iex> BTx.RPC.Wallets.send_to_address(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      ...>   amount: 0.2,
      ...>   verbose: true,
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.SendToAddressResult{
        txid: "1234567890abcdef...",
        fee_reason: "Fallback fee"
      }}

  """
  @spec send_to_address(RPC.client(), params(), keyword()) :: response(SendToAddressResult.t())
  def send_to_address(client, params, opts \\ []) do
    with {:ok, request} <- SendToAddress.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      SendToAddressResult.new(result)
    end
  end

  @doc """
  Same as `send_to_address/3` but raises on error.
  """
  @spec send_to_address!(RPC.client(), params(), keyword()) :: SendToAddressResult.t()
  def send_to_address!(client, params, opts \\ []) do
    client
    |> RPC.call!(SendToAddress.new!(params), opts)
    |> Map.fetch!(:result)
    |> SendToAddressResult.new!()
  end

  ## Transactions

  @doc """
  Get detailed information about in-wallet transaction `txid`.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.GetTransaction` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get transaction information
      iex> BTx.RPC.Wallets.get_transaction(client, txid: "txid")
      {:ok, %BTx.RPC.Wallets.GetTransactionResult{
        txid: "txid",
        amount: 0.05000000,
        confirmations: 6,
        ...
      }}

      # Get transaction information with verbose option
      iex> BTx.RPC.Wallets.get_transaction(client, txid: "txid", verbose: true)
      {:ok, %BTx.RPC.Wallets.GetTransactionResult{
        txid: "txid",
        amount: 0.05000000,
        decoded: %{"txid" => "txid", "version" => 2, ...},
        ...
      }}

      # Get transaction information with wallet-specific RPC call
      iex> BTx.RPC.Wallets.get_transaction(client,
      ...>   txid: "txid",
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.GetTransactionResult{...}}

  """
  @spec get_transaction(RPC.client(), params(), keyword()) :: response(GetTransactionResult.t())
  def get_transaction(client, params, opts \\ []) do
    with {:ok, request} <- GetTransaction.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      GetTransactionResult.new(result)
    end
  end

  @doc """
  Same as `get_transaction/3` but raises on error.
  """
  @spec get_transaction!(RPC.client(), params(), keyword()) :: GetTransactionResult.t()
  def get_transaction!(client, params, opts \\ []) do
    client
    |> RPC.call!(GetTransaction.new!(params), opts)
    |> Map.fetch!(:result)
    |> GetTransactionResult.new!()
  end

  @doc """
  If a label name is provided, this will return only incoming transactions
  paying to addresses with the specified label.

  Returns up to 'count' most recent transactions skipping the first 'skip'
  transactions.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.ListTransactions` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # List the most recent 10 transactions
      iex> BTx.RPC.Wallets.list_transactions(client, wallet_name: "my_wallet")
      {:ok, [
        %BTx.RPC.Wallets.ListTransactionsItem{
          category: "receive",
          amount: 0.05,
          txid: "abc123...",
          confirmations: 6,
          ...
        },
        ...
      ]}

      # List transactions with specific label
      iex> BTx.RPC.Wallets.list_transactions(client,
      ...>   wallet_name: "my_wallet",
      ...>   label: "customer_payments"
      ...> )
      {:ok, [...]}

      # List transactions with pagination
      iex> BTx.RPC.Wallets.list_transactions(client,
      ...>   wallet_name: "my_wallet",
      ...>   count: 20,
      ...>   skip: 100
      ...> )
      {:ok, [...]}

      # List all transactions (disable filtering)
      iex> BTx.RPC.Wallets.list_transactions(client,
      ...>   wallet_name: "my_wallet",
      ...>   label: "*"
      ...> )
      {:ok, [...]}

  """
  @spec list_transactions(RPC.client(), params(), keyword()) ::
          response([ListTransactionsItem.t()])
  def list_transactions(client, params, opts \\ []) do
    with {:ok, request} <- ListTransactions.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      parse_transaction_list(result)
    end
  end

  @doc """
  Same as `list_transactions/3` but raises on error.
  """
  @spec list_transactions!(RPC.client(), params(), keyword()) :: [ListTransactionsItem.t()]
  def list_transactions!(client, params, opts \\ []) do
    client
    |> RPC.call!(ListTransactions.new!(params), opts)
    |> Map.fetch!(:result)
    |> parse_transaction_list!()
  end

  ## UTXO Control

  @doc """
  Returns array of unspent transaction outputs with between minconf and maxconf
  (inclusive) confirmations.

  Optionally filter to only include txouts paid to specified addresses.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.ListUnspent` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # List all unspent outputs
      iex> BTx.RPC.Wallets.list_unspent(client)
      {:ok, [
        %BTx.RPC.Wallets.ListUnspentItem{
          txid: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
          vout: 0,
          address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
          amount: 0.05000000,
          confirmations: 6,
          spendable: true,
          solvable: true,
          safe: true
        }
      ]}

      # List unspent outputs with at least 6 confirmations
      iex> BTx.RPC.Wallets.list_unspent(client, minconf: 6)
      {:ok, [%BTx.RPC.Wallets.ListUnspentItem{...}]}

      # List unspent outputs for specific addresses
      iex> BTx.RPC.Wallets.list_unspent(client,
      ...>   addresses: ["bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl"]
      ...> )
      {:ok, [%BTx.RPC.Wallets.ListUnspentItem{...}]}

      # List with amount filtering
      iex> BTx.RPC.Wallets.list_unspent(client,
      ...>   query_options: %{
      ...>     minimum_amount: 0.001,
      ...>     maximum_amount: 1.0,
      ...>     maximum_count: 50
      ...>   }
      ...> )
      {:ok, [%BTx.RPC.Wallets.ListUnspentItem{...}]}

      # List from specific wallet
      iex> BTx.RPC.Wallets.list_unspent(client,
      ...>   wallet_name: "my_wallet",
      ...>   minconf: 1,
      ...>   maxconf: 9999999,
      ...>   include_unsafe: false
      ...> )
      {:ok, [%BTx.RPC.Wallets.ListUnspentItem{...}]}

  """
  @spec list_unspent(RPC.client(), params(), keyword()) :: response([ListUnspentItem.t()])
  def list_unspent(client, params \\ [], opts \\ []) do
    with {:ok, request} <- ListUnspent.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      parse_unspent_list(result)
    end
  end

  @doc """
  Same as `list_unspent/3` but raises on error.
  """
  @spec list_unspent!(RPC.client(), params(), keyword()) :: [ListUnspentItem.t()]
  def list_unspent!(client, params \\ [], opts \\ []) do
    client
    |> RPC.call!(ListUnspent.new!(params), opts)
    |> Map.fetch!(:result)
    |> parse_unspent_list!()
  end

  ## Raw Transactions

  @doc """
  Sign inputs for raw transaction (serialized, hex-encoded).

  The second optional argument (may be null) is an array of previous transaction
  outputs that this transaction depends on but may not yet be in the block chain.

  Requires wallet passphrase to be set with walletpassphrase call if wallet is
  encrypted.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Wallets.SignRawTransactionWithWallet` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Sign a raw transaction with wallet
      iex> BTx.RPC.Wallets.sign_raw_transaction_with_wallet(client,
      ...>   hexstring: "0200000001...",
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.SignRawTransactionWithWalletResult{
        hex: "0200000001...",
        complete: true,
        errors: []
      }}

      # Sign with previous transactions
      iex> BTx.RPC.Wallets.sign_raw_transaction_with_wallet(client,
      ...>   hexstring: "0200000001...",
      ...>   prevtxs: [
      ...>     %{
      ...>       txid: "abc123...",
      ...>       vout: 0,
      ...>       script_pub_key: "76a914...",
      ...>       amount: 0.01
      ...>     }
      ...>   ],
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.SignRawTransactionWithWalletResult{...}}

      # Sign with custom signature hash type
      iex> BTx.RPC.Wallets.sign_raw_transaction_with_wallet(client,
      ...>   hexstring: "0200000001...",
      ...>   sighashtype: "SINGLE",
      ...>   wallet_name: "my_wallet"
      ...> )
      {:ok, %BTx.RPC.Wallets.SignRawTransactionWithWalletResult{...}}

  """
  @spec sign_raw_transaction_with_wallet(RPC.client(), params(), keyword()) ::
          response(SignRawTransactionWithWalletResult.t())
  def sign_raw_transaction_with_wallet(client, params, opts \\ []) do
    with {:ok, request} <- SignRawTransactionWithWallet.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      SignRawTransactionWithWalletResult.new(result)
    end
  end

  @doc """
  Same as `sign_raw_transaction_with_wallet/3` but raises on error.
  """
  @spec sign_raw_transaction_with_wallet!(RPC.client(), params(), keyword()) ::
          SignRawTransactionWithWalletResult.t()
  def sign_raw_transaction_with_wallet!(client, params, opts \\ []) do
    client
    |> RPC.call!(SignRawTransactionWithWallet.new!(params), opts)
    |> Map.fetch!(:result)
    |> SignRawTransactionWithWalletResult.new!()
  end

  ## Private helper functions

  defp parse_transaction_list(transactions) do
    transactions
    |> assert_transaction_list!()
    |> Enum.reduce_while({:ok, []}, fn transaction, {:ok, acc} ->
      case ListTransactionsItem.new(transaction) do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
    |> case do
      {:ok, items} -> {:ok, Enum.reverse(items)}
      error -> error
    end
  end

  defp parse_transaction_list!(transactions) do
    transactions
    |> assert_transaction_list!()
    |> Enum.map(&ListTransactionsItem.new!/1)
  end

  defp assert_transaction_list!(transactions) when is_list(transactions) do
    transactions
  end

  defp assert_transaction_list!(transactions) do
    raise "Expected a list of transactions, got #{inspect(transactions)}"
  end

  defp parse_unspent_list(unspent_outputs) do
    unspent_outputs
    |> assert_unspent_list!()
    |> Enum.reduce_while({:ok, []}, fn unspent, {:ok, acc} ->
      case ListUnspentItem.new(unspent) do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
    |> case do
      {:ok, items} -> {:ok, Enum.reverse(items)}
      error -> error
    end
  end

  defp parse_unspent_list!(unspent_outputs) do
    unspent_outputs
    |> assert_unspent_list!()
    |> Enum.map(&ListUnspentItem.new!/1)
  end

  defp assert_unspent_list!(unspent_outputs) when is_list(unspent_outputs) do
    unspent_outputs
  end

  defp assert_unspent_list!(unspent_outputs) do
    raise "Expected a list of unspent outputs, got #{inspect(unspent_outputs)}"
  end
end
