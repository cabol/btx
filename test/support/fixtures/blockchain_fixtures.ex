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

  ## GetBlockchainInfo fixtures

  @doc """
  Returns a fixture for getblockchaininfo RPC result.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default blockchain info
      get_blockchain_info_result_fixture()

      # Override chain and blocks
      get_blockchain_info_result_fixture(%{
        "chain" => "main",
        "blocks" => 750000
      })

      # With pruning enabled
      get_blockchain_info_result_fixture(%{
        "pruned" => true,
        "pruneheight" => 500000,
        "automatic_pruning" => true,
        "prune_target_size" => 5500
      })

  """
  @spec get_blockchain_info_result_fixture(map()) :: map()
  def get_blockchain_info_result_fixture(overrides \\ %{}) do
    default_blockchain_info_fixture()
    |> deep_merge(overrides)
  end

  @doc """
  Returns preset fixtures for common blockchain info scenarios.

  ## Examples

      get_blockchain_info_preset(:regtest)
      get_blockchain_info_preset(:mainnet)
      get_blockchain_info_preset(:testnet)
      get_blockchain_info_preset(:pruned)
      get_blockchain_info_preset(:syncing)

  """
  @spec get_blockchain_info_preset(atom()) :: map()
  def get_blockchain_info_preset(type) do
    case type do
      :regtest -> get_blockchain_info_result_fixture()
      :mainnet -> get_blockchain_info_result_fixture(mainnet_overrides())
      :testnet -> get_blockchain_info_result_fixture(testnet_overrides())
      :pruned -> get_blockchain_info_result_fixture(pruned_overrides())
      :syncing -> get_blockchain_info_result_fixture(syncing_overrides())
    end
  end

  ## Softfork fixtures

  @doc """
  Returns a fixture for a buried softfork.
  """
  @spec buried_softfork_fixture(map()) :: map()
  def buried_softfork_fixture(overrides \\ %{}) do
    %{
      "type" => "buried",
      "active" => true,
      "height" => 0
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns a fixture for a BIP9 softfork.
  """
  @spec bip9_softfork_fixture(map()) :: map()
  def bip9_softfork_fixture(overrides \\ %{}) do
    %{
      "type" => "bip9",
      "active" => true,
      "height" => 481_824,
      "bip9" => %{
        "status" => "active",
        "start_time" => 1_479_168_000,
        "timeout" => 1_510_704_000,
        "since" => 481_824
      }
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns a fixture for BIP9 statistics.
  """
  @spec bip9_statistics_fixture(map()) :: map()
  def bip9_statistics_fixture(overrides \\ %{}) do
    %{
      "period" => 2016,
      "threshold" => 1916,
      "elapsed" => 1000,
      "count" => 1850,
      "possible" => true
    }
    |> deep_merge(overrides)
  end

  ## Private functions for GetBlockchainInfo

  defp default_blockchain_info_fixture do
    %{
      "chain" => "regtest",
      "blocks" => 150,
      "headers" => 150,
      "bestblockhash" => "0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcdef",
      "difficulty" => 4.656542373906925e-10,
      "mediantime" => 1_640_995_200,
      "verificationprogress" => 1.0,
      "initialblockdownload" => false,
      "chainwork" => "0000000000000000000000000000000000000000000000000000012e012e012e",
      "size_on_disk" => 45_123,
      "pruned" => false,
      "softforks" => %{
        "csv" => buried_softfork_fixture(%{"height" => 0}),
        "segwit" => buried_softfork_fixture(%{"height" => 0}),
        "taproot" =>
          bip9_softfork_fixture(%{
            "height" => 709_632,
            "bip9" => %{
              "status" => "active",
              "start_time" => 1_619_222_400,
              "timeout" => 1_628_640_000,
              "since" => 709_632
            }
          })
      },
      "warnings" => ""
    }
  end

  defp mainnet_overrides do
    %{
      "chain" => "main",
      "blocks" => 750_000,
      "headers" => 750_000,
      "bestblockhash" => "00000000000000000008a89e854d57e5667df88f1cdef6fde2fbca1de5b639ad",
      "difficulty" => 30_283_852_313_128.25,
      "mediantime" => 1_640_995_200,
      "verificationprogress" => 0.9999,
      "initialblockdownload" => false,
      "chainwork" => "00000000000000000000000000000000000000001f057509fecbf3e4baffffff",
      "size_on_disk" => 445_123_456_789,
      "pruned" => false
    }
  end

  defp testnet_overrides do
    %{
      "chain" => "test",
      "blocks" => 2_100_000,
      "headers" => 2_100_000,
      "bestblockhash" => "00000000000001a2b3c4d5e6f789abcdef0123456789abcdef0123456789abcdef",
      "difficulty" => 21_434_395_961_348.92,
      "mediantime" => 1_640_995_200,
      "verificationprogress" => 1.0,
      "initialblockdownload" => false,
      "chainwork" => "000000000000000000000000000000000000000014a2b3c4d5e6f789abcdef01",
      "size_on_disk" => 25_123_456_789,
      "pruned" => false
    }
  end

  defp pruned_overrides do
    %{
      "pruned" => true,
      "pruneheight" => 500_000,
      "automatic_pruning" => true,
      "prune_target_size" => 5500,
      "size_on_disk" => 5_500_000_000
    }
  end

  defp syncing_overrides do
    %{
      "blocks" => 700_000,
      "headers" => 750_000,
      "verificationprogress" => 0.8543,
      "initialblockdownload" => true,
      "warnings" =>
        "Warning: We do not appear to fully agree with our peers! You may need to upgrade, or other nodes may need to upgrade."
    }
  end
end
