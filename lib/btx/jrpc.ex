defmodule BTx.JRPC do
  @moduledoc """
  JSON RPC client for Bitcoin.
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
  def call(client, %_t{} = method, opts \\ []) do
    # Validate options
    opts = Options.validate_rpc_opts!(opts)

    # Extract options
    {id, opts} = Keyword.pop(opts, :id)
    {path, opts} = Keyword.pop(opts, :path)

    # Encode method and add ID if provided
    request = Encodable.encode(method)
    request = if id, do: %{request | id: id}, else: request

    case Tesla.post(client, path || request.path, request, opts: opts) do
      {:ok, %Tesla.Env{} = response} ->
        Response.new(response)

      {:error, reason} ->
        wrap_error BTx.JRPC.Error, reason: reason, method: method
    end
  end

  @doc """
  Calls the JSON RPC API with the given method.
  """
  @spec call!(client(), Encodable.t(), keyword()) :: Response.t()
  def call!(client, %_t{} = method, opts \\ []) do
    case call(client, method, opts) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end
end
