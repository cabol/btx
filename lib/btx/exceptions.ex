defmodule BTx.RPC.Error do
  @moduledoc """
  Error returned when a JSON RPC request fails.

  ## Error reasons

  The `:reason` field can assume the following values:

    * `:bad_request` - if the request is invalid.
    * `:unauthorized` - if the RPC credentials are missing or incorrect.
    * `:forbidden` - if access is denied (IP not allowed, etc.).
    * `:not_found` - if the RPC endpoint doesn't exist.
    * `:method_not_allowed` - if the wrong HTTP method is used (e.g., GET instead of POST).
    * `:internal_server_error` - if Bitcoin Core is not running.
    * `:bad_gateway` - if Bitcoin Core is overloaded.
    * `:service_unavailable` - if Bitcoin Core is starting, stopping, or overloaded.
    * `:gateway_timeout` - if Bitcoin Core is taking too long to respond.
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

  defp format_error(:http_bad_request, metadata) do
    ("Bad Request: The request is invalid. " <>
       "Please check the request parameters and ensure they are correct.")
    |> maybe_format_metadata(metadata)
  end

  defp format_error(:http_unauthorized, metadata) do
    ("Unauthorized: RPC credentials are missing or incorrect. " <>
       "Please check your Bitcoin Core `rpcuser` and `rpcpassword` configuration.")
    |> maybe_format_metadata(metadata)
  end

  defp format_error(:http_forbidden, metadata) do
    ("Forbidden: Access denied to Bitcoin Core RPC. " <>
       "This usually means your IP address is not in the `rpcallowip` list or " <>
       "other access restrictions are in place. Check your Bitcoin Core configuration.")
    |> maybe_format_metadata(metadata)
  end

  defp format_error(:http_not_found, metadata) do
    ("Not Found: The RPC endpoint does not exist. " <>
       "Please check the URL and ensure Bitcoin Core is running with RPC enabled.")
    |> maybe_format_metadata(metadata)
  end

  defp format_error(:http_method_not_allowed, metadata) do
    ("Method Not Allowed: Invalid HTTP method used for RPC request. " <>
       "Bitcoin Core RPC requires POST requests with JSON-RPC payload.")
    |> maybe_format_metadata(metadata)
  end

  defp format_error(:http_internal_server_error, metadata) do
    ("Internal Server Error: Bitcoin Core is not running. " <>
       "Please check if Bitcoin Core is running and try again.")
    |> maybe_format_metadata(metadata)
  end

  defp format_error(:http_bad_gateway, metadata) do
    ("Bad Gateway: Bitcoin Core is overloaded. " <>
       "Please try again later or check if Bitcoin Core is running.")
    |> maybe_format_metadata(metadata)
  end

  defp format_error(:http_service_unavailable, metadata) do
    ("Service Unavailable: Bitcoin Core RPC service is temporarily unavailable. " <>
       "This can happen during startup, shutdown, or when the node is overloaded. " <>
       "Please wait and retry.")
    |> maybe_format_metadata(metadata)
  end

  defp format_error(:http_gateway_timeout, metadata) do
    ("Gateway Timeout: Bitcoin Core is taking too long to respond. " <>
       "Please check if Bitcoin Core is running and try again.")
    |> maybe_format_metadata(metadata)
  end

  defp format_error(:unknown_error, metadata) do
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

  # :ssl.format_error/1 falls back to :inet.format_error/1 when the error is not
  # an SSL-specific error (at least since OTP 19+), so we can just use that.
  defp format_error(reason, metadata) do
    case :ssl.format_error(reason) do
      ~c"Unexpected error:" ++ _ ->
        "JSON RPC request failed with reason: #{inspect(reason)}"

      message ->
        "JSON RPC request failed with reason: " <> List.to_string(message)
    end
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
  @type t() :: %__MODULE__{id: String.t(), code: integer(), reason: atom(), message: String.t()}

  # Exception struct
  defexception [:id, :code, :reason, :message]

  ## Callbacks

  @impl true
  def exception(opts) do
    id = Keyword.fetch!(opts, :id)
    code = Keyword.fetch!(opts, :code)
    reason = Keyword.fetch!(opts, :reason)
    message = Keyword.fetch!(opts, :message)

    %__MODULE__{id: id, code: code, reason: reason, message: message}
  end

  @impl true
  def message(%__MODULE__{message: message}) do
    message
  end

  ## Public API

  @doc """
  Maps a Bitcoin Core error code to its corresponding reason atom.

  [Bitcoin Core error codes](https://github.com/bitcoin/bitcoin/blob/master/src/rpc/protocol.h#L100)

  ## Examples

      iex> BTx.RPC.MethodError.reason(-6)
      :wallet_insufficient_funds

      iex> BTx.RPC.MethodError.reason(-18)
      :wallet_not_found

      iex> BTx.RPC.MethodError.reason(-32_602)
      :invalid_params

  """
  @spec reason(integer()) :: atom()
  def reason(code)

  # Standard JSON-RPC 2.0 errors
  def reason(-32_600), do: :invalid_request
  def reason(-32_601), do: :method_not_found
  def reason(-32_602), do: :invalid_params
  def reason(-32_603), do: :internal_error
  def reason(-32_700), do: :parse_error

  # General application defined errors
  def reason(-1), do: :misc_error
  def reason(-3), do: :type_error
  def reason(-5), do: :invalid_address_or_key
  def reason(-7), do: :out_of_memory
  def reason(-8), do: :invalid_parameter
  def reason(-20), do: :database_error
  def reason(-22), do: :deserialization_error
  def reason(-25), do: :verify_error
  def reason(-26), do: :verify_rejected
  def reason(-27), do: :verify_already_in_utxo_set
  def reason(-28), do: :in_warmup
  def reason(-32), do: :method_deprecated

  # P2P client errors
  def reason(-9), do: :client_not_connected
  def reason(-10), do: :client_in_initial_download
  def reason(-23), do: :client_node_already_added
  def reason(-24), do: :client_node_not_added
  def reason(-29), do: :client_node_not_connected
  def reason(-30), do: :client_invalid_ip_or_subnet
  def reason(-31), do: :client_p2p_disabled
  def reason(-34), do: :client_node_capacity_reached

  # Chain errors
  def reason(-33), do: :client_mempool_disabled

  # Wallet errors
  def reason(-4), do: :wallet_error
  def reason(-6), do: :wallet_insufficient_funds
  def reason(-11), do: :wallet_invalid_label_name
  def reason(-12), do: :wallet_keypool_ran_out
  def reason(-13), do: :wallet_unlock_needed
  def reason(-14), do: :wallet_passphrase_incorrect
  def reason(-15), do: :wallet_wrong_enc_state
  def reason(-16), do: :wallet_encryption_failed
  def reason(-17), do: :wallet_already_unlocked
  def reason(-18), do: :wallet_not_found
  def reason(-19), do: :wallet_not_specified
  def reason(-35), do: :wallet_already_loaded
  def reason(-36), do: :wallet_already_exists

  # Backwards compatible aliases
  def reason(-2), do: :forbidden_by_safe_mode

  # Unknown error code
  def reason(_), do: :unknown_error
end
