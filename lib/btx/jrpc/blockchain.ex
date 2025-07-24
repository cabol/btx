defmodule BTx.JRPC.Blockchain do
  @moduledoc """
  High-level interface for Bitcoin Core blockchain operations.

  This module provides convenient functions for blockchain operations like
  querying mempool information, block data, and network status. It wraps the
  lower-level `BTx.JRPC` functionality with blockchain-specific conveniences.

  ## Blockchain requests

  - `BTx.JRPC.Blockchain.GetMempoolEntry`
  - **More coming soon**

  """

  alias BTx.JRPC
  alias BTx.JRPC.Response

  alias BTx.JRPC.Blockchain.{
    GetMempoolEntry,
    GetMempoolEntryResult
  }

  @typedoc "Params for blockchain-related RPC calls"
  @type params() :: keyword() | %{optional(atom()) => any()}

  @typedoc "Response from blockchain-related RPC calls"
  @type response() :: JRPC.rpc_response() | {:error, Ecto.Changeset.t()}

  @typedoc "Response from blockchain-related RPC calls"
  @type response(t) :: {:ok, t} | {:error, Ecto.Changeset.t()} | JRPC.rpc_error()

  ## API

  @doc """
  Returns mempool data for given transaction.

  ## Arguments

  - `client` - Same as `BTx.JRPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.JRPC.Blockchain.GetMempoolEntry` for more information about the
    available parameters.
  - `opts` - Same as `BTx.JRPC.call/3`.

  ## Options

  See `BTx.JRPC.call/3`.

  ## Examples

      # Get mempool entry for a transaction
      iex> BTx.JRPC.Blockchain.get_mempool_entry(client,
      ...>   txid: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      ...> )
      {:ok, %BTx.JRPC.Blockchain.GetMempoolEntryResult{
        vsize: 141,
        weight: 561,
        fees: %BTx.JRPC.Blockchain.GetMempoolEntryFees{
          base: 0.00001000,
          modified: 0.00001000,
          ancestor: 0.00001000,
          descendant: 0.00001000
        },
        time: 1640995200,
        height: 750123,
        depends: [],
        spentby: [],
        bip125_replaceable: true,
        unbroadcast: false,
        ...
      }}

      # Handle transaction not in mempool
      iex> BTx.JRPC.Blockchain.get_mempool_entry(client,
      ...>   txid: "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
      ...> )
      {:error, %BTx.JRPC.MethodError{
        code: -5,
        message: "Transaction not in mempool"
      }}

  """
  @spec get_mempool_entry(JRPC.client(), params(), keyword()) :: response(GetMempoolEntryResult.t())
  def get_mempool_entry(client, params, opts \\ []) do
    with {:ok, request} <- GetMempoolEntry.new(params),
         {:ok, %Response{result: result}} <- JRPC.call(client, request, opts) do
      GetMempoolEntryResult.new(result)
    end
  end

  @doc """
  Same as `get_mempool_entry/3` but raises on error.
  """
  @spec get_mempool_entry!(JRPC.client(), params(), keyword()) :: GetMempoolEntryResult.t()
  def get_mempool_entry!(client, params, opts \\ []) do
    client
    |> JRPC.call!(GetMempoolEntry.new!(params), opts)
    |> Map.fetch!(:result)
    |> GetMempoolEntryResult.new!()
  end
end
