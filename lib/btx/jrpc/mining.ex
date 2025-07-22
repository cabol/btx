defmodule BTx.JRPC.Mining do
  @moduledoc """
  High-level interface for Bitcoin Core mining operations.

  This module provides convenient functions for mining operations like
  generating blocks to specified addresses. It wraps the lower-level
  `BTx.JRPC` functionality with mining-specific conveniences.

  ## Mining requests

  - `BTx.JRPC.Mining.GenerateToAddress`
  - **More coming soon**

  ## Mining Operations

  Mining operations in Bitcoin Core are typically used for testing and
  development purposes, especially on regtest networks where you need to
  generate blocks manually.
  """

  alias BTx.JRPC
  alias BTx.JRPC.Mining.GenerateToAddress
  alias BTx.JRPC.Response

  @typedoc "Params for mining-related RPC calls"
  @type params() :: keyword() | %{optional(atom()) => any()}

  @typedoc "Response from mining-related RPC calls"
  @type response() :: JRPC.rpc_response() | {:error, Ecto.Changeset.t()}

  @typedoc "Response from mining-related RPC calls"
  @type response(t) :: {:ok, t} | {:error, Ecto.Changeset.t()} | JRPC.rpc_error()

  ## API

  @doc """
  Mine blocks immediately to a specified address (before the RPC call returns).

  ## Arguments

  - `client` - Same as `BTx.JRPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.JRPC.Mining.GenerateToAddress` for more information about the
    available parameters.
  - `opts` - Same as `BTx.JRPC.call/3`.

  ## Options

  See `BTx.JRPC.call/3`.

  ## Examples

      # Generate 10 blocks to a specific address
      iex> BTx.JRPC.Mining.generate_to_address(client,
      ...>   nblocks: 10,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl"
      ...> )
      {:ok, [
        "0000000000000001...",
        "0000000000000002...",
        ...
      ]}

      # Generate 5 blocks with custom max tries
      iex> BTx.JRPC.Mining.generate_to_address(client,
      ...>   nblocks: 5,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      ...>   maxtries: 500000
      ...> )
      {:ok, [
        "0000000000000003...",
        "0000000000000004...",
        ...
      ]}

      # Typical usage in regtest environment
      iex> {:ok, address} = BTx.JRPC.Wallets.get_new_address(client,
      ...>   wallet_name: "test_wallet"
      ...> )
      iex> BTx.JRPC.Mining.generate_to_address(client,
      ...>   nblocks: 101,  # Generate enough blocks for coinbase maturity
      ...>   address: address
      ...> )
      {:ok, [...]}

  """
  @spec generate_to_address(JRPC.client(), params(), keyword()) :: response([String.t()])
  def generate_to_address(client, params, opts \\ []) do
    with {:ok, request} <- GenerateToAddress.new(params),
         {:ok, %Response{result: result}} <- JRPC.call(client, request, opts) do
      {:ok, assert_list(result)}
    end
  end

  @doc """
  Same as `generate_to_address/3` but raises on error.
  """
  @spec generate_to_address!(JRPC.client(), params(), keyword()) :: [String.t()]
  def generate_to_address!(client, params, opts \\ []) do
    client
    |> JRPC.call!(GenerateToAddress.new!(params), opts)
    |> Map.fetch!(:result)
    |> assert_list()
  end

  ## Private functions

  defp assert_list(result) do
    if is_list(result) do
      result
    else
      raise "Expected a list, got #{inspect(result)}"
    end
  end
end
