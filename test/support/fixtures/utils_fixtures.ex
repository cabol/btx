defmodule BTx.UtilsFixtures do
  @moduledoc """
  This module defines test fixtures for the Utils context.
  """

  import BTx.TestUtils

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
