defmodule BTx.WalletsFixtures do
  @moduledoc """
  Test fixtures for Bitcoin RPC responses and test data.
  """

  ## GetTransaction result

  @doc """
  Returns a fixture for gettransaction RPC result.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default receive transaction
      get_transaction_result_fixture()

      # Override amount and confirmations
      get_transaction_result_fixture(%{
        "amount" => 1.5,
        "confirmations" => 10
      })

      # Send transaction
      get_transaction_result_fixture(%{
        "amount" => -0.5,
        "fee" => -0.0001,
        "details" => [%{
          "category" => "send",
          "amount" => -0.5,
          "address" => "bc1qexample...",
          "fee" => -0.0001
        }]
      })

      # Unconfirmed transaction
      get_transaction_result_fixture(%{
        "confirmations" => 0,
        "trusted" => false,
        "blockhash" => nil,
        "blockheight" => nil,
        "blockindex" => nil,
        "blocktime" => nil
      })

      # Coinbase transaction
      get_transaction_result_fixture(%{
        "amount" => 6.25,
        "generated" => true,
        "confirmations" => 150,
        "details" => [%{
          "category" => "generate",
          "amount" => 6.25
        }]
      })

  """
  @spec get_transaction_result_fixture(map()) :: map()
  def get_transaction_result_fixture(overrides \\ %{}) do
    default_fixture()
    |> deep_merge(overrides)
  end

  @doc """
  Returns preset fixtures for common transaction types.

  ## Examples

      get_transaction_preset(:receive)
      get_transaction_preset(:send)
      get_transaction_preset(:coinbase)
      get_transaction_preset(:unconfirmed)

  """
  @spec get_transaction_preset(atom()) :: map()
  def get_transaction_preset(type) do
    case type do
      :receive -> get_transaction_result_fixture()
      :send -> get_transaction_result_fixture(send_overrides())
      :coinbase -> get_transaction_result_fixture(coinbase_overrides())
      :unconfirmed -> get_transaction_result_fixture(unconfirmed_overrides())
    end
  end

  ## Private functions

  defp default_fixture do
    %{
      "amount" => 0.05000000,
      "fee" => -0.00001000,
      "confirmations" => 6,
      "generated" => false,
      "trusted" => true,
      "blockhash" => "0000000000000000000a1b2c3d4e5f6789abcdef0123456789abcdef01234567",
      "blockheight" => 750_123,
      "blockindex" => 2,
      "blocktime" => 1_698_765_432,
      "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      "walletconflicts" => [],
      "time" => 1_698_765_400,
      "timereceived" => 1_698_765_405,
      "comment" => "Payment for services",
      "bip125-replaceable" => "no",
      "details" => [
        %{
          "involvesWatchonly" => false,
          "address" => "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
          "category" => "receive",
          "amount" => 0.05000000,
          "label" => "Customer Payment",
          "vout" => 0,
          "fee" => nil,
          "abandoned" => false
        }
      ],
      "hex" =>
        "02000000010123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef000000006a47304402203c2a7d8c8a4b5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1021034567890abcdef0123456789abcdef0123456789abcdef0123456789abcdef01ffffffff0200f2052a0100000017a914abcdef0123456789abcdef0123456789abcdef012387e8030000000000001976a914fedcba9876543210fedcba9876543210fedcba9888ac00000000",
      "decoded" => %{
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "hash" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "version" => 2,
        "size" => 225,
        "vsize" => 225,
        "weight" => 900,
        "locktime" => 0,
        "vin" => [
          %{
            "txid" => "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
            "vout" => 0,
            "scriptSig" => %{
              "asm" =>
                "304402203c2a7d8c8a4b5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f[ALL] 034567890abcdef0123456789abcdef0123456789abcdef0123456789abcdef01",
              "hex" =>
                "47304402203c2a7d8c8a4b5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1021034567890abcdef0123456789abcdef0123456789abcdef0123456789abcdef01"
            },
            "sequence" => 4_294_967_295
          }
        ],
        "vout" => [
          %{
            "value" => 0.05000000,
            "n" => 0,
            "scriptPubKey" => %{
              "asm" => "OP_HASH160 abcdef0123456789abcdef0123456789abcdef0123 OP_EQUAL",
              "desc" => "addr(3GzfQq5B4Zx8GWLG3ZpGQf1cKo5XcY2p1A)#checksum",
              "hex" => "a914abcdef0123456789abcdef0123456789abcdef012387",
              "address" => "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
              "type" => "scripthash"
            }
          },
          %{
            "value" => 0.00100000,
            "n" => 1,
            "scriptPubKey" => %{
              "asm" =>
                "OP_DUP OP_HASH160 fedcba9876543210fedcba9876543210fedcba98 OP_EQUALVERIFY OP_CHECKSIG",
              "desc" => "addr(1QHK8pRYKK1J2mDtFmHVn2nqwC6QbJp8z9)#checksum",
              "hex" => "76a914fedcba9876543210fedcba9876543210fedcba9888ac",
              "address" => "1QHK8pRYKK1J2mDtFmHVn2nqwC6QbJp8z9",
              "type" => "pubkeyhash"
            }
          }
        ]
      }
    }
  end

  defp send_overrides do
    %{
      "amount" => -0.10000000,
      "fee" => -0.00002500,
      "confirmations" => 12,
      "blockhash" => "00000000000000000008a1b2c3d4e5f6789abcdef0123456789abcdef0123456",
      "blockheight" => 750_150,
      "blockindex" => 1,
      "blocktime" => 1_698_766_000,
      "txid" => "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
      "time" => 1_698_765_950,
      "timereceived" => 1_698_765_952,
      "comment" => "Payment to vendor",
      "bip125-replaceable" => "yes",
      "details" => [
        %{
          "involvesWatchonly" => false,
          "address" => "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
          "category" => "send",
          "amount" => -0.10000000,
          "label" => "Vendor Payment",
          "vout" => 0,
          "fee" => -0.00002500,
          "abandoned" => false
        }
      ]
    }
  end

  defp coinbase_overrides do
    %{
      "amount" => 6.25000000,
      "fee" => nil,
      "confirmations" => 150,
      "generated" => true,
      "blockhash" => "00000000000000000001a1b2c3d4e5f6789abcdef0123456789abcdef0123456",
      "blockheight" => 750_000,
      "blockindex" => 0,
      "blocktime" => 1_698_760_000,
      "txid" => "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
      "time" => 1_698_760_000,
      "timereceived" => 1_698_760_001,
      "comment" => nil,
      "bip125-replaceable" => "no",
      "details" => [
        %{
          "involvesWatchonly" => false,
          "address" => "bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297",
          "category" => "generate",
          "amount" => 6.25000000,
          "label" => "Mining Reward",
          "vout" => 0,
          "fee" => nil,
          "abandoned" => nil
        }
      ]
    }
  end

  defp unconfirmed_overrides do
    %{
      "amount" => 0.02000000,
      "fee" => nil,
      "confirmations" => 0,
      "trusted" => false,
      "blockhash" => nil,
      "blockheight" => nil,
      "blockindex" => nil,
      "blocktime" => nil,
      "txid" => "567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234",
      "time" => 1_698_767_000,
      "timereceived" => 1_698_767_005,
      "comment" => "Pending payment",
      "bip125-replaceable" => "unknown",
      "details" => [
        %{
          "involvesWatchonly" => false,
          "address" => "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
          "category" => "receive",
          "amount" => 0.02000000,
          "label" => "Pending Payment",
          "vout" => 0,
          "fee" => nil,
          "abandoned" => false
        }
      ]
    }
  end

  # Deep merge helper function
  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, left, right) when is_map(left) and is_map(right) do
    deep_merge(left, right)
  end

  defp deep_resolve(_key, _left, right) do
    right
  end
end
