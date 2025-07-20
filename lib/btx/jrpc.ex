defmodule BTx.JRPC do
  @moduledoc """
  A JSON-RPC client for Bitcoin Core.

  This module provides a high-level interface for communicating with Bitcoin
  Core's JSON-RPC API. It handles connection management, request encoding,
  response parsing, and error handling.

  ## Features

  - **Type-safe requests** - Uses Ecto schemas for request validation.
  - **Comprehensive error handling** - Detailed error types for different
    failure modes.
  - **Wallet support** - Automatic wallet-specific endpoint routing.
  - **Telemetry integration** - Built-in metrics and monitoring.
  - **Tesla-based** - Flexible HTTP client with adapter support.
  - **Configurable** - Support for different environments and connection
    options.

  ## Quick Start

      # Create a client
      client = BTx.JRPC.client(
        base_url: "http://localhost:8332",
        username: "bitcoinrpc",
        password: "your_password"
      )

      # Create and send a request
      request = BTx.JRPC.Wallets.CreateWallet.new!(
        wallet_name: "my_wallet",
        passphrase: "secure_password"
      )

      # Make the call
      case BTx.JRPC.call(client, request) do
        {:ok, response} ->
          IO.puts("Wallet created: \#{response.result["name"]}")
        {:error, error} ->
          IO.puts("Error: \#{Exception.message(error)}")
      end

  ## Request Types

  All request objects must implement the `BTx.JRPC.Encodable` protocol.
  The requests are grouped by context, and the context exposes related
  functions. For example, the `BTx.JRPC.Wallets` context exposes functions
  to create and manage wallets.

  For more information please check:

  - **Wallet Operations**: `BTx.JRPC.Wallets`.
  - **More coming soon**: Blockchain, network, and mining operations.

  ## Telemetry

  This module uses Telemetry to track the performance of the JSON RPC API.

  #### `[:btx, :jrpc, :call, :start]`

  This event is emitted before a JSON RPC API call is executed.

  The `:measurements` map will include the following:

    * `:system_time` - The current system time in native units from calling:
      `System.system_time()`.

  A Telemetry `:metadata` map including the following fields:

    * `:client` - The Tesla client.
    * `:method` - The name of the method.
    * `:method_object` - The method object.
    * `:id` - The ID of the request.
    * `:path` - The path of the request.

  Example event data:

      %{
        measurements: %{system_time: 1_678_123_456_789},
        metadata: %{
          id: "1234567890",
          path: "/wallet/my-wallet-name",
          client: %Tesla.Client{},
          method: "getnewaddress",
          method_object: %BTx.JRPC.Wallets.GetNewAddress{
            method: "getnewaddress",
            wallet_name: "btx-test-wallet",
            label: "test-label",
            address_type: "bech32"
          }
        }
      }

   #### `[:btx, :jrpc, :call, :stop]`

  This event is emitted after a JSON RPC API call is executed.

  The `:measurements` map will include the following:

    * `:duration` - The time spent executing the cache command. The measurement
      is given in the `:native` time unit. You can read more about it in the
      docs for `System.convert_time_unit/3`.

  A Telemetry `:metadata` map including the following fields:

    * `:client` - The Tesla client.
    * `:method` - The name of the method.
    * `:method_object` - The method object.
    * `:id` - The ID of the request.
    * `:path` - The path of the request.
    * `:status` - The status of the call: `:ok` or `:error`.
    * `:result` - The command's result.

  Example event data:

      %{
        measurements: %{duration: 1_234_567},
        metadata: %{
          id: "1234567890",
          path: "/wallet/my-wallet-name",
          client: %Tesla.Client{},
          method: "getnewaddress",
          method_object: %BTx.JRPC.Wallets.GetNewAddress{
            method: "getnewaddress",
            wallet_name: "btx-test-wallet",
            label: "test-label",
            address_type: "bech32"
          },
          status: :ok,
          result: %BTx.JRPC.Response{...}
        }
      }

  #### `[:btx, :jrpc, :call, :exception]`

  This event is emitted when an error or exception occurs during the
  JSON RPC API call.

  The `:measurements` map will include the following:

    * `:duration` - The time spent executing the cache command. The measurement
      is given in the `:native` time unit. You can read more about it in the
      docs for `System.convert_time_unit/3`.

  A Telemetry `:metadata` map including the following fields:

    * `:client` - The Tesla client.
    * `:method` - The name of the method.
    * `:method_object` - The method object.
    * `:id` - The ID of the request.
    * `:path` - The path of the request.
    * `:status` - The status of the call: `:ok` or `:error`.
    * `:reason` - The reason of the error.
    * `:stacktrace` - Exception's stack trace.
    * `:kind` - The type of the error: `:error`, `:exit`, or `:throw`.
    * `:reason` - The reason of the error.
    * `:stacktrace` - Exception's stack trace.

  Example event data:

      %{
        measurements: %{duration: 1_234_567},
        metadata: %{
          id: "1234567890",
          path: "/wallet/my-wallet-name",
          client: %Tesla.Client{},
          method: "getnewaddress",
          method_object: %BTx.JRPC.Wallets.GetNewAddress{
            method: "getnewaddress",
            wallet_name: "btx-test-wallet",
            label: "test-label",
            address_type: "bech32"
          },
          status: :error,
          kind: :error,
          reason: %RuntimeError{message: "unexpected error"},
          stacktrace: [...]
        }
      }

  """

  import BTx.Helpers

  alias BTx.JRPC.{Encodable, Options, Response}

  @typedoc "Proxy type for a Tesla client"
  @type client() :: Tesla.Client.t()

  @typedoc "Response from the JSON RPC API"
  @type rpc_response() ::
          {:ok, BTx.JRPC.Response.t()}
          | {:error, BTx.JRPC.MethodError.t() | BTx.JRPC.Error.t()}

  ## API

  @doc """
  Creates a Tesla client for the Bitcoin JSON RPC API.

  ## Options

  #{Options.client_opts_docs()}

  ## Example

      client = BTx.JRPC.client(
        base_url: "http://localhost:18443",      # Bitcoin Core RPC endpoint
        username: "btx-user",                    # RPC username
        password: "btx-pass",                    # RPC password
        headers: [{"user-agent", "my-app/1.0"}], # Additional headers
        adapter: {Tesla.Adapter.Finch, name: MyFinch} # HTTP adapter
      )

  """
  @spec client(keyword()) :: client()
  def client(opts \\ []) do
    # Validate options
    opts = Options.validate_client_opts!(opts)

    # Extract options
    adapter = Keyword.fetch!(opts, :adapter)
    base_url = Keyword.fetch!(opts, :base_url)
    username = Keyword.fetch!(opts, :username)
    password = Keyword.fetch!(opts, :password)
    headers = Keyword.fetch!(opts, :headers)

    # Create Tesla client
    Tesla.client(
      [
        # Set the base URL
        {Tesla.Middleware.BaseUrl, base_url},
        # Add headers
        {Tesla.Middleware.Headers, headers},
        # Set the basic auth
        {Tesla.Middleware.BasicAuth, %{username: username, password: password}},
        # Set the JSON engine
        {Tesla.Middleware.JSON, engine: BTx.json_module()}
      ],
      adapter
    )
  end

  @doc """
  Executes a JSON-RPC request against Bitcoin Core.

  This function encodes the request, sends it to Bitcoin Core via HTTP, and
  parses the response. It automatically handles wallet routing, error parsing,
  request validation, and telemetry emission.

  ## Arguments

  - `client` - A Tesla client created with `client/1`.
  - `method_object` - A request struct implementing the `BTx.JRPC.Encodable`
    protocol.
  - `opts` - Optional RPC-specific configuration (see Options below).

  ## Options

  #{Options.rpc_opts_docs()}

  ## Returns

  - `{:ok, BTx.JRPC.Response.t()}` - Successful response containing:
    - `id` - The request ID (auto-generated or custom)
    - `result` - The RPC method result data

  - `{:error, BTx.JRPC.MethodError.t()}` - Bitcoin Core RPC error containing:
    - `id` - The request ID
    - `code` - Bitcoin Core error code (e.g., -4 for wallet exists)
    - `message` - Human-readable error description

  - `{:error, BTx.JRPC.Error.t()}` - HTTP/network/parsing error containing:
    - `reason` - Error type (`{:rpc, :unauthorized}`, etc.)
    - `metadata` - Additional error context

  ## Examples

  ### Basic Usage

      # Create a request
      request = BTx.JRPC.Wallets.GetNewAddress.new!(
        label: "Customer Payment",
        address_type: "bech32"
      )

      # Execute the call
      case BTx.JRPC.call(client, request) do
        {:ok, response} ->
          address = response.result
          IO.puts("Generated address: \#{address}")

        {:error, error} ->
          IO.puts("Failed to generate address: \#{Exception.message(error)}")
      end

  ### Custom Request ID

      request = BTx.JRPC.Wallets.CreateWallet.new!(
        wallet_name: "my_wallet",
        passphrase: "secure_password"
      )

      {:ok, response} = BTx.JRPC.call(client, request, id: "create-wallet-001")
      assert response.id == "create-wallet-001"

  ### Comprehensive Error Handling

      case BTx.JRPC.call(client, create_wallet_request) do
        {:ok, response} ->
          Logger.info("Wallet created: \#{response.result["name"]}")
          {:ok, response.result}

        # Bitcoin Core RPC errors
        {:error, %BTx.JRPC.MethodError{code: -4, message: message}} ->
          Logger.warn("Wallet already exists: \#{message}")
          {:error, :wallet_exists}

        {:error, %BTx.JRPC.MethodError{code: -8, message: message}} ->
          Logger.error("Invalid parameters: \#{message}")
          {:error, :invalid_params}

        {:error, %BTx.JRPC.MethodError{code: -18, message: message}} ->
          Logger.error("Wallet not loaded: \#{message}")
          {:error, :wallet_not_loaded}

        # HTTP/Network errors
        {:error, %BTx.JRPC.Error{reason: {:rpc, :unauthorized}}} ->
          Logger.error("Authentication failed - check RPC credentials")
          {:error, :auth_failed}

        {:error, %BTx.JRPC.Error{reason: {:rpc, :service_unavailable}}} ->
          Logger.warn("Bitcoin Core temporarily unavailable")
          {:error, :service_unavailable}

        {:error, %BTx.JRPC.Error{reason: {:rpc, :forbidden}}} ->
          Logger.error("Access denied - check IP allowlist")
          {:error, :access_denied}

        {:error, %BTx.JRPC.Error{reason: :econnrefused}} ->
          Logger.error("Connection refused - is Bitcoin Core running?")
          {:error, :connection_refused}

        {:error, %BTx.JRPC.Error{reason: :timeout}} ->
          Logger.error("Request timed out")
          {:error, :timeout}

        {:error, error} ->
          Logger.error("Unexpected error: \#{Exception.message(error)}")
          {:error, :unknown}
      end

  > #### `call` function usage {: .warning}
  >
  > The `call` function is a generic JSON-RPC method that can execute any
  > Bitcoin Core RPC command. While it provides maximum flexibility for calling
  > any Bitcoin Core API method, it is highly recommended to use the specific
  > context modules instead (such as `BTx.JRPC.Wallets`, `BTx.JRPC.Blockchain`,
  > etc.) whenever possible.
  >
  > **Why use context modules?**
  >
  > - **Type safety**: Context modules use Ecto embedded schemas for automatic
  >   encoding.
  > - **Clearer intent**: Makes your code more self-documenting.
  >
  > **When to use call:**
  >
  > - Testing new Bitcoin Core RPC methods not yet implemented in BTx.
  > - Dynamic method execution scenarios.
  > - Debugging or experimental Bitcoin Core features.
  >
  > Reserve `call` for cases where no appropriate context module exists, or when
  > you need to execute RPC methods dynamically at runtime.
  """
  @spec call(client(), Encodable.t(), keyword()) :: rpc_response()
  def call(client, %_t{method: method} = method_object, opts \\ []) do
    # Validate options
    opts = Options.validate_rpc_opts!(opts)

    # Extract options
    {id, opts} = Keyword.pop(opts, :id)
    {path, opts} = Keyword.pop(opts, :path)

    # Encode method and add ID if provided
    request = Encodable.encode(method_object)
    request = if id, do: %{request | id: id}, else: request

    # Resolve the path
    path = path || request.path

    metadata = %{
      client: client,
      method: method,
      method_object: method_object,
      id: request.id,
      path: path
    }

    :telemetry.span([:btx, :jrpc, :call], metadata, fn ->
      client
      |> Tesla.post(path, request, opts: opts)
      |> case do
        {:ok, %Tesla.Env{} = response} ->
          Response.new(response)

        {:error, reason} ->
          wrap_error BTx.JRPC.Error, reason: reason, method: method, method_object: method_object
      end
      |> handle_response(metadata)
    end)
  end

  @doc """
  Same as `call/3` but raises an error if the call fails.
  """
  @spec call!(client(), Encodable.t(), keyword()) :: Response.t()
  def call!(client, method, opts \\ []) do
    case call(client, method, opts) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end

  ## Private functions

  defp handle_response({:ok, response} = ok, metadata) do
    {ok, Map.merge(metadata, %{status: :ok, result: response})}
  end

  defp handle_response({:error, reason} = error, metadata) do
    {error, Map.merge(metadata, %{status: :error, reason: reason})}
  end
end
