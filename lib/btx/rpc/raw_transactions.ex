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
    CreateRawTransaction,
    DecodeRawTransaction,
    DecodeRawTransactionResult,
    GetRawTransaction,
    GetRawTransactionResult,
    SignRawTransactionWithKey,
    SignRawTransactionWithKeyResult
  }

  alias BTx.RPC.Response

  @typedoc "Params for raw transaction-related RPC calls"
  @type params() :: keyword() | %{optional(atom()) => any()}

  @typedoc "Response from raw transaction-related RPC calls"
  @type response() :: RPC.rpc_response() | {:error, Ecto.Changeset.t()}

  @typedoc "Response from raw transaction-related RPC calls"
  @type response(t) :: {:ok, t} | {:error, Ecto.Changeset.t()} | RPC.rpc_error()

  ## API

  # Add this to the alias list in raw_transactions.ex:
  alias BTx.RPC.RawTransactions.{
    # <- ADD THIS LINE
    CreateRawTransaction,
    DecodeRawTransaction,
    DecodeRawTransactionResult,
    GetRawTransaction,
    GetRawTransactionResult
  }

  # Add these functions at the end of the raw_transactions.ex module:

  @doc """
  Create a transaction spending the given inputs and creating new outputs.

  Outputs can be addresses or data. Returns hex-encoded raw transaction.

  Note that the transaction's inputs are not signed, and it is not stored in the
  wallet or transmitted to the network.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.RawTransactions.CreateRawTransaction` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Create transaction with address output
      iex> BTx.RPC.RawTransactions.create_raw_transaction(client,
      ...>   inputs: [%{txid: "abc123...", vout: 0}],
      ...>   outputs: %{
      ...>     addresses: [%{address: "bc1q...", amount: 1.0}]
      ...>   }
      ...> )
      {:ok, "0200000001abc123..."}

      # Create transaction with data output
      iex> BTx.RPC.RawTransactions.create_raw_transaction(client,
      ...>   inputs: [%{txid: "abc123...", vout: 0}],
      ...>   outputs: %{
      ...>     data: "deadbeef"
      ...>   }
      ...> )
      {:ok, "0200000001abc123..."}

      # Create transaction with mixed outputs
      iex> BTx.RPC.RawTransactions.create_raw_transaction(client,
      ...>   inputs: [%{txid: "abc123...", vout: 0}],
      ...>   outputs: %{
      ...>     addresses: [%{address: "bc1q...", amount: 1.0}],
      ...>     data: "deadbeef"
      ...>   }
      ...> )
      {:ok, "0200000001abc123..."}

      # Create transaction with locktime and replaceable
      iex> BTx.RPC.RawTransactions.create_raw_transaction(client,
      ...>   inputs: [%{txid: "abc123...", vout: 0, sequence: 1000}],
      ...>   outputs: %{
      ...>     addresses: [%{address: "bc1q...", amount: 1.0}]
      ...>   },
      ...>   locktime: 500000,
      ...>   replaceable: true
      ...> )
      {:ok, "0200000001abc123..."}

  """
  @spec create_raw_transaction(RPC.client(), params(), keyword()) :: response(String.t())
  def create_raw_transaction(client, params, opts \\ []) do
    with {:ok, request} <- CreateRawTransaction.new(params) do
      case RPC.call(client, request, opts) do
        {:ok, %Response{result: result}} -> {:ok, result}
        error -> error
      end
    end
  end

  @doc """
  Same as `create_raw_transaction/3` but raises on error.
  """
  @spec create_raw_transaction!(RPC.client(), params(), keyword()) :: String.t()
  def create_raw_transaction!(client, params, opts \\ []) do
    client
    |> RPC.call!(CreateRawTransaction.new!(params), opts)
    |> Map.fetch!(:result)
  end

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

  @doc """
  Return a JSON object representing the serialized, hex-encoded transaction.

  This function accepts a hex-encoded transaction string and returns detailed
  information about the transaction structure including inputs, outputs, and metadata.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.RawTransactions.DecodeRawTransaction` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Decode a raw transaction hex string
      iex> BTx.RPC.RawTransactions.decode_raw_transaction(client,
      ...>   hexstring: "02000000010123456789abcdef...")
      {:ok, %BTx.RPC.RawTransactions.DecodeRawTransactionResult{
        txid: "abcdef1234567890...",
        hash: "fedcba0987654321...",
        size: 225,
        vsize: 144,
        weight: 573,
        version: 2,
        locktime: 0,
        vin: [...],
        vout: [...]
      }}

      # Decode with witness flag
      iex> BTx.RPC.RawTransactions.decode_raw_transaction(client,
      ...>   hexstring: "02000000010123456789abcdef...",
      ...>   iswitness: true)
      {:ok, %BTx.RPC.RawTransactions.DecodeRawTransactionResult{...}}

  """
  @spec decode_raw_transaction(RPC.client(), params(), keyword()) ::
          response(DecodeRawTransactionResult.t())
  def decode_raw_transaction(client, params, opts \\ []) do
    with {:ok, request} <- DecodeRawTransaction.new(params) do
      case RPC.call(client, request, opts) do
        {:ok, %Response{result: result}} -> DecodeRawTransactionResult.new(result)
        error -> error
      end
    end
  end

  @doc """
  Same as `decode_raw_transaction/3` but raises on error.
  """
  @spec decode_raw_transaction!(RPC.client(), params(), keyword()) ::
          DecodeRawTransactionResult.t()
  def decode_raw_transaction!(client, params, opts \\ []) do
    client
    |> RPC.call!(DecodeRawTransaction.new!(params), opts)
    |> Map.fetch!(:result)
    |> DecodeRawTransactionResult.new!()
  end

  @doc """
  Sign inputs for raw transaction (serialized, hex-encoded).

  The second argument is an array of base58-encoded private keys that will be
  the only keys used to sign the transaction.

  The third optional argument (may be null) is an array of previous transaction
  outputs that this transaction depends on but may not yet be in the block chain.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.RawTransactions.SignRawTransactionWithKey` for more information
    about the available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Sign transaction with private keys
      iex> BTx.RPC.RawTransactions.sign_raw_transaction_with_key(client,
      ...>   hexstring: "02000000010123456789abcdef...",
      ...>   privkeys: ["5HueCGU8rMjxEXxiPuD5BDu... "]
      ...> )
      {:ok, %BTx.RPC.RawTransactions.SignRawTransactionWithKeyResult{
        hex: "0200000001...",
        complete: true,
        errors: []
      }}

      # Sign with previous transaction outputs
      iex> BTx.RPC.RawTransactions.sign_raw_transaction_with_key(client,
      ...>   hexstring: "02000000010123456789abcdef...",
      ...>   privkeys: ["5HueCGU8rMjxEXxiPuD5BDu... "],
      ...>   prevtxs: [%{
      ...>     txid: "abcdef123...",
      ...>     vout: 0,
      ...>     script_pub_key: "76a914...",
      ...>     amount: 1.0
      ...>   }]
      ...> )
      {:ok, %BTx.RPC.RawTransactions.SignRawTransactionWithKeyResult{...}}

      # Sign with custom signature hash type
      iex> BTx.RPC.RawTransactions.sign_raw_transaction_with_key(client,
      ...>   hexstring: "02000000010123456789abcdef...",
      ...>   privkeys: ["5HueCGU8rMjxEXxiPuD5BDu... "],
      ...>   sighashtype: "SINGLE"
      ...> )
      {:ok, %BTx.RPC.RawTransactions.SignRawTransactionWithKeyResult{...}}

  """
  @spec sign_raw_transaction_with_key(RPC.client(), params(), keyword()) ::
          response(SignRawTransactionWithKeyResult.t())
  def sign_raw_transaction_with_key(client, params, opts \\ []) do
    with {:ok, request} <- SignRawTransactionWithKey.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      SignRawTransactionWithKeyResult.new(result)
    end
  end

  @doc """
  Same as `sign_raw_transaction_with_key/3` but raises on error.
  """
  @spec sign_raw_transaction_with_key!(RPC.client(), params(), keyword()) ::
          SignRawTransactionWithKeyResult.t()
  def sign_raw_transaction_with_key!(client, params, opts \\ []) do
    client
    |> RPC.call!(SignRawTransactionWithKey.new!(params), opts)
    |> Map.fetch!(:result)
    |> SignRawTransactionWithKeyResult.new!()
  end
end
