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
    GetBlock,
    GetBlockchainInfo,
    GetBlockchainInfoResult,
    GetBlockCount,
    GetBlockResultV1,
    GetBlockResultV2,
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

  @doc """
  Returns an object containing various state info regarding blockchain processing.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get blockchain information
      iex> BTx.RPC.Blockchain.get_blockchain_info(client)
      {:ok, %BTx.RPC.Blockchain.GetBlockchainInfoResult{
        chain: "regtest",
        blocks: 150,
        headers: 150,
        bestblockhash: "0000000000000a...",
        difficulty: 4.656542373906925e-10,
        mediantime: 1640995200,
        verificationprogress: 1.0,
        initialblockdownload: false,
        chainwork: "0000000000000000000000000000000000000000000000000000012e012e012e",
        size_on_disk: 45123,
        pruned: false,
        softforks: %{
          "csv" => %BTx.RPC.Blockchain.Commons.Softfork{
            type: "buried",
            active: true,
            height: 0
          },
          "segwit" => %BTx.RPC.Blockchain.Commons.Softfork{
            type: "buried",
            active: true,
            height: 0
          }
        },
        warnings: ""
      }}

  """
  @spec get_blockchain_info(RPC.client(), keyword()) :: response(GetBlockchainInfoResult.t())
  def get_blockchain_info(client, opts \\ []) do
    with {:ok, request} <- GetBlockchainInfo.new(),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      GetBlockchainInfoResult.new(result)
    end
  end

  @doc """
  Same as `get_blockchain_info/2` but raises on error.
  """
  @spec get_blockchain_info!(RPC.client(), keyword()) :: GetBlockchainInfoResult.t()
  def get_blockchain_info!(client, opts \\ []) do
    client
    |> RPC.call!(GetBlockchainInfo.new!(), opts)
    |> Map.fetch!(:result)
    |> GetBlockchainInfoResult.new!()
  end

  @doc """
  Returns the height of the most-work fully-validated chain.

  The genesis block has height 0.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get current block count
      iex> BTx.RPC.Blockchain.get_block_count(client)
      {:ok, 750000}

      # For regtest (typically lower block count)
      iex> BTx.RPC.Blockchain.get_block_count(client)
      {:ok, 150}

      # Genesis block has height 0, so first block after genesis is 1
      iex> BTx.RPC.Blockchain.get_block_count(client)
      {:ok, 1}

  """
  @spec get_block_count(RPC.client(), keyword()) :: response(non_neg_integer())
  def get_block_count(client, opts \\ []) do
    with {:ok, request} <- GetBlockCount.new(),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      {:ok, result}
    end
  end

  @doc """
  Same as `get_block_count/2` but raises on error.
  """
  @spec get_block_count!(RPC.client(), keyword()) :: non_neg_integer()
  def get_block_count!(client, opts \\ []) do
    client
    |> RPC.call!(GetBlockCount.new!(), opts)
    |> Map.fetch!(:result)
  end

  @doc """
  Returns block data by block hash.

  If verbosity is 0, returns a hex-encoded string.
  If verbosity is 1, returns a structured object with transaction IDs as strings.
  If verbosity is 2, returns a structured object with full transaction details.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Blockchain.GetBlock` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Get block as hex string (verbosity=0)
      iex> BTx.RPC.Blockchain.get_block(client,
      ...>   blockhash: "0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcdef",
      ...>   verbosity: 0
      ...> )
      {:ok, "0100000000000000000000..."}

      # Get block with transaction IDs (verbosity=1, default)
      iex> BTx.RPC.Blockchain.get_block(client,
      ...>   blockhash: "0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcdef"
      ...> )
      {:ok, %BTx.RPC.Blockchain.GetBlockResultV1{
        hash: "0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcdef",
        confirmations: 100,
        size: 1024,
        height: 750123,
        tx: ["abc123...", "def456..."],
        time: 1640995200,
        ...
      }}

      # Get block with full transaction details (verbosity=2)
      iex> BTx.RPC.Blockchain.get_block(client,
      ...>   blockhash: "0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcdef",
      ...>   verbosity: 2
      ...> )
      {:ok, %BTx.RPC.Blockchain.GetBlockResultV2{
        hash: "0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcdef",
        confirmations: 100,
        tx: [
          %BTx.RPC.RawTransactions.GetRawTransactionResult{...},
          %BTx.RPC.RawTransactions.GetRawTransactionResult{...}
        ],
        ...
      }}

      # Handle block not found
      iex> BTx.RPC.Blockchain.get_block(client,
      ...>   blockhash: "nonexistent0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef012345"
      ...> )
      {:error, %BTx.RPC.MethodError{
        code: -5,
        message: "Block not found"
      }}

  """
  @spec get_block(RPC.client(), params(), keyword()) ::
          response(String.t()) | response(GetBlockResultV1.t()) | response(GetBlockResultV2.t())
  def get_block(client, params, opts \\ []) do
    with {:ok, request} <- GetBlock.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      {:ok, get_block_result(result, request.verbosity)}
    end
  end

  @doc """
  Same as `get_block/3` but raises on error.
  """
  @spec get_block!(RPC.client(), params(), keyword()) ::
          String.t() | GetBlockResultV1.t() | GetBlockResultV2.t()
  def get_block!(client, params, opts \\ []) do
    request = GetBlock.new!(params)

    client
    |> RPC.call!(GetBlock.new!(params), opts)
    |> Map.fetch!(:result)
    |> get_block_result(request.verbosity)
  end

  # Return based on verbosity parameter
  defp get_block_result(result, 0), do: result
  defp get_block_result(result, 1), do: GetBlockResultV1.new!(result)
  defp get_block_result(result, 2), do: GetBlockResultV2.new!(result)
end
