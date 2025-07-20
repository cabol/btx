defmodule BTx do
  @moduledoc """
  Bitcoin Toolkit for Elixir.

  BTx is a modern Elixir library for Bitcoin development, providing an idiomatic
  interface for interacting with Bitcoin Core through its JSON-RPC API. Designed
  for developers building Bitcoin applications, BTx offers clean, functional
  APIs with comprehensive Bitcoin tooling capabilities.

  ## Features

    * **Full JSON-RPC Compliance** - Complete implementation of Bitcoin Core's
      JSON-RPC API.
    * **Idiomatic Elixir Interface** - Clean, functional API that feels natural
      in Elixir.
    * **Automatic Encoding** - Bitcoin methods automatically encoded using Ecto
      embedded schemas.
    * **Intelligent Response Handling** - Smart response parsing and error
      handling.
    * **Configurable Client** - Built on Tesla for flexible HTTP client
      configuration.

  ## Quick Start

  Create a client and make your first call:

      client = BTx.JRPC.client(
        base_url: "http://127.0.0.1:18443",
        username: "btx-user",
        password: "btx-pass"
      )

      BTx.JRPC.Wallets.create_wallet!(client,
        wallet_name: "my-wallet",
        descriptors: true
      )

  ## Main Modules

    * `BTx.JRPC` - JSON-RPC client and core functionality.
    * `BTx.JRPC.Wallets` - Wallet-specific RPC methods.

  See individual module documentation for detailed examples and usage patterns.

  ## Development Status

  **BTx** is under active development with plans to expand beyond JSON-RPC into
  comprehensive Bitcoin tooling including wallet management, transaction
  building, and blockchain analysis utilities.
  """

  ## API

  # Inline common instructions
  @compile {:inline, json_module: 0}

  @doc """
  Returns the JSON module to use for encoding and decoding JSON.
  """
  @spec json_module() :: module()
  if Code.ensure_loaded?(JSON) do
    def json_module, do: JSON

    def json_encoder, do: JSON.Encoder
  else
    def json_module, do: Jason

    def json_encoder, do: Jason.Encoder
  end
end
