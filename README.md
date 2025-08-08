# ⚡₿𝕋𝕩
> Bitcoin Toolkit for Elixir.

![CI](http://github.com/cabol/btx/workflows/CI/badge.svg)
[![Codecov](http://codecov.io/gh/cabol/btx/graph/badge.svg)](http://codecov.io/gh/cabol/btx/graph/badge.svg)
[![Hex.pm](http://img.shields.io/hexpm/v/btx.svg)](http://hex.pm/packages/btx)
[![Documentation](http://img.shields.io/badge/Documentation-ff69b4)](http://hexdocs.pm/btx)

**BTx** is a modern Elixir library for Bitcoin development, starting with a
powerful JSON-RPC client for Bitcoin Core. Designed for developers building
Bitcoin applications, `BTx` provides an idiomatic Elixir interface with
comprehensive Bitcoin tooling.

## ✨ Features

### 🚀 Complete JSON-RPC Implementation
- **Full Bitcoin Core API Coverage**: Complete implementation of Bitcoin
  Core's JSON-RPC API.
- **Type-Safe Requests**: All methods use Ecto schemas with automatic
  validation.
- **Intelligent Response Parsing**: Structured response handling with embedded
  schemas.

### 🛠️ Developer Experience
- **Idiomatic Elixir Interface**: Clean, functional API that feels natural in
  Elixir applications.
- **Context-Organized API**: Well-organized modules (`BTx.RPC.Wallets`,
  `BTx.RPC.Blockchain`, etc.).
- **Comprehensive Error Handling**: Detailed error messages with specific
  Bitcoin Core error codes.
- **Built-in Retries**: Configurable retry logic for network resilience.

### 🔧 Enterprise-Ready
- **Flexible HTTP Client**: Built on Tesla for maximum configurability.
- **Telemetry Integration**: Built-in metrics and observability.
- **Connection Pooling**: Efficient resource management.
- **Wallet Routing**: Automatic wallet-specific endpoint routing.

## 🚀 Quick Install

Add `btx` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:btx, "~> 0.1.0"}
  ]
end
```

For more detailed information, see the
[getting started guide][getting_started] and
[online documentation][docs].

[getting_started]: http://hexdocs.pm/btx/getting-started.html
[docs]: http://hexdocs.pm/btx/BTx.html

## ⚡ Quick Start

### 1. Start Bitcoin Core (Regtest)
```bash
# Using the included docker-compose
docker-compose up -d
```

### 2. Create a Client
```elixir
client = BTx.RPC.client(
  base_url: "http://127.0.0.1:18443",
  username: "my-user",
  password: "my-pass"
)
```

### 3. Create Your First Wallet
```elixir
{:ok, result} = BTx.RPC.Wallets.create_wallet(client,
  wallet_name: "my-wallet",
  passphrase: "secure-passphrase",
  avoid_reuse: true,
  descriptors: true
)

# => %BTx.RPC.Wallets.CreateWalletResult{name: "my-wallet", warning: nil}
```

### 4. Generate Addresses & Send Transactions
```elixir
# Generate a new address
{:ok, address} = BTx.RPC.Wallets.get_new_address(client,
  wallet_name: "my-wallet",
  label: "customer-payment",
  address_type: "bech32"
)

# Get wallet balance
{:ok, balance} = BTx.RPC.Wallets.get_balance(client,
  wallet_name: "my-wallet"
)

# Send payment
{:ok, txid} = BTx.RPC.Wallets.send_to_address(client,
  address: "bc1q...",
  amount: 0.001,
  wallet_name: "my-wallet"
)
```

## 🎯 Key Advantages

### Type Safety First
```elixir
# ✅ Type-safe with validation
{:ok, wallet} = BTx.RPC.Wallets.create_wallet(client,
  wallet_name: "valid-name",
  descriptors: true
)

# ❌ Invalid parameters caught early
{:error, changeset} = BTx.RPC.Wallets.create_wallet(client,
  wallet_name: "", # Empty name validation fails
  descriptors: "invalid" # Type validation fails
)
```

### Comprehensive Error Handling
```elixir
case BTx.RPC.Wallets.create_wallet(client, wallet_name: "existing") do
  {:ok, result} ->
    # Success
  {:error, %BTx.RPC.MethodError{reason: :misc_error}} ->
    # Wallet already exists
  {:error, %BTx.RPC.Error{reason: :econnrefused}} ->
    # Bitcoin Core not running
end
```

### Context-Organized API
- **`BTx.RPC.Blockchain`** - Blockchain info, blocks, mining
- **`BTx.RPC.Mining`** - Mining utilities
- **`BTx.RPC.RawTransactions`** - Transaction creation and signing
- **`BTx.RPC.Utils`** - Utility functions, validation, estimates
- **`BTx.RPC.Wallets`** - Wallet management, addresses, transactions

## 📚 Learn More

Ready to dive deeper? Check out our comprehensive guides:

**[📖 Getting Started Guide](docs/getting-started.md)** - Complete tutorial
with real examples

**[📋 API Documentation](http://hexdocs.pm/btx)** - Full API reference

## 🗺️ Roadmap

BTx is actively developed with an ambitious roadmap focused on building
comprehensive Bitcoin development tools:

| **Phase** | **Description** | **Status** |
|-----------|-----------------|------------|
| 🔌 **I** | Foundation layer providing complete Bitcoin Core JSON-RPC API coverage with type-safe requests and intelligent response parsing. | ⚠️ **In Progress** |
| 📋 **II** | High-level transaction builders, multi-signature support, fee optimization algorithms, and advanced signing workflows for complex transaction scenarios. | ❌ **Planned** |
| 🚧 **III** | Wallet utilities including backup/restore formats, address generation algorithms, balance calculation helpers, and transaction parsing/validation tools. | ❌ **Planned** |
| 📊 **IV** | Blockchain analysis tools including UTXO analysis algorithms, transaction graph building utilities, mempool monitoring helpers, and block parsing/validation tools. | ❌ **Planned** |
| 🧙 **V** | Advanced Bitcoin primitives including Lightning Network protocols, privacy features (CoinJoin), smart contract scripting, and custom Bitcoin protocol extensions. | ❌ **Planned** |

## ⚠️ Development Status

**Work in Progress**: `BTx` is currently in active development. While the core
JSON-RPC functionality is stable and well-tested, the API may evolve between
versions. Currently suitable for development and testing environments.

## 🤝 Contributing

Contributions are very welcome! Here's how you can help:

1. **Report Issues**: Use the [issue tracker](https://github.com/cabol/btx/issues)
   for bugs or feature requests
2. **Submit PRs**: Open [pull requests](https://github.com/cabol/btx/pulls)
   for improvements
3. **Run Tests**: Ensure `mix test.ci` passes before submitting
4. **Documentation**: Help improve docs and examples

### Development Setup
```bash
# Clone and setup
git clone https://github.com/cabol/btx.git
cd btx
mix deps.get

# Start Bitcoin regtest for testing
docker-compose up -d

# Run full test suite
mix test.ci
```

## 📄 Copyright and License

Copyright (c) 2025 Carlos Andres Bolaños R.A.

BTx source code is licensed under the [MIT License](LICENSE.md).
