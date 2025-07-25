defmodule BTx.RPC.Response do
  @moduledoc """
  Response from the JSON RPC API.
  """

  use Ecto.Schema

  import BTx.Helpers

  @typedoc "Native type for the result field"
  @type native_type() :: number() | boolean() | String.t() | map() | nil

  @typedoc "Result type for the response"
  @type result() :: native_type() | [native_type()]

  @typedoc "Response from the JSON RPC API"
  @type t() :: %__MODULE__{id: String.t() | nil, result: result()}

  @derive BTx.json_encoder()
  @enforce_keys ~w(id)a
  defstruct id: nil, result: nil

  ## API

  @doc """
  Creates a new `Response` struct.
  """
  @spec new(Tesla.Env.t()) :: {:ok, t()} | {:error, BTx.RPC.MethodError.t() | BTx.RPC.Error.t()}
  def new(response)

  # Successful response
  def new(%Tesla.Env{status: 200, body: %{"error" => nil, "id" => id, "result" => result}}) do
    {:ok, %__MODULE__{id: id, result: result}}
  end

  # HTTP 400 - Bad Request (invalid request)
  def new(%Tesla.Env{status: 400}) do
    wrap_error BTx.RPC.Error, reason: {:rpc, :bad_request}
  end

  # HTTP 401 - Unauthorized (invalid credentials)
  def new(%Tesla.Env{status: 401}) do
    wrap_error BTx.RPC.Error, reason: {:rpc, :unauthorized}
  end

  # HTTP 403 - Forbidden (IP not allowed, access denied)
  def new(%Tesla.Env{status: 403}) do
    wrap_error BTx.RPC.Error, reason: {:rpc, :forbidden}
  end

  # HTTP 404 - Not Found (invalid endpoint)
  def new(%Tesla.Env{status: 404}) do
    wrap_error BTx.RPC.Error, reason: :not_found
  end

  # HTTP 405 - Method Not Allowed (wrong HTTP method, e.g., GET instead of POST)
  def new(%Tesla.Env{status: 405}) do
    wrap_error BTx.RPC.Error, reason: {:rpc, :method_not_allowed}
  end

  # HTTP 503 - Service Unavailable (node is starting, stopping, or overloaded)
  def new(%Tesla.Env{status: 503}) do
    wrap_error BTx.RPC.Error, reason: {:rpc, :service_unavailable}
  end

  # HTTP 200, 500, or any other status with JSON-RPC error in body
  # This covers most Bitcoin Core application errors
  # (invalid params, insufficient funds, etc.)
  def new(%Tesla.Env{
        status: _,
        body: %{"result" => nil, "error" => %{"code" => code, "message" => message}} = body
      }) do
    wrap_error BTx.RPC.MethodError, id: body["id"], code: code, message: message
  end

  # Fallback for any other unexpected cases
  def new(%Tesla.Env{status: status, body: body}) do
    wrap_error BTx.RPC.Error, reason: {:rpc, :unknown_error}, status: status, body: body
  end
end
