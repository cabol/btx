defmodule BTx.UtilsFixtures do
  @moduledoc """
  This module defines test fixtures for the Utils context.
  """

  import BTx.TestUtils

  ## GetDescriptorInfo fixtures

  @doc """
  Returns a fixture for getdescriptorinfo request.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default request
      get_descriptor_info_request_fixture()

      # Override specific fields
      get_descriptor_info_request_fixture(%{
        "descriptor" => "custom_descriptor"
      })

  """
  @spec get_descriptor_info_request_fixture(map()) :: map()
  def get_descriptor_info_request_fixture(overrides \\ %{}) do
    %{
      "descriptor" =>
        "wpkh([d34db33f/84h/0h/0h]0279be667ef9dcbbac55a06295Ce870b07029Bfcdb2dce28d959f2815b16f81798)"
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns a fixture for getdescriptorinfo result.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default successful result
      get_descriptor_info_result_fixture()

      # Override for ranged descriptor
      get_descriptor_info_result_fixture(%{
        "descriptor" => "wpkh([d34db33f/84h/0h/0h]xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL/0/*)#cjjspncu",
        "isrange" => true
      })

      # Override for descriptor with private keys
      get_descriptor_info_result_fixture(%{
        "descriptor" => "wpkh(03a34b99f22c790c4e36b2b3c2c35a36db06226e41c692fc82b8b56ac1c540c5bd)#8fhd9pwu",
        "checksum" => "8fhd9pwu",
        "hasprivatekeys" => true
      })

  """
  @spec get_descriptor_info_result_fixture(map()) :: map()
  def get_descriptor_info_result_fixture(overrides \\ %{}) do
    %{
      "descriptor" =>
        "wpkh([d34db33f/84h/0h/0h]0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798)#cjjspncu",
      "checksum" => "cjjspncu",
      "isrange" => false,
      "issolvable" => true,
      "hasprivatekeys" => false
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns preset fixtures for common getdescriptorinfo scenarios.

  ## Examples

      get_descriptor_info_preset(:basic_pubkey)
      get_descriptor_info_preset(:ranged_descriptor)
      get_descriptor_info_preset(:with_private_keys)
      get_descriptor_info_preset(:unsolvable)

  """
  @spec get_descriptor_info_preset(atom()) :: map()
  def get_descriptor_info_preset(type) do
    case type do
      :basic_pubkey -> get_descriptor_info_result_fixture()
      :ranged_descriptor -> get_descriptor_info_result_fixture(ranged_descriptor_overrides())
      :with_private_keys -> get_descriptor_info_result_fixture(with_private_keys_overrides())
      :unsolvable -> get_descriptor_info_result_fixture(unsolvable_overrides())
      :multisig -> get_descriptor_info_result_fixture(multisig_overrides())
    end
  end

  ## Private functions

  defp ranged_descriptor_overrides do
    %{
      "descriptor" =>
        "wpkh([d34db33f/84h/0h/0h]xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL/0/*)#cjjspncu",
      "checksum" => "cjjspncu",
      "isrange" => true,
      "issolvable" => true,
      "hasprivatekeys" => false
    }
  end

  defp with_private_keys_overrides do
    %{
      "descriptor" =>
        "wpkh(03a34b99f22c790c4e36b2b3c2c35a36db06226e41c692fc82b8b56ac1c540c5bd)#8fhd9pwu",
      "checksum" => "8fhd9pwu",
      "isrange" => false,
      "issolvable" => true,
      "hasprivatekeys" => true
    }
  end

  defp unsolvable_overrides do
    %{
      "descriptor" => "raw(76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac)#0rql6426",
      "checksum" => "0rql6426",
      "isrange" => false,
      "issolvable" => false,
      "hasprivatekeys" => false
    }
  end

  defp multisig_overrides do
    %{
      "descriptor" =>
        "multi(2,03a0434d9e47f3c86235477c7b1ae6ae5d3442d49b1943c2b752a68e2a47e247c7,03774ae7f858a9411e5ef4246b70c65aac5649980be5c17891bbec17895da008cb)#9wnf9t4w",
      "checksum" => "9wnf9t4w",
      "isrange" => false,
      "issolvable" => true,
      "hasprivatekeys" => false
    }
  end

  ## ValidateAddress fixtures

  @doc """
  Returns a fixture for validateaddress RPC result.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default valid bech32 address result
      validate_address_result_fixture()

      # Override for legacy address
      validate_address_result_fixture(%{
        "address" => "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
        "scriptPubKey" => "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac",
        "isscript" => false,
        "iswitness" => false,
        "witness_version" => nil,
        "witness_program" => nil
      })

      # Invalid address result
      validate_address_result_fixture(%{
        "isvalid" => false,
        "address" => nil,
        "scriptPubKey" => nil,
        "isscript" => nil,
        "iswitness" => nil
      })

  """
  @spec validate_address_result_fixture(map()) :: map()
  def validate_address_result_fixture(overrides \\ %{}) do
    default_validate_address_fixture()
    |> deep_merge(overrides)
  end

  @doc """
  Returns preset fixtures for common address validation scenarios.

  ## Examples

      validate_address_preset(:valid_bech32)
      validate_address_preset(:valid_legacy)
      validate_address_preset(:valid_p2sh)
      validate_address_preset(:invalid)

  """
  @spec validate_address_preset(atom()) :: map()
  def validate_address_preset(type) do
    case type do
      :valid_bech32 -> validate_address_result_fixture()
      :valid_legacy -> validate_address_result_fixture(legacy_address_overrides())
      :valid_p2sh -> validate_address_result_fixture(p2sh_address_overrides())
      :invalid -> validate_address_result_fixture(invalid_address_overrides())
    end
  end

  ## Private functions for ValidateAddress

  defp default_validate_address_fixture do
    %{
      "isvalid" => true,
      "address" => "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      "scriptPubKey" => "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
      "isscript" => false,
      "iswitness" => true,
      "witness_version" => 0,
      "witness_program" => "389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
    }
  end

  defp legacy_address_overrides do
    %{
      "address" => "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
      "scriptPubKey" => "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac",
      "isscript" => false,
      "iswitness" => false,
      "witness_version" => nil,
      "witness_program" => nil
    }
  end

  defp p2sh_address_overrides do
    %{
      "address" => "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
      "scriptPubKey" => "a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2687",
      "isscript" => true,
      "iswitness" => false,
      "witness_version" => nil,
      "witness_program" => nil
    }
  end

  defp invalid_address_overrides do
    %{
      "isvalid" => false,
      "address" => nil,
      "scriptPubKey" => nil,
      "isscript" => nil,
      "iswitness" => nil,
      "witness_version" => nil,
      "witness_program" => nil
    }
  end
end
