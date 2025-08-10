defmodule BTx.RPC.Response do
  @moduledoc """
  Response from the JSON RPC API.
  """

  use Ecto.Schema

  import BTx.Helpers

  alias BTx.RPC.MethodError

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
  @spec new(Tesla.Env.t(), keyword()) ::
          {:ok, t()} | {:error, BTx.RPC.MethodError.t() | BTx.RPC.Error.t()}
  def new(response, meta \\ [])

  # Successful response
  def new(
        %Tesla.Env{
          status: 200,
          body: %{"error" => nil, "id" => id, "result" => result}
        },
        _meta
      ) do
    {:ok, %__MODULE__{id: id, result: result}}
  end

  # HTTP error
  def new(%Tesla.Env{status: status}, meta)
      when status in [400, 401, 403, 404, 405, 502, 503, 504] do
    wrap_error BTx.RPC.Error, [reason: http_reason(status), status: status] ++ meta
  end

  # HTTP 200, 500, or any other status with JSON-RPC error in body
  # This covers most Bitcoin Core application errors
  # (invalid params, insufficient funds, etc.)
  def new(
        %Tesla.Env{
          status: _,
          body: %{"result" => nil, "error" => %{"code" => code, "message" => message}} = body
        },
        meta
      ) do
    meta = [id: body["id"], code: code, message: message, reason: MethodError.reason(code)] ++ meta

    wrap_error MethodError, meta
  end

  # HTTP 500 - Internal Server Error (node is not running)
  def new(%Tesla.Env{status: 500}, meta) do
    wrap_error BTx.RPC.Error, [reason: http_reason(500), status: 500] ++ meta
  end

  # Fallback for any other unexpected cases
  def new(%Tesla.Env{status: status}, meta) do
    wrap_error BTx.RPC.Error, [reason: http_reason(status), status: status] ++ meta
  end

  @doc """
  Returns the HTTP reason for the given status code.
  """
  @spec http_reason(integer()) :: atom()
  def http_reason(status)

  def http_reason(400), do: :http_bad_request
  def http_reason(401), do: :http_unauthorized
  def http_reason(403), do: :http_forbidden
  def http_reason(404), do: :http_not_found
  def http_reason(405), do: :http_method_not_allowed
  def http_reason(500), do: :http_internal_server_error
  def http_reason(502), do: :http_bad_gateway
  def http_reason(503), do: :http_service_unavailable
  def http_reason(504), do: :http_gateway_timeout
  def http_reason(_), do: :unknown_error
end
