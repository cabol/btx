defmodule BTx.RPC do
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
      client = BTx.RPC.client(
        base_url: "http://localhost:8332",
        username: "bitcoinrpc",
        password: "your_password"
      )

      # Create and send a request
      request = BTx.RPC.Wallets.CreateWallet.new!(
        wallet_name: "my_wallet",
        passphrase: "secure_password"
      )

      # Make the call
      case BTx.RPC.call(client, request) do
        {:ok, response} ->
          IO.puts("Wallet created: \#{response.result["name"]}")
        {:error, error} ->
          IO.puts("Error: \#{Exception.message(error)}")
      end

  ## Request Types

  All request objects must implement the `BTx.RPC.Encodable` protocol.
  The requests are grouped by context, and the context exposes related
  functions. For example, the `BTx.RPC.Wallets` context exposes functions
  to create and manage wallets.

  For more information please check:

  - **Wallet Operations**: `BTx.RPC.Wallets`.
  - **More coming soon**: Blockchain, network, and mining operations.

  ## Telemetry

  This module uses Telemetry to track the performance of the JSON RPC API.

  #### `[:btx, :rpc, :call, :start]`

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
          method_object: %BTx.RPC.Wallets.GetNewAddress{
            method: "getnewaddress",
            wallet_name: "btx-test-wallet",
            label: "test-label",
            address_type: "bech32"
          }
        }
      }

   #### `[:btx, :rpc, :call, :stop]`

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
          method_object: %BTx.RPC.Wallets.GetNewAddress{
            method: "getnewaddress",
            wallet_name: "btx-test-wallet",
            label: "test-label",
            address_type: "bech32"
          },
          status: :ok,
          result: %BTx.RPC.Response{...}
        }
      }

  #### `[:btx, :rpc, :call, :exception]`

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
          method_object: %BTx.RPC.Wallets.GetNewAddress{
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

  alias BTx.RPC.{Encodable, Options, Response}

  @typedoc "Proxy type for a Tesla client"
  @type client() :: Tesla.Client.t()

  @typedoc "Error from the JSON RPC API"
  @type rpc_error() :: {:error, BTx.RPC.MethodError.t() | BTx.RPC.Error.t()}

  @typedoc "Response from the JSON RPC API"
  @type rpc_response() :: {:ok, BTx.RPC.Response.t()} | rpc_error()

  # Default retryable errors
  @default_retryable_errors ~w(http_internal_server_error
                               http_service_unavailable
                               http_bad_gateway
                               http_gateway_timeout)a

  # Inline common instructions
  @compile {:inline, default_retryable_errors: 0}

  ## API

  @doc """
  Creates a Tesla client for the Bitcoin JSON RPC API.

  ## Options

  #{Options.client_opts_docs()}

  ## Example

      client = BTx.RPC.client(
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
    default_opts = Keyword.fetch!(opts, :default_opts)

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
        {Tesla.Middleware.JSON, engine: BTx.json_module()},
        # Set the default options
        {Tesla.Middleware.Opts, default_opts}
      ]
      # Maybe add the retry middleware
      |> maybe_add_retry_middleware(opts)
      # Maybe add the timeout middleware
      |> maybe_add_timeout_middleware(opts),
      # Set the adapter
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
  - `method_object` - A request struct implementing the `BTx.RPC.Encodable`
    protocol.
  - `opts` - Optional RPC-specific configuration (see Options below).

  ## RPC Options

  #{Options.rpc_opts_docs()}

  ## Adapter Options

  In addition to the RPC-specific options above, this function also accepts all
  options supported by the underlying Tesla adapter. These options are passed
  through directly to the adapter.

  For example, when using `Tesla.Adapter.Finch`, you can pass any options
  supported by `Finch.request/3`, such as:

  - `:receive_timeout` - Request timeout in milliseconds.
  - `:pool_timeout` - Pool checkout timeout in milliseconds.
  - `:request_timeout` - Overall request timeout in milliseconds.

  When using `Tesla.Adapter.Hackney`, you can pass options like:

  - `:timeout` - Request timeout in milliseconds.
  - `:recv_timeout` - Receive timeout in milliseconds.
  - `:connect_timeout` - Connection timeout in milliseconds.

  These adapter-specific options provide fine-grained control over HTTP behavior
  and timeouts, complementing the RPC retry and error handling mechanisms.

  ## Returns

  - `{:ok, BTx.RPC.Response.t()}` - Successful response containing:
    - `id` - The request ID (auto-generated or custom)
    - `result` - The RPC method result data

  - `{:error, BTx.RPC.MethodError.t()}` - Bitcoin Core RPC error containing:
    - `id` - The request ID
    - `code` - Bitcoin Core error code (e.g., -4 for wallet exists)
    - `reason` - Bitcoin Core error reason (e.g., `:wallet_error` for wallet exists).
    - `message` - Human-readable error description

  - `{:error, BTx.RPC.Error.t()}` - HTTP/network/parsing error containing:
    - `reason` - Error type (`:http_unauthorized`, etc.)
    - `metadata` - Additional error context

  ## Examples

  ### Basic Usage

      # Create a request
      request = BTx.RPC.Wallets.GetNewAddress.new!(
        label: "Customer Payment",
        address_type: "bech32"
      )

      # Execute the call
      case BTx.RPC.call(client, request) do
        {:ok, response} ->
          address = response.result
          IO.puts("Generated address: \#{address}")

        {:error, error} ->
          IO.puts("Failed to generate address: \#{Exception.message(error)}")
      end

  ### Custom Request ID

      request = BTx.RPC.Wallets.CreateWallet.new!(
        wallet_name: "my_wallet",
        passphrase: "secure_password"
      )

      {:ok, response} = BTx.RPC.call(client, request, id: "create-wallet-001")
      assert response.id == "create-wallet-001"

  ### Comprehensive Error Handling

      case BTx.RPC.call(client, create_wallet_request) do
        {:ok, response} ->
          Logger.info("Wallet created: \#{response.result["name"]}")
          {:ok, response.result}

        # Bitcoin Core RPC errors
        {:error, %BTx.RPC.MethodError{reason: reason, message: message}} ->
          Logger.error("Method error (\#{reason}): \#{message}")
          {:error, :method_error}

        # HTTP/Network errors
        {:error, %BTx.RPC.Error{} = reason} ->
          reason |> Exception.message() |> Logger.error()
          {:error, :http_error}
      end

  > #### `call` function usage {: .warning}
  >
  > The `call` function is a generic JSON-RPC method that can execute any
  > Bitcoin Core RPC command. While it provides maximum flexibility for calling
  > any Bitcoin Core API method, it is highly recommended to use the specific
  > context modules instead (such as `BTx.RPC.Wallets`, `BTx.RPC.Blockchain`,
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

    :telemetry.span([:btx, :rpc, :call], metadata, fn ->
      client
      |> post(path, request, opts, method: method, id: id, path: path)
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

  @doc """
  Returns the default retryable errors.
  """
  @spec default_retryable_errors() :: [atom()]
  def default_retryable_errors, do: @default_retryable_errors

  @doc """
  Default retry function for `Tesla.Middleware.Retry`.

  It retries on the following conditions:

  - If the response is an error and the reason is within the default retryable
    errors.
  - In the case of connection errors (`nxdomain`, `connrefused`, etc).

  """
  @spec should_retry?(Tesla.Env.result(), Tesla.Env.t(), any()) :: boolean()
  def should_retry?(env, env, context)

  def should_retry?({:ok, %Tesla.Env{} = env}, _env, _context) do
    case Response.new(env) do
      {:error, %BTx.RPC.Error{reason: reason}} ->
        Enum.member?(@default_retryable_errors, reason)

      _else ->
        false
    end
  end

  def should_retry?({:error, _reason}, _env, _context) do
    true
  end

  ## Private functions

  defp maybe_add_retry_middleware(middleware, opts) do
    # If automatic retry is enabled, add the retry middleware
    if Keyword.fetch!(opts, :automatic_retry) do
      # Build the retry options
      retry_opts =
        opts
        |> Keyword.fetch!(:retry_opts)
        |> Keyword.put_new_lazy(:should_retry, fn -> &__MODULE__.should_retry?/3 end)

      [{Tesla.Middleware.Retry, retry_opts} | middleware]
    else
      # Skip the retry middleware
      middleware
    end
  end

  defp maybe_add_timeout_middleware(middleware, opts) do
    # If async opts are provided, add the timeout middleware
    if async_opts = Keyword.get(opts, :async_opts) do
      # Add the timeout middleware
      [{Tesla.Middleware.Timeout, async_opts} | middleware]
    else
      # Skip the timeout middleware
      middleware
    end
  end

  defp post(client, path, request, opts, meta) do
    client
    |> Tesla.post(path, request, opts: opts)
    |> case do
      {:ok, %Tesla.Env{} = response} ->
        Response.new(response, meta)

      {:error, reason} ->
        wrap_error BTx.RPC.Error, [reason: reason] ++ meta
    end
  end

  defp handle_response({:ok, response} = ok, metadata) do
    {ok, Map.merge(metadata, %{status: :ok, result: response})}
  end

  defp handle_response({:error, reason} = error, metadata) do
    {error, Map.merge(metadata, %{status: :error, reason: reason})}
  end
end
