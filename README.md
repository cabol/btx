# ⚡₿𝕋𝕩
> Elixir library for Bitcoin.

![CI](http://github.com/cabol/btx/workflows/CI/badge.svg)
[![Codecov](http://codecov.io/gh/cabol/btx/graph/badge.svg)](http://codecov.io/gh/cabol/btx/graph/badge.svg)
[![Hex.pm](http://img.shields.io/hexpm/v/btx.svg)](http://hex.pm/packages/btx)
[![Documentation](http://img.shields.io/badge/Documentation-ff69b4)](http://hexdocs.pm/btx)

## About

**BTx** is a modern Elixir library for Bitcoin development, starting with a
powerful JSON-RPC client for Bitcoin Core. Designed for developers building
Bitcoin applications, `BTx` provides an idiomatic Elixir interface with plans
to expand into comprehensive Bitcoin tooling.

## Features

- **Full JSON-RPC Compliance**: Complete implementation of Bitcoin Core's
  JSON-RPC API.
- **Idiomatic Elixir Interface**: Clean, functional API that feels natural
  in Elixir applications.
- **Configurable Client**: Built on Tesla for flexible HTTP client
  configuration.
- **Automatic Encoding**: Bitcoin methods automatically encoded using Ecto
  embedded schemas.
- **Response Handling**: Intelligent response parsing and error handling.

## Installation

Add `btx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:btx, "~> 0.1.0"}
  ]
end
```

## Quick Start

The first step is to ensure that you have a Bitcoin node running locally.
You can use the `docker-compose.yml` file in the repo to spin up the Bitcoin
node (running in `regtest` mode), like so:

```shell
docker-compose up -d
```

Now we can start using the JSON RPC API. Let's create a wallet:

```elixir
iex> BTx.JRPC.client(
...>   base_url: "http://127.0.0.1:18443",
...>   username: "btx-user",
...>   password: "btx-pass"
...> )
...> |> BTx.JRPC.call!(BTx.JRPC.Wallet.CreateWallet.new!(
...>   wallet_name: "btx-wallet",
...>   passphrase: "btx-pass",
...>   avoid_reuse: true,
...>   descriptors: true
...> ))
%BTx.JRPC.Response{
  id: "btx-9cdb7b45-2dc0-4f2e-8d7b-664a03482ca1",
  result: %{"name" => "btx-wallet"}
}
```

## Roadmap

BTx is under active development with plans to expand beyond JSON-RPC:

- **Phase 1** (Current): Complete JSON-RPC client implementation
- **Phase 2**: Wallet management utilities
- **Phase 3**: Transaction building and signing
- **Phase 4**: Blockchain analysis and utilities
- **Phase 5**: Advanced Bitcoin primitives

## Development Status

⚠️ **Work in Progress**: `BTx` is currently under active development. While the
core JSON-RPC functionality is being implemented, the API may change between
versions. Not recommended for production use yet.

## Contributing

We welcome contributions! Please feel free to submit issues, feature requests,
or pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Copyright and License

Copyright (c) 2025 Carlos Andres Bolaños R.A.

Nebulex source code is licensed under the [MIT License](LICENSE).
