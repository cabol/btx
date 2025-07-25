defmodule BTx.RPC.Error do
  @moduledoc """
  Error returned when a JSON RPC request fails.

  ## Error reasons

  The `:reason` field can assume the following values:

    * `{:rpc, status}` - RPC error.
      * `:bad_request` - if the request is invalid.
      * `:unauthorized` - if the RPC credentials are missing or incorrect.
      * `:forbidden` - if access is denied (IP not allowed, etc.).
      * `:not_found` - if the RPC endpoint doesn't exist.
      * `:method_not_allowed` - if the wrong HTTP method is used (e.g., GET instead of POST).
      * `:service_unavailable` - if Bitcoin Core is starting, stopping, or overloaded.
      * `:unknown_error` - for unexpected error conditions.

    * `t:Exception.t/0` - if the underlying adapter fails due to an exception.

    * `t:any/0` - any other error.

  """

  @typedoc """
  The type for this exception struct.

  This exception has the following public fields:

    * `:reason` - the error reason.

    * `:metadata` - the metadata contains the options given to the exception
      excluding the `:reason` that is part of the exception fields. For example,
      in `raise BTx.RPC.Error, reason: :test, foo: :bar`, the metadata will be
      `[foo: :bar]`.

  """
  @type t() :: %__MODULE__{reason: any(), metadata: keyword()}

  # Exception struct
  defexception reason: nil, metadata: []

  ## Callbacks

  @impl true
  def exception(opts) do
    {reason, opts} = Keyword.pop!(opts, :reason)

    %__MODULE__{reason: reason, metadata: opts}
  end

  @impl true
  def message(%__MODULE__{reason: reason, metadata: metadata}) do
    format_error(reason, metadata)
  end

  ## Helpers

  defp format_error({:rpc, :bad_request}, _metadata) do
    "Bad Request: The request is invalid. " <>
      "Please check the request parameters and ensure they are correct."
  end

  defp format_error({:rpc, :unauthorized}, _metadata) do
    "Unauthorized: RPC credentials are missing or incorrect. " <>
      "Please check your Bitcoin Core `rpcuser` and `rpcpassword` configuration."
  end

  defp format_error({:rpc, :forbidden}, _metadata) do
    "Forbidden: Access denied to Bitcoin Core RPC. " <>
      "This usually means your IP address is not in the `rpcallowip` list or " <>
      "other access restrictions are in place. Check your Bitcoin Core configuration."
  end

  defp format_error({:rpc, :not_found}, _metadata) do
    "Not Found: The RPC endpoint does not exist. " <>
      "Please check the URL and ensure Bitcoin Core is running with RPC enabled."
  end

  defp format_error({:rpc, :method_not_allowed}, _metadata) do
    "Method Not Allowed: Invalid HTTP method used for RPC request. " <>
      "Bitcoin Core RPC requires POST requests with JSON-RPC payload."
  end

  defp format_error({:rpc, :service_unavailable}, _metadata) do
    "Service Unavailable: Bitcoin Core RPC service is temporarily unavailable. " <>
      "This can happen during startup, shutdown, or when the node is overloaded. " <>
      "Please wait and retry."
  end

  defp format_error({:rpc, :unknown_error}, metadata) do
    "Unknown Error: An unexpected error occurred during RPC communication."
    |> maybe_format_metadata(metadata)
  end

  defp format_error(exception, metadata) when is_exception(exception) do
    {stacktrace, metadata} = Keyword.pop(metadata, :stacktrace, [])

    """
    the following exception occurred when executing a command.

        #{Exception.format(:error, exception, stacktrace) |> String.replace("\n", "\n    ")}
    """
    |> maybe_format_metadata(metadata)
  end

  defp format_error(reason, metadata) do
    "JSON RPC request failed with reason: #{inspect(reason)}"
    |> maybe_format_metadata(metadata)
  end

  defp maybe_format_metadata(msg, metadata) do
    if Enum.count(metadata) > 0 do
      """
      #{msg}

      Error metadata:

      #{inspect(metadata)}
      """
    else
      msg
    end
  end
end

defmodule BTx.RPC.MethodError do
  @moduledoc """
  Error returned when a JSON RPC method cannot be executed.
  """

  @typedoc """
  The type for this exception struct.
  """
  @type t() :: %__MODULE__{id: String.t(), code: integer(), message: String.t()}

  # Exception struct
  defexception [:id, :code, :message]

  ## Callbacks

  @impl true
  def exception(opts) do
    id = Keyword.fetch!(opts, :id)
    code = Keyword.fetch!(opts, :code)
    message = Keyword.fetch!(opts, :message)

    %__MODULE__{id: id, code: code, message: message}
  end

  @impl true
  def message(%__MODULE__{message: message}) do
    message
  end
end
