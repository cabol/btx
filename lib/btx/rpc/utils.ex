defmodule BTx.RPC.Utils do
  @moduledoc """
  Utility RPC methods for Bitcoin Core.

  This module provides utility functions for Bitcoin operations such as
  address validation, signature verification, and other general utilities.
  """

  alias BTx.RPC
  alias BTx.RPC.Response

  alias BTx.RPC.Utils.{
    GetDescriptorInfo,
    GetDescriptorInfoResult,
    ValidateAddress,
    ValidateAddressResult
  }

  ## Types

  @typedoc "Parameters for RPC calls"
  @type params() :: keyword() | map()

  @typedoc "Response type for RPC calls"
  @type response(result) :: {:ok, result} | {:error, term()}

  ## API

  @doc """
  Analyses a descriptor.

  ## Arguments

  - `client` - Same as `BTx.RPC.call/3`.
  - `params` - A keyword list or map of parameters for the request.
    See `BTx.RPC.Utils.GetDescriptorInfo` for more information about the
    available parameters.
  - `opts` - Same as `BTx.RPC.call/3`.

  ## Options

  See `BTx.RPC.call/3`.

  ## Examples

      # Analyze a basic descriptor
      iex> BTx.RPC.Utils.get_descriptor_info(client,
      ...>   descriptor: "wpkh([d34db33f/84h/0h/0h]0279be667ef9dcbbac55a06295Ce870b07029Bfcdb2dce28d959f2815b16f81798)"
      ...> )
      {:ok, %BTx.RPC.Utils.GetDescriptorInfoResult{
        descriptor: "wpkh([d34db33f/84h/0h/0h]0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798)#cjjspncu",
        checksum: "cjjspncu",
        isrange: false,
        issolvable: true,
        hasprivatekeys: false
      }}

      # Analyze a ranged descriptor
      iex> BTx.RPC.Utils.get_descriptor_info(client,
      ...>   descriptor: "wpkh([d34db33f/84h/0h/0h]xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL/0/*)"
      ...> )
      {:ok, %BTx.RPC.Utils.GetDescriptorInfoResult{
        descriptor: "wpkh([d34db33f/84h/0h/0h]xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL/0/*)#cjjspncu",
        checksum: "cjjspncu",
        isrange: true,
        issolvable: true,
        hasprivatekeys: false
      }}

      # Analyze a descriptor with private keys
      iex> BTx.RPC.Utils.get_descriptor_info(client,
      ...>   descriptor: "wpkh(L1aW4aubDFB7yfras2S1mN3bqg9nwySY8nkoLmJebSLD5BWv3ENZ)"
      ...> )
      {:ok, %BTx.RPC.Utils.GetDescriptorInfoResult{
        descriptor: "wpkh(03a34b99f22c790c4e36b2b3c2c35a36db06226e41c692fc82b8b56ac1c540c5bd)#8fhd9pwu",
        checksum: "8fhd9pwu",
        isrange: false,
        issolvable: true,
        hasprivatekeys: true
      }}

  """
  @spec get_descriptor_info(RPC.client(), params(), keyword()) ::
          response(GetDescriptorInfoResult.t())
  def get_descriptor_info(client, params, opts \\ []) do
    with {:ok, request} <- GetDescriptorInfo.new(params),
         {:ok, %Response{result: result}} <- RPC.call(client, request, opts) do
      GetDescriptorInfoResult.new(result)
    end
  end

  @doc """
  Same as `get_descriptor_info/3` but raises on error.
  """
  @spec get_descriptor_info!(RPC.client(), params(), keyword()) ::
          GetDescriptorInfoResult.t()
  def get_descriptor_info!(client, params, opts \\ []) do
    client
    |> RPC.call!(GetDescriptorInfo.new!(params), opts)
    |> Map.fetch!(:result)
    |> GetDescriptorInfoResult.new!()
  end

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
