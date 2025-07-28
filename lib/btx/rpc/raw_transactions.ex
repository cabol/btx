defmodule BTx.RPC.RawTransactions do
  @moduledoc """
  High-level interface for Bitcoin Core raw transaction operations.

  This module provides convenient functions for raw transaction operations like
  retrieving raw transaction data in both hex format and verbose JSON format.
  It wraps the lower-level `BTx.RPC` functionality with raw transaction-specific
  conveniences.
  """

  alias BTx.RPC

  alias BTx.RPC.RawTransactions.{
    GetRawTransaction,
    GetRawTransactionResult
  }

  alias BTx.RPC.Response

  @typedoc "Params for raw transaction-related RPC calls"
  @type params() :: keyword() | %{optional(atom()) => any()}

  @typedoc "Response from raw transaction-related RPC calls"
  @type response() :: RPC.rpc_response() | {:error, Ecto.Changeset.t()}

  @typedoc "Response from raw transaction-related RPC calls"
  @type response(t) :: {:ok, t} | {:error, Ecto.Changeset.t()} | RPC.rpc_error()

  ## API

  @doc """
  Return the raw transaction data.

  By default this function only works for mempool transactions. When called with a blockhash
  argument, getrawtransaction will return the transaction if the specified block is available
  and the transaction is found in that block.

  If verbose is 'false' or omitted, returns a hex-encoded string.
  If verbose is 'true', returns a structured object with transaction details.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.RawTransactions.GetRawTransaction` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get raw transaction as hex string (default behavior)
      iex> BTx.RPC.RawTransactions.get_raw_transaction(client,
      ...>   txid: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      ...> )
      {:ok, "020000000001..."}

      # Get raw transaction as structured object
      iex> BTx.RPC.RawTransactions.get_raw_transaction(client,
      ...>   txid: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      ...>   verbose: true
      ...> )
      {:ok, %BTx.RPC.RawTransactions.GetRawTransactionResult{
        hex: "020000000001...",
        txid: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        hash: "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
        size: 225,
        vsize: 144,
        weight: 573,
        version: 2,
        locktime: 0,
        vin: [...],
        vout: [...],
        blockhash: "0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcdef",
        confirmations: 100,
        blocktime: 1640995200,
        time: 1640995200
      }}

      # Get raw transaction from specific block
      iex> BTx.RPC.RawTransactions.get_raw_transaction(client,
      ...>   txid: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      ...>   verbose: true,
      ...>   blockhash: "0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcdef"
      ...> )
      {:ok, %BTx.RPC.RawTransactions.GetRawTransactionResult{...}}

      # Handle transaction not found
      iex> BTx.RPC.RawTransactions.get_raw_transaction(client,
      ...>   txid: "nonexistent1234567890abcdef1234567890abcdef1234567890abcdef123456"
      ...> )
      {:error, %BTx.RPC.MethodError{
        code: -5,
        message: "No such mempool or blockchain transaction"
      }}

  """
  @spec get_raw_transaction(RPC.client(), params(), keyword()) ::
          response(String.t()) | response(GetRawTransactionResult.t())
  def get_raw_transaction(client, params, opts \\ []) do
    with {:ok, request} <- GetRawTransaction.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      # Return based on verbose parameter
      case request.verbose do
        true -> GetRawTransactionResult.new(result)
        # result is a hex string
        _false_or_nil -> {:ok, result}
      end
    end
  end

  @doc """
  Same as `get_raw_transaction/3` but raises on error.
  """
  @spec get_raw_transaction!(RPC.client(), params(), keyword()) ::
          String.t() | GetRawTransactionResult.t()
  def get_raw_transaction!(client, params, opts \\ []) do
    request = GetRawTransaction.new!(params)

    result =
      client
      |> RPC.call!(request, opts)
      |> Map.fetch!(:result)

    # Return based on verbose parameter
    case request.verbose do
      true -> GetRawTransactionResult.new!(result)
      # result is a hex string
      _false_or_nil -> result
    end
  end
end
