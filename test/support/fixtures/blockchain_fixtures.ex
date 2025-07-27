defmodule BTx.BlockchainFixtures do
  @moduledoc """
  Test fixtures for Bitcoin Blockchain RPC responses and test data.
  """

  import BTx.TestUtils

  ## GetMempoolEntry result

  @doc """
  Returns a fixture for getmempoolentry RPC result.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default mempool entry
      get_mempool_entry_result_fixture()

      # Override vsize and weight
      get_mempool_entry_result_fixture(%{
        "vsize" => 250,
        "weight" => 1000
      })

      # Transaction with dependencies
      get_mempool_entry_result_fixture(%{
        "depends" => ["abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"],
        "spentby" => ["fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"],
        "descendantcount" => 2,
        "ancestorcount" => 2
      })

      # RBF non-replaceable transaction
      get_mempool_entry_result_fixture(%{
        "bip125-replaceable" => false
      })

      # High fee transaction
      get_mempool_entry_result_fixture(%{
        "fees" => %{
          "base" => 0.00050000,
          "modified" => 0.00050000,
          "ancestor" => 0.00050000,
          "descendant" => 0.00050000
        }
      })

  """
  @spec get_mempool_entry_result_fixture(map()) :: map()
  def get_mempool_entry_result_fixture(overrides \\ %{}) do
    default_fixture()
    |> deep_merge(overrides)
  end

  @doc """
  Returns preset fixtures for common mempool entry types.

  ## Examples

      get_mempool_entry_preset(:standard)
      get_mempool_entry_preset(:with_dependencies)
      get_mempool_entry_preset(:high_fee)
      get_mempool_entry_preset(:rbf_disabled)
      get_mempool_entry_preset(:unbroadcast)

  """
  @spec get_mempool_entry_preset(atom()) :: map()
  def get_mempool_entry_preset(type) do
    case type do
      :standard -> get_mempool_entry_result_fixture()
      :with_dependencies -> get_mempool_entry_result_fixture(dependencies_overrides())
      :high_fee -> get_mempool_entry_result_fixture(high_fee_overrides())
      :rbf_disabled -> get_mempool_entry_result_fixture(rbf_disabled_overrides())
      :unbroadcast -> get_mempool_entry_result_fixture(unbroadcast_overrides())
    end
  end

  ## Private functions

  defp default_fixture do
    %{
      "vsize" => 141,
      "weight" => 561,
      "fee" => 0.00001000,
      "modifiedfee" => 0.00001000,
      "time" => 1_640_995_200,
      "height" => 750_123,
      "descendantcount" => 1,
      "descendantsize" => 141,
      "descendantfees" => 0.00001000,
      "ancestorcount" => 1,
      "ancestorsize" => 141,
      "ancestorfees" => 0.00001000,
      "wtxid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      "fees" => %{
        "base" => 0.00001000,
        "modified" => 0.00001000,
        "ancestor" => 0.00001000,
        "descendant" => 0.00001000
      },
      "depends" => [],
      "spentby" => [],
      "bip125-replaceable" => true,
      "unbroadcast" => false
    }
  end

  defp dependencies_overrides do
    %{
      "vsize" => 250,
      "weight" => 1000,
      "fee" => 0.00002000,
      "modifiedfee" => 0.00002000,
      "time" => 1_640_995_300,
      "height" => 750_124,
      "descendantcount" => 2,
      "descendantsize" => 391,
      "descendantfees" => 0.00003000,
      "ancestorcount" => 2,
      "ancestorsize" => 391,
      "ancestorfees" => 0.00003000,
      "fees" => %{
        "base" => 0.00002000,
        "modified" => 0.00002000,
        "ancestor" => 0.00003000,
        "descendant" => 0.00003000
      },
      "depends" => ["abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"],
      "spentby" => ["fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"],
      "bip125-replaceable" => false,
      "unbroadcast" => true
    }
  end

  defp high_fee_overrides do
    %{
      "vsize" => 225,
      "weight" => 900,
      "fee" => 0.00050000,
      "modifiedfee" => 0.00050000,
      "time" => 1_640_995_400,
      "height" => 750_125,
      "descendantfees" => 0.00050000,
      "ancestorfees" => 0.00050000,
      "fees" => %{
        "base" => 0.00050000,
        "modified" => 0.00050000,
        "ancestor" => 0.00050000,
        "descendant" => 0.00050000
      },
      "bip125-replaceable" => true
    }
  end

  defp rbf_disabled_overrides do
    %{
      "vsize" => 180,
      "weight" => 720,
      "fee" => 0.00001500,
      "modifiedfee" => 0.00001500,
      "time" => 1_640_995_500,
      "height" => 750_126,
      "descendantfees" => 0.00001500,
      "ancestorfees" => 0.00001500,
      "fees" => %{
        "base" => 0.00001500,
        "modified" => 0.00001500,
        "ancestor" => 0.00001500,
        "descendant" => 0.00001500
      },
      "bip125-replaceable" => false
    }
  end

  defp unbroadcast_overrides do
    %{
      "vsize" => 165,
      "weight" => 660,
      "fee" => 0.00000800,
      "modifiedfee" => 0.00000800,
      "time" => 1_640_995_100,
      "height" => 750_122,
      "descendantfees" => 0.00000800,
      "ancestorfees" => 0.00000800,
      "fees" => %{
        "base" => 0.00000800,
        "modified" => 0.00000800,
        "ancestor" => 0.00000800,
        "descendant" => 0.00000800
      },
      "bip125-replaceable" => true,
      "unbroadcast" => true
    }
  end
end
