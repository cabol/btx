defmodule BTx.RPC.Blockchain do
  @moduledoc """
  High-level interface for Bitcoin Core blockchain operations.

  This module provides convenient functions for blockchain operations like
  querying mempool information, block data, and network status. It wraps the
  lower-level `BTx.RPC` functionality with blockchain-specific conveniences.
  """

  alias BTx.RPC
  alias BTx.RPC.Response

  alias BTx.RPC.Blockchain.{
    GetMempoolEntry,
    GetMempoolEntryResult
  }

  @typedoc "Params for blockchain-related RPC calls"
  @type params() :: keyword() | %{optional(atom()) => any()}

  @typedoc "Response from blockchain-related RPC calls"
  @type response() :: RPC.rpc_response() | {:error, Ecto.Changeset.t()}

  @typedoc "Response from blockchain-related RPC calls"
  @type response(t) :: {:ok, t} | {:error, Ecto.Changeset.t()} | RPC.rpc_error()

  ## API

  @doc """
  Returns mempool data for given transaction.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Blockchain.GetMempoolEntry` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get mempool entry for a transaction
      iex> BTx.RPC.Blockchain.get_mempool_entry(client,
      ...>   txid: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      ...> )
      {:ok, %BTx.RPC.Blockchain.GetMempoolEntryResult{
        vsize: 141,
        weight: 561,
        fees: %BTx.RPC.Blockchain.GetMempoolEntryFees{
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
      iex> BTx.RPC.Blockchain.get_mempool_entry(client,
      ...>   txid: "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
      ...> )
      {:error, %BTx.RPC.MethodError{
        code: -5,
        message: "Transaction not in mempool"
      }}

  """
  @spec get_mempool_entry(RPC.client(), params(), keyword()) :: response(GetMempoolEntryResult.t())
  def get_mempool_entry(client, params, opts \\ []) do
    with {:ok, request} <- GetMempoolEntry.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      GetMempoolEntryResult.new(result)
    end
  end

  @doc """
  Same as `get_mempool_entry/3` but raises on error.
  """
  @spec get_mempool_entry!(RPC.client(), params(), keyword()) :: GetMempoolEntryResult.t()
  def get_mempool_entry!(client, params, opts \\ []) do
    client
    |> RPC.call!(GetMempoolEntry.new!(params), opts)
    |> Map.fetch!(:result)
    |> GetMempoolEntryResult.new!()
  end
end
