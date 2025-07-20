defmodule BTx.JRPC do
  @moduledoc """
  JSON RPC client for Bitcoin.

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
  Calls the JSON RPC API with the given method.
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
  Calls the JSON RPC API with the given method.
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
