defmodule BTx.RPC.Utils do
  @moduledoc """
  Utility RPC methods for Bitcoin Core.

  This module provides utility functions for Bitcoin operations such as
  address validation, signature verification, and other general utilities.
  """

  alias BTx.RPC
  alias BTx.RPC.Response
  alias BTx.RPC.Utils.{ValidateAddress, ValidateAddressResult}

  ## Types

  @typedoc "Parameters for RPC calls"
  @type params() :: keyword() | map()

  @typedoc "Response type for RPC calls"
  @type response(result) :: {:ok, result} | {:error, term()}

  ## ValidateAddress

  @doc """
  Return information about the given bitcoin address.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Utils.ValidateAddress` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Validate a bech32 address
      iex> BTx.RPC.Utils.validate_address(client,
      ...>   address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl"
      ...> )
      {:ok, %BTx.RPC.Utils.ValidateAddressResult{
        isvalid: true,
        address: "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
        script_pub_key: "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
        isscript: false,
        iswitness: true,
        witness_version: 0,
        witness_program: "389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
      }}

      # Validate a legacy address
      iex> BTx.RPC.Utils.validate_address(client,
      ...>   address: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
      ...> )
      {:ok, %BTx.RPC.Utils.ValidateAddressResult{
        isvalid: true,
        address: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
        script_pub_key: "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac",
        isscript: false,
        iswitness: false
      }}

      # Validate an invalid address
      iex> BTx.RPC.Utils.validate_address(client, address: "invalid_address")
      {:ok, %BTx.RPC.Utils.ValidateAddressResult{isvalid: false}}

      # Validate a P2SH address
      iex> BTx.RPC.Utils.validate_address(client,
      ...>   address: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
      ...> )
      {:ok, %BTx.RPC.Utils.ValidateAddressResult{
        isvalid: true,
        address: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
        script_pub_key: "a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2687",
        isscript: true,
        iswitness: false
      }}

  """
  @spec validate_address(RPC.client(), params(), keyword()) :: response(ValidateAddressResult.t())
  def validate_address(client, params, opts \\ []) do
    with {:ok, request} <- ValidateAddress.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      ValidateAddressResult.new(result)
    end
  end

  @doc """
  Same as `validate_address/3` but raises on error.
  """
  @spec validate_address!(RPC.client(), params(), keyword()) :: ValidateAddressResult.t()
  def validate_address!(client, params, opts \\ []) do
    client
    |> RPC.call!(ValidateAddress.new!(params), opts)
    |> Map.fetch!(:result)
    |> ValidateAddressResult.new!()
  end
end
