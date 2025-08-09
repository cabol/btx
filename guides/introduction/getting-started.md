# 🚀 Getting Started with BTx

Welcome to BTx, the comprehensive Bitcoin toolkit for Elixir! This guide will
walk you through everything you need to know to start building Bitcoin
applications with BTx.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Setting up Bitcoin Core](#setting-up-bitcoin-core)
- [Your First Client](#your-first-client)
- [Working with Wallets](#working-with-wallets)
- [Understanding Addresses](#understanding-addresses)
- [Managing Transactions](#managing-transactions)
- [Blockchain Operations](#blockchain-operations)
- [Error Handling](#error-handling)
- [Advanced Configuration](#advanced-configuration)
- [Best Practices](#best-practices)

## 🎯 Prerequisites

Before getting started with BTx, make sure you have:

- **Elixir 1.14+** and **OTP 24+**
- **Bitcoin Core** (we'll help you set this up)
- Basic familiarity with **Elixir** and **functional programming**
- Understanding of **Bitcoin fundamentals** (addresses, transactions, blocks)

## 📦 Installation

### 1. Add BTx to Your Project

Add `btx` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:btx, "~> 0.1.0"}
  ]
end
```

### 2. Fetch Dependencies

```bash
mix deps.get
```

## ⛓️ Setting up Bitcoin Core

BTx requires a running Bitcoin Core instance. We'll set up a regtest node for
development.

### Option A: Using Docker (Recommended)

BTx includes a ready-to-use Docker Compose configuration:

```bash
# Clone the BTx repo (or copy docker-compose.yml)
git clone https://github.com/cabol/btx.git
cd btx

# Start Bitcoin Core in regtest mode
docker-compose up -d

# Verify it's running
docker-compose logs bitcoin-core
```

### Option B: Local Bitcoin Core Installation

1. **Download Bitcoin Core** from [bitcoin.org](https://bitcoin.org/en/download)

2. **Create a configuration file** at `~/.bitcoin/bitcoin.conf`:

```ini
# Regtest mode for development
regtest=1

# RPC settings
server=1
rpcuser=my-user
rpcpassword=my-secure-password
rpcport=18443
rpcbind=127.0.0.1
rpcallowip=127.0.0.1

# Enable wallet functionality
wallet=default
```

3. **Start Bitcoin Core**:

```bash
bitcoind -daemon
```

### Verify Bitcoin Core is Running

```bash
# Using bitcoin-cli
bitcoin-cli -regtest getblockchaininfo

# Using curl
curl -u "my-user:my-secure-password" -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"1.0","id":"test","method":"getblockchaininfo","params":[]}' \
  http://127.0.0.1:18443/
```

## 🔌 Your First Client

Let's create your first BTx client and make a connection:

```elixir
# Start an IEx session
iex -S mix

# Create a client
client = BTx.RPC.client(
  base_url: "http://127.0.0.1:18443",
  username: "my-user",
  password: "my-secure-password"
)

# Test the connection
{:ok, info} = BTx.RPC.Blockchain.get_blockchain_info(client)
IO.inspect(info.chain)  # => "regtest"
```

### Client Configuration Options

```elixir
config = [
  # Required
  base_url: "http://127.0.0.1:18443",
  username: "my-user",
  password: "my-secure-password",

  # Optional
  headers: [{"User-Agent", "MyApp/1.0"}],
  adapter: {Tesla.Adapter.Hackney, [pool: :btx]},
  timeout: 30_000
]

client = BTx.RPC.client(config)

# You can also configure retries
client = BTx.RPC.client([retry_opts: [max_retries: 10]] ++ config)
```

## 💰 Working with Wallets

### Creating Your First Wallet

```elixir
# Create a new wallet with descriptors (recommended)
{:ok, result} = BTx.RPC.Wallets.create_wallet(client,
  wallet_name: "development-wallet",
  passphrase: "super-secure-passphrase",
  avoid_reuse: true,
  descriptors: true,
  load_on_startup: true
)

IO.puts("Created wallet: #{result.name}")
```

### Loading and Managing Wallets

```elixir
# List all available wallets
{:ok, wallets} = BTx.RPC.Wallets.list_wallets(client)
IO.inspect(wallets)

# Load an existing wallet
{:ok, result} = BTx.RPC.Wallets.load_wallet(client,
  filename: "my-existing-wallet.dat",
  load_on_startup: true
)

# Get wallet information
{:ok, info} = BTx.RPC.Wallets.get_wallet_info(client,
  wallet_name: "development-wallet"
)

IO.inspect(info.walletname)
IO.inspect(info.balance)
IO.inspect(info.txcount)
```

### Wallet Operations

```elixir
# Get wallet balance
{:ok, balance} = BTx.RPC.Wallets.get_balance(client,
  wallet_name: "development-wallet"
)
IO.puts("Balance: #{balance} BTC")

# Get wallet balances (detailed breakdown)
{:ok, balances} = BTx.RPC.Wallets.get_balances(client,
  wallet_name: "development-wallet"
)
```

## 📍 Understanding Addresses

### Generating New Addresses

```elixir
# Generate a bech32 address (recommended for new applications)
{:ok, address} = BTx.RPC.Wallets.get_new_address(client,
  wallet_name: "development-wallet",
  label: "customer-payment-001",
  address_type: "bech32"
)
IO.puts("New address: #{address}")

# Generate different address types
address_types = ["legacy", "p2sh-segwit", "bech32"]

for type <- address_types do
  {:ok, addr} = BTx.RPC.Wallets.get_new_address(client,
    wallet_name: "development-wallet",
    label: "test-#{type}",
    address_type: type
  )
  IO.puts("#{type}: #{addr}")
end
```

### Address Information and Validation

```elixir
# Get detailed address information
{:ok, info} = BTx.RPC.Wallets.get_address_info(client,
  address: address,
  wallet_name: "development-wallet"
)

IO.inspect(%{
  address: info.address,
  is_mine: info.ismine,
  script_type: info.script,
  label: info.label,
  hd_key_path: info.hdkeypath
})

# Validate address format
{:ok, validation} = BTx.RPC.Utils.validate_address(client,
  address: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
)

IO.inspect(%{
  is_valid: validation.isvalid,
  address_type: validation.address_type,
  script_type: validation.script_type
})
```

### Working with Labels

```elixir
# Get addresses by label
{:ok, addresses} = BTx.RPC.Wallets.get_addresses_by_label(client,
  label: "customer-payments",
  wallet_name: "development-wallet"
)

for {address, info} <- addresses do
  IO.puts("#{address}: #{info["purpose"]}")
end
```

## 💸 Managing Transactions

### Mining Some Test Bitcoin (Regtest Only)

```elixir
# In regtest, we can mine blocks to get test Bitcoin
{:ok, address} = BTx.RPC.Wallets.get_new_address(client,
  wallet_name: "development-wallet"
)

# Mine 101 blocks (100 + 1 for maturity) to this address
{:ok, block_hashes} = BTx.RPC.Mining.generate_to_address(client,
  nblocks: 101,
  address: address
)

IO.puts("Mined #{length(block_hashes)} blocks")

# Check balance (should have 50 BTC * 100 blocks)
{:ok, balance} = BTx.RPC.Wallets.get_balance(client,
  wallet_name: "development-wallet"
)
IO.puts("Balance: #{balance} BTC")
```

### Sending Transactions

```elixir
# Create a second wallet for testing
{:ok, _} = BTx.RPC.Wallets.create_wallet(client,
  wallet_name: "recipient-wallet",
  descriptors: true
)

# Get address from recipient wallet
{:ok, recipient_address} = BTx.RPC.Wallets.get_new_address(client,
  wallet_name: "recipient-wallet",
  label: "incoming-payment"
)

# Send Bitcoin from development wallet
{:ok, txid} = BTx.RPC.Wallets.send_to_address(client,
  address: recipient_address,
  amount: 1.5,  # 1.5 BTC
  comment: "Test payment",
  comment_to: "Recipient wallet",
  wallet_name: "development-wallet"
)

IO.puts("Transaction sent: #{txid}")
```

### Advanced Transaction Operations

```elixir
# Send with custom fee rate
{:ok, txid} = BTx.RPC.Wallets.send_to_address(client,
  address: recipient_address,
  amount: 0.1,
  fee_rate: 0.00001000,  # 1 sat/byte
  wallet_name: "development-wallet"
)

# List transactions
{:ok, transactions} = BTx.RPC.Wallets.list_transactions(client,
  wallet_name: "development-wallet",
  count: 10
)

for tx <- transactions do
  IO.puts("#{tx.category}: #{tx.amount} BTC (#{tx.confirmations} confirmations)")
end
```

### Raw Transaction Operations

```elixir
# Create a raw transaction
{:ok, unspent} = BTx.RPC.Wallets.list_unspent(client,
  wallet_name: "development-wallet"
)

# Use the first unspent output
input = %{
  txid: List.first(unspent).txid,
  vout: List.first(unspent).vout
}

outputs = %{
  addresses: [%{address: recipient_address, amount: 0.1}]
}

{:ok, raw_tx} = BTx.RPC.RawTransactions.create_raw_transaction(client,
  inputs: [input],
  outputs: outputs
)

# Fund the transaction (add inputs and change output)
{:ok, funded_tx} = BTx.RPC.RawTransactions.fund_raw_transaction(client,
  hexstring: raw_tx,
  wallet_name: "development-wallet"
)

# Sign the transaction
{:ok, signed_tx} = BTx.RPC.Wallets.sign_raw_transaction_with_wallet(client,
  hexstring: funded_tx.hex,
  wallet_name: "development-wallet"
)

# Send the transaction
{:ok, txid} = BTx.RPC.RawTransactions.send_raw_transaction(client,
  hexstring: signed_tx.hex
)
```

## ⛓️ Blockchain Operations

### Exploring the Blockchain

```elixir
# Get current blockchain info
{:ok, info} = BTx.RPC.Blockchain.get_blockchain_info(client)

IO.inspect(%{
  chain: info.chain,
  blocks: info.blocks,
  best_block_hash: info.bestblockhash,
  difficulty: info.difficulty
})

# Get specific block information
{:ok, block} = BTx.RPC.Blockchain.get_block(client,
  blockhash: info.bestblockhash,
  verbosity: 2  # Include transaction details
)

IO.inspect(%{
  height: block.height,
  timestamp: block.time,
  transactions: length(block.tx),
  size: block.size
})
```

### Working with Transactions

```elixir
# Get transaction details
first_tx = List.first(block.tx)

{:ok, tx_details} = BTx.RPC.RawTransactions.get_raw_transaction(client,
  txid: first_tx.txid,
  verbose: true
)

IO.inspect(%{
  txid: tx_details.txid,
  inputs: length(tx_details.vin),
  outputs: length(tx_details.vout),
  confirmations: tx_details.confirmations
})

# Get mempool information
{:ok, mempool_info} = BTx.RPC.Blockchain.get_mempool_info(client)

IO.inspect(%{
  size: mempool_info.size,
  bytes: mempool_info.bytes,
  usage: mempool_info.usage
})
```

## ⚠️ Error Handling

BTx provides comprehensive error handling for all scenarios you'll encounter:

### Common Error Patterns

```elixir
defmodule MyBitcoinApp do
  require Logger

  def create_wallet_safely(client, name) do
    case BTx.RPC.Wallets.create_wallet(client, wallet_name: name) do
      # Success
      {:ok, result} ->
        Logger.info("Wallet created: #{result.name}")
        {:ok, result}

      # Bitcoin Core specific errors - using enhanced error handling
      {:error, %BTx.RPC.MethodError{reason: reason, message: message}} ->
        Logger.error("Method error (#{reason}): #{message}")
        {:error, :method_error}

      # Connection and authentication errors
      {:error, %BTx.RPC.Error{reason: :http_unauthorized}} ->
        Logger.error("Authentication failed - check credentials")
        {:error, :auth_failed}

      {:error, %BTx.RPC.Error{reason: :econnrefused}} ->
        Logger.error("Cannot connect to Bitcoin Core")
        {:error, :connection_failed}

      {:error, %BTx.RPC.Error{reason: :timeout}} ->
        Logger.error("Request timed out")
        {:error, :timeout}

      # Validation errors
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Validation failed: #{inspect(changeset.errors)}")
        {:error, :validation_failed}

      # Unexpected errors
      {:error, error} ->
        Logger.error("Unexpected error: #{Exception.message(error)}")
        {:error, :unknown}
    end
  end
end
```

### Error Code Reference

Common Bitcoin Core RPC error codes:

| Code | Meaning | Common Causes |
|------|---------|---------------|
| -1 | Miscellaneous error | Various issues |
| -3 | Invalid amount | Negative or too precise amounts |
| -4 | Wallet already exists | Duplicate wallet creation |
| -5 | Invalid address | Malformed Bitcoin address |
| -6 | Insufficient funds | Not enough balance |
| -8 | Invalid parameter | Wrong parameter types/values |
| -13 | Wallet encryption | Wrong passphrase |
| -18 | Wallet not found | Wallet not loaded |

## ⚙️ Advanced Configuration

### Connection Pooling

```elixir
# Configure connection pooling for production
defmodule MyApp.BitcoinClient do
  def new_client do
    BTx.RPC.client(
      base_url: Application.get_env(:my_app, :bitcoin_url),
      username: Application.get_env(:my_app, :bitcoin_user),
      password: Application.get_env(:my_app, :bitcoin_password),

      # With retries
      retry_opts: [max_retries: 10, max_delay: :timer.seconds(5)],

      # Use connection pooling
      adapter: {Tesla.Adapter.Finch, name: :bitcoin_pool}
    )
  end
end

# In your application supervisor
children = [
  # Start the connection pool
  {Finch, name: :bitcoin_pool, pools: %{
    default: [count: 10, size: 50]
  }},
  # Your other processes
]
```

### Environment Configuration

```elixir
# config/config.exs
config :my_app, :bitcoin,
  url: System.get_env("BITCOIN_RPC_URL", "http://127.0.0.1:18443"),
  username: System.get_env("BITCOIN_RPC_USER", "my-user"),
  password: System.get_env("BITCOIN_RPC_PASSWORD", "my-password")

# config/prod.exs
config :my_app, :bitcoin,
  url: {:system, "BITCOIN_RPC_URL"},
  username: {:system, "BITCOIN_RPC_USER"},
  password: {:system, "BITCOIN_RPC_PASSWORD"}
```

### Telemetry Integration

BTx emits telemetry events that you can use for monitoring:

```elixir
defmodule MyApp.BitcoinTelemetry do
  require Logger

  def setup do
    :telemetry.attach_many(
      "bitcoin-rpc-events",
      [
        [:btx, :rpc, :call, :start],
        [:btx, :rpc, :call, :stop],
        [:btx, :rpc, :call, :exception]
      ],
      &handle_event/4,
      nil
    )
  end

  def handle_event([:btx, :rpc, :call, :start], measurements, metadata, _config) do
    Logger.info("Bitcoin RPC call started: #{metadata.method}")
  end

  def handle_event([:btx, :rpc, :call, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    Logger.info("Bitcoin RPC call completed: #{metadata.method} (#{duration_ms}ms)")
  end

  def handle_event([:btx, :rpc, :call, :exception], measurements, metadata, _config) do
    Logger.error("Bitcoin RPC call failed: #{metadata.method} - #{inspect(metadata.reason)}")
  end
end
```

## 🎯 Best Practices

### 1. Connection Management

```elixir
# ✅ Good: Create one client and reuse it
defmodule MyApp.Bitcoin do
  def start_link(_) do
    client = BTx.RPC.client(
      base_url: config(:url),
      username: config(:username),
      password: config(:password)
    )

    GenServer.start_link(__MODULE__, client, name: __MODULE__)
  end

  def get_client do
    GenServer.call(__MODULE__, :get_client)
  end
end

# ❌ Bad: Creating clients on every call
def bad_example do
  client = BTx.RPC.client(...)  # Don't do this repeatedly
  BTx.RPC.Wallets.get_balance(client, wallet_name: "test")
end
```

### 2. Error Handling Patterns

```elixir
# ✅ Good: Comprehensive error handling
def safe_wallet_operation(client, wallet_name) do
  with {:ok, info} <- BTx.RPC.Wallets.get_wallet_info(client,
                        wallet_name: wallet_name),
       {:ok, balance} <- BTx.RPC.Wallets.get_balance(client,
                           wallet_name: wallet_name) do
    {:ok, %{info: info, balance: balance}}
  else
    {:error, %BTx.RPC.MethodError{reason: :wallet_not_found}} ->
      {:error, :wallet_not_loaded}
    {:error, error} ->
      {:error, error}
  end
end

# ❌ Bad: Ignoring errors
def bad_example(client) do
  {:ok, balance} = BTx.RPC.Wallets.get_balance(client, wallet_name: "test")
  balance  # Will crash if wallet doesn't exist
end
```

### 3. Type Safety

```elixir
# ✅ Good: Use result schemas
{:ok, info} = BTx.RPC.Blockchain.get_blockchain_info(client)
blocks = info.blocks  # Type-safe field access

# ✅ Good: Validate inputs with schemas
{:ok, request} = BTx.RPC.Wallets.CreateWallet.new(
  wallet_name: "my-wallet",
  descriptors: true
)
BTx.RPC.call(client, request)

# ❌ Bad: Using generic call without validation
{:ok, response} = BTx.RPC.call(client, %{method: "createwallet",
                                          params: [""]})
```

### 4. Wallet Management

```elixir
# ✅ Good: Explicit wallet routing
{:ok, balance} = BTx.RPC.Wallets.get_balance(client,
  wallet_name: "production-wallet"
)

# ✅ Good: Create wallets with descriptors
{:ok, _} = BTx.RPC.Wallets.create_wallet(client,
  wallet_name: "my-app-wallet",
  descriptors: true,        # Better UTXO management
  avoid_reuse: true,        # Better privacy
  load_on_startup: false    # Don't auto-load unless needed
)
```

## 💡 Common Patterns and Examples

Here are some real-world patterns you'll frequently use:

### Payment Processing Service
```elixir
defmodule MyApp.PaymentProcessor do
  require Logger

  def process_payment(client, recipient_address, amount_btc, order_id) do
    case BTx.RPC.Wallets.send_to_address(client,
           address: recipient_address,
           amount: amount_btc,
           comment: "Order ##{order_id}",
           wallet_name: "payments"
         ) do
      {:ok, txid} ->
        Logger.info("Payment sent for order #{order_id}: #{txid}")
        {:ok, txid}

      {:error, %BTx.RPC.MethodError{reason: :wallet_insufficient_funds}} ->
        Logger.warn("Insufficient funds for order #{order_id}")
        {:error, :insufficient_funds}

      {:error, error} ->
        Logger.error("Payment failed for order #{order_id}: #{inspect(error)}")
        {:error, :payment_failed}
    end
  end

  def get_payment_address(client, user_id) do
    label = "user-#{user_id}"

    case BTx.RPC.Wallets.get_new_address(client,
           wallet_name: "incoming",
           label: label,
           address_type: "bech32"
         ) do
      {:ok, address} ->
        Logger.info("Generated address for user #{user_id}: #{address}")
        {:ok, address}

      {:error, error} ->
        Logger.error("Failed to generate address for user #{user_id}: #{inspect(error)}")
        {:error, :address_generation_failed}
    end
  end
end
```

### Balance Monitoring
```elixir
defmodule MyApp.BalanceMonitor do
  use GenServer
  require Logger

  def start_link(client) do
    GenServer.start_link(__MODULE__, client, name: __MODULE__)
  end

  def init(client) do
    schedule_check()
    {:ok, %{client: client, last_balance: 0}}
  end

  def handle_info(:check_balance, %{client: client} = state) do
    case BTx.RPC.Wallets.get_balance(client, wallet_name: "main") do
      {:ok, current_balance} ->
        if current_balance != state.last_balance do
          Logger.info("Balance changed: #{state.last_balance} -> #{current_balance} BTC")
          notify_balance_change(state.last_balance, current_balance)
        end

        schedule_check()
        {:noreply, %{state | last_balance: current_balance}}

      {:error, error} ->
        Logger.error("Failed to check balance: #{inspect(error)}")
        schedule_check()
        {:noreply, state}
    end
  end

  defp schedule_check do
    # Check every 30 seconds
    Process.send_after(self(), :check_balance, 30_000)
  end

  defp notify_balance_change(old_balance, new_balance) do
    # Send notifications, update database, etc.
    Phoenix.PubSub.broadcast(MyApp.PubSub, "balance_updates", {
      :balance_changed,
      %{old: old_balance, new: new_balance}
    })
  end
end
```

### Transaction History Analysis
```elixir
defmodule MyApp.TransactionAnalyzer do
  def analyze_wallet_activity(client, wallet_name, days_back \\ 30) do
    {:ok, transactions} = BTx.RPC.Wallets.list_transactions(client,
      wallet_name: wallet_name,
      count: 1000
    )

    cutoff_time = DateTime.utc_now()
                  |> DateTime.add(-days_back, :day)
                  |> DateTime.to_unix()

    recent_transactions = Enum.filter(transactions, fn tx ->
      tx.time >= cutoff_time
    end)

    %{
      total_transactions: length(recent_transactions),
      incoming_count: count_by_category(recent_transactions, "receive"),
      outgoing_count: count_by_category(recent_transactions, "send"),
      total_received: sum_by_category(recent_transactions, "receive"),
      total_sent: abs(sum_by_category(recent_transactions, "send")),
      average_transaction: calculate_average_amount(recent_transactions),
      most_active_day: find_most_active_day(recent_transactions)
    }
  end

  defp count_by_category(transactions, category) do
    Enum.count(transactions, fn tx -> tx.category == category end)
  end

  defp sum_by_category(transactions, category) do
    transactions
    |> Enum.filter(fn tx -> tx.category == category end)
    |> Enum.map(fn tx -> tx.amount end)
    |> Enum.sum()
  end

  defp calculate_average_amount(transactions) do
    if length(transactions) > 0 do
      total = Enum.map(transactions, fn tx -> abs(tx.amount) end)
              |> Enum.sum()
      total / length(transactions)
    else
      0
    end
  end

  defp find_most_active_day(transactions) do
    transactions
    |> Enum.group_by(fn tx ->
      DateTime.from_unix!(tx.time) |> DateTime.to_date()
    end)
    |> Enum.max_by(fn {_date, txs} -> length(txs) end,
                    fn -> {Date.utc_today(), []} end)
    |> elem(0)
  end
end
```

## 🔧 Development and Testing

### Setting up Tests
```elixir
# test/support/bitcoin_case.ex
defmodule MyApp.BitcoinCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import MyApp.BitcoinCase

      setup :setup_bitcoin_client
    end
  end

  def setup_bitcoin_client(_context) do
    client = BTx.RPC.client(
      base_url: "http://127.0.0.1:18443",
      username: "test-user",
      password: "test-password"
    )

    # Ensure we have a test wallet
    case BTx.RPC.Wallets.create_wallet(client,
           wallet_name: "test-wallet",
           descriptors: true) do
      {:ok, _} -> :ok
      {:error, %BTx.RPC.MethodError{reason: :wallet_error}} -> :ok  # Wallet exists
      {:error, error} ->
        raise "Failed to create test wallet: #{inspect(error)}"
    end

    {:ok, client: client, wallet_name: "test-wallet"}
  end

  def mine_blocks(client, address, count \\ 1) do
    {:ok, _} = BTx.RPC.Mining.generate_to_address(client,
      nblocks: count,
      address: address
    )
  end

  def wait_for_confirmations(client, txid, confirmations \\ 1) do
    case BTx.RPC.RawTransactions.get_raw_transaction(client,
           txid: txid,
           verbose: true) do
      {:ok, tx} when tx.confirmations >= confirmations -> :ok
      {:ok, _tx} ->
        Process.sleep(100)
        wait_for_confirmations(client, txid, confirmations)
      {:error, _} ->
        Process.sleep(100)
        wait_for_confirmations(client, txid, confirmations)
    end
  end
end
```

### Example Test
```elixir
# test/my_app/payment_processor_test.exs
defmodule MyApp.PaymentProcessorTest do
  use MyApp.BitcoinCase, async: false

  alias MyApp.PaymentProcessor

  test "processes payment successfully", %{client: client, wallet_name: wallet} do
    # Setup: mine some blocks to get balance
    {:ok, address} = BTx.RPC.Wallets.get_new_address(client,
                       wallet_name: wallet)
    mine_blocks(client, address, 101)

    # Get recipient address
    {:ok, recipient} = BTx.RPC.Wallets.get_new_address(client,
      wallet_name: wallet,
      label: "test-recipient"
    )

    # Process payment
    assert {:ok, txid} = PaymentProcessor.process_payment(
      client,
      recipient,
      0.1,
      "TEST-001"
    )

    # Verify transaction exists
    assert {:ok, tx} = BTx.RPC.RawTransactions.get_raw_transaction(
      client,
      txid: txid,
      verbose: true
    )

    assert tx.txid == txid
  end

  test "handles insufficient funds", %{client: client} do
    # Create empty wallet
    {:ok, _} = BTx.RPC.Wallets.create_wallet(client,
      wallet_name: "empty-wallet",
      descriptors: true
    )

    {:ok, address} = BTx.RPC.Wallets.get_new_address(client,
      wallet_name: "empty-wallet"
    )

    # Try to send from empty wallet
    assert {:error, :insufficient_funds} = PaymentProcessor.process_payment(
      client,
      address,
      1.0,
      "FAIL-001"
    )
  end
end
```

## 🚀 Production Deployment

### Environment Variables
```bash
# .env.prod
BITCOIN_RPC_URL=https://your-bitcoin-node.com:8332
BITCOIN_RPC_USER=production-user
BITCOIN_RPC_PASSWORD=super-secure-password

# SSL Configuration
BITCOIN_RPC_SSL=true
BITCOIN_RPC_SSL_VERIFY=true

# Connection settings
BITCOIN_RPC_TIMEOUT=60000
```

### Production Configuration
```elixir
# config/prod.exs
config :my_app, :bitcoin,
  url: System.get_env("BITCOIN_RPC_URL"),
  username: System.get_env("BITCOIN_RPC_USER"),
  password: System.get_env("BITCOIN_RPC_PASSWORD"),
  ssl: System.get_env("BITCOIN_RPC_SSL", "false") == "true",
  timeout: String.to_integer(System.get_env("BITCOIN_RPC_TIMEOUT", "30000"))

  # Connection pooling for production
  adapter_config: [
    pool: :bitcoin_pool,
    timeout: 60_000,
    recv_timeout: 60_000,
    max_connections: 50
  ]
```

### Health Checks
```elixir
defmodule MyApp.HealthCheck do
  def bitcoin_health(client) do
    case BTx.RPC.Blockchain.get_blockchain_info(client) do
      {:ok, info} ->
        %{
          status: :healthy,
          chain: info.chain,
          blocks: info.blocks,
          sync_progress: info.verificationprogress
        }

      {:error, error} ->
        %{
          status: :unhealthy,
          error: Exception.message(error)
        }
    end
  end

  def wallet_health(client, wallet_name) do
    case BTx.RPC.Wallets.get_wallet_info(client, wallet_name: wallet_name) do
      {:ok, info} ->
        %{
          status: :healthy,
          wallet: info.walletname,
          balance: info.balance,
          transactions: info.txcount
        }

      {:error, error} ->
        %{
          status: :unhealthy,
          wallet: wallet_name,
          error: Exception.message(error)
        }
    end
  end
end
```

## 📊 Monitoring and Observability

### Custom Metrics
```elixir
defmodule MyApp.BitcoinMetrics do
  use Supervisor

  def start_link(client) do
    Supervisor.start_link(__MODULE__, client, name: __MODULE__)
  end

  def init(client) do
    children = [
      {Task, fn -> collect_metrics(client) end}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp collect_metrics(client) do
    :telemetry.execute([:bitcoin, :blocks], %{count: get_block_count(client)})
    :telemetry.execute([:bitcoin, :mempool], %{size: get_mempool_size(client)})
    :telemetry.execute([:bitcoin, :wallet_balance], %{balance: get_total_balance(client)})

    Process.sleep(30_000)
    collect_metrics(client)
  end

  defp get_block_count(client) do
    case BTx.RPC.Blockchain.get_block_count(client) do
      {:ok, count} -> count
      {:error, _} -> 0
    end
  end

  defp get_mempool_size(client) do
    case BTx.RPC.Blockchain.get_mempool_info(client) do
      {:ok, info} -> info.size
      {:error, _} -> 0
    end
  end

  defp get_total_balance(client) do
    case BTx.RPC.Wallets.get_balance(client) do
      {:ok, balance} -> balance
      {:error, _} -> 0.0
    end
  end
end
```

## 🎉 Next Steps

Congratulations! You now have a solid foundation with BTx. Here are some
suggested next steps:

### 📖 Further Reading
- [API Documentation](http://hexdocs.pm/btx) - Complete function reference
- [Bitcoin Core RPC Reference](https://developer.bitcoin.org/reference/rpc/) -
  Underlying RPC documentation

### 🏗️ Build Something Amazing
- **Payment Processor**: Handle incoming Bitcoin payments
- **Wallet Service**: Multi-user wallet management
- **Block Explorer**: Blockchain data visualization
- **Trading Bot**: Automated Bitcoin trading
- **Lightning Integration**: Layer 2 payment solutions

### 🤝 Get Involved
- [Open an Issue](https://github.com/cabol/btx/issues) - Report bugs or
  request features
- [Submit a PR](https://github.com/cabol/btx/pulls) - Contribute code
  improvements
- [Join Discussions](https://github.com/cabol/btx/discussions) - Share ideas
  and ask questions
- [Star the Project](https://github.com/cabol/btx) - Show your support

---

## 🎊 Congratulations!

You've completed the BTx getting started guide! You now have the knowledge to:

- ✅ Set up Bitcoin Core for development and production
- ✅ Create and configure BTx clients
- ✅ Manage wallets and addresses
- ✅ Send and receive Bitcoin transactions
- ✅ Handle errors gracefully
- ✅ Implement production-ready patterns
- ✅ Monitor and test your Bitcoin applications

### 🚀 Ready to Build?

With BTx, you have everything you need to build robust Bitcoin applications
in Elixir. The combination of Elixir's fault-tolerance and BTx's type-safe
Bitcoin integration gives you a powerful foundation for any Bitcoin project.

**Happy coding!** 🎉

---

## 📚 Additional Resources

- **[BTx Documentation](http://hexdocs.pm/btx)** - Complete API reference
- **[Bitcoin Core Documentation](https://developer.bitcoin.org/reference/rpc/)** -
  RPC reference
- **[Elixir Guides](https://elixir-lang.org/getting-started/introduction.html)** -
  Learn Elixir
- **[Bitcoin Developer Resources](https://developer.bitcoin.org/)** - Bitcoin
  development guides
