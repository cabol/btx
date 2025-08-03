defmodule BTx.WalletsFixtures do
  @moduledoc """
  Test fixtures for Bitcoin RPC responses and test data.
  """

  import BTx.TestUtils

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

  ## GetAddressInfo result

  @doc """
  Returns a fixture for getaddressinfo RPC result.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default bech32 address info
      get_address_info_result_fixture()

      # Override address and ownership
      get_address_info_result_fixture(%{
        "address" => "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
        "ismine" => false,
        "iswitness" => false
      })

      # Multisig address info
      get_address_info_result_fixture(%{
        "address" => "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
        "isscript" => true,
        "script" => "multisig",
        "sigsrequired" => 2,
        "pubkeys" => ["033add1f0e...", "033b3636a8..."]
      })

      # Watch-only address
      get_address_info_result_fixture(%{
        "ismine" => false,
        "iswatchonly" => true,
        "labels" => ["watch_only"]
      })

  """
  @spec get_address_info_result_fixture(map()) :: map()
  def get_address_info_result_fixture(overrides \\ %{}) do
    default_address_info_fixture()
    |> deep_merge(overrides)
  end

  @doc """
  Returns preset fixtures for common address info types.

  ## Examples

      get_address_info_preset(:bech32)
      get_address_info_preset(:legacy)
      get_address_info_preset(:p2sh)
      get_address_info_preset(:multisig)
      get_address_info_preset(:watch_only)
      get_address_info_preset(:embedded_witness)

  """
  @spec get_address_info_preset(atom()) :: map()
  def get_address_info_preset(type) do
    case type do
      :bech32 -> get_address_info_result_fixture()
      :legacy -> get_address_info_result_fixture(legacy_overrides())
      :p2sh -> get_address_info_result_fixture(p2sh_overrides())
      :multisig -> get_address_info_result_fixture(multisig_overrides())
      :watch_only -> get_address_info_result_fixture(watch_only_overrides())
      :embedded_witness -> get_address_info_result_fixture(embedded_witness_overrides())
    end
  end

  ## Private functions for GetAddressInfo

  defp default_address_info_fixture do
    %{
      "address" => "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      "scriptPubKey" => "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
      "ismine" => true,
      "iswatchonly" => false,
      "solvable" => true,
      "desc" =>
        "wpkh([d34db33f/0'/0'/0']03a34b99f22c790c4e36b2b3c2c35a36db06226e41c692fc82b8b56ac1c540c5bd)#8fhd9pwu",
      "isscript" => false,
      "ischange" => false,
      "iswitness" => true,
      "witness_version" => 0,
      "witness_program" => "389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
      "pubkey" => "03a34b99f22c790c4e36b2b3c2c35a36db06226e41c692fc82b8b56ac1c540c5bd",
      "iscompressed" => true,
      "timestamp" => 1_640_995_200,
      "hdkeypath" => "m/0'/0'/0'",
      "hdseedid" => "d34db33f",
      "hdmasterfingerprint" => "d34db33f",
      "labels" => [""]
    }
  end

  defp legacy_overrides do
    %{
      "address" => "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
      "scriptPubKey" => "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac",
      "ismine" => false,
      "solvable" => true,
      "desc" => nil,
      "iswitness" => false,
      "witness_version" => nil,
      "witness_program" => nil,
      "labels" => []
    }
  end

  defp p2sh_overrides do
    %{
      "address" => "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
      "scriptPubKey" => "a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2687",
      "isscript" => true,
      "iswitness" => false,
      "witness_version" => nil,
      "witness_program" => nil,
      "script" => "scripthash",
      "labels" => []
    }
  end

  defp multisig_overrides do
    %{
      "address" => "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
      "scriptPubKey" => "a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2687",
      "isscript" => true,
      "iswitness" => false,
      "witness_version" => nil,
      "witness_program" => nil,
      "script" => "multisig",
      "hex" =>
        "5221033add1f0e8e3c3e5119d0e274283c498d149df99d98ac93724d6a5b3c4c589d0ae5121033b3636a87b7c9bb1a6c17c0f9aee64c3b8b6b87b8a5a7b1c8c5b9b2d6f3a1b2f52ae",
      "pubkeys" => [
        "033add1f0e8e3c3e5119d0e274283c498d149df99d98ac93724d6a5b3c4c589d0ae51",
        "033b3636a87b7c9bb1a6c17c0f9aee64c3b8b6b87b8a5a7b1c8c5b9b2d6f3a1b2f"
      ],
      "sigsrequired" => 2,
      "labels" => ["multisig_wallet"]
    }
  end

  defp watch_only_overrides do
    %{
      "ismine" => false,
      "iswatchonly" => true,
      "desc" => nil,
      "timestamp" => nil,
      "hdkeypath" => nil,
      "hdseedid" => nil,
      "hdmasterfingerprint" => nil,
      "labels" => ["watch_only"]
    }
  end

  defp embedded_witness_overrides do
    %{
      "address" => "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
      "scriptPubKey" => "a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2687",
      "isscript" => true,
      "iswitness" => false,
      "witness_version" => nil,
      "witness_program" => nil,
      "script" => "witness_v0_keyhash",
      "embedded" => %{
        "address" => "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
        "scriptPubKey" => "0014751e76dc81",
        "isscript" => false,
        "iswitness" => true,
        "witness_version" => 0,
        "witness_program" => "751e76dc81"
      },
      "labels" => []
    }
  end

  ## ListUnspent fixtures

  @doc """
  Returns a fixture for listunspent RPC result item.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default unspent output
      list_unspent_item_fixture()

      # Override amount and confirmations
      list_unspent_item_fixture(%{
        "amount" => 1.50000000,
        "confirmations" => 100
      })

      # P2SH output with redeem script
      list_unspent_item_fixture(%{
        "address" => "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
        "redeemScript" => "522103abc...52ae",
        "spendable" => false
      })

      # Watch-only output
      list_unspent_item_fixture(%{
        "spendable" => false,
        "solvable" => true,
        "safe" => true
      })

  """
  @spec list_unspent_item_fixture(map()) :: map()
  def list_unspent_item_fixture(overrides \\ %{}) do
    default_unspent_item_fixture()
    |> deep_merge(overrides)
  end

  @doc """
  Returns preset fixtures for common unspent output types.

  ## Examples

      list_unspent_preset(:confirmed)
      list_unspent_preset(:unconfirmed)
      list_unspent_preset(:large_amount)
      list_unspent_preset(:p2sh)
      list_unspent_preset(:watch_only)
      list_unspent_preset(:unsafe)

  """
  @spec list_unspent_preset(atom()) :: map()
  def list_unspent_preset(type) do
    case type do
      :confirmed -> list_unspent_item_fixture()
      :unconfirmed -> list_unspent_item_fixture(list_unspent_unconfirmed_overrides())
      :large_amount -> list_unspent_item_fixture(large_amount_overrides())
      :p2sh -> list_unspent_item_fixture(p2sh_unspent_overrides())
      :watch_only -> list_unspent_item_fixture(watch_only_unspent_overrides())
      :unsafe -> list_unspent_item_fixture(unsafe_overrides())
    end
  end

  @doc """
  Returns a list of unspent output fixtures.

  ## Examples

      # Default list with various outputs
      list_unspent_list_fixture()

      # Custom list
      list_unspent_list_fixture([
        list_unspent_preset(:confirmed),
        list_unspent_preset(:unconfirmed)
      ])

  """
  @spec list_unspent_list_fixture(list() | nil) :: [map()]
  def list_unspent_list_fixture(custom_items \\ nil) do
    custom_items ||
      [
        list_unspent_preset(:confirmed),
        list_unspent_preset(:unconfirmed),
        list_unspent_preset(:large_amount)
      ]
  end

  ## Private functions for ListUnspent

  defp default_unspent_item_fixture do
    %{
      "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      "vout" => 0,
      "address" => "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl",
      "label" => "",
      "scriptPubKey" => "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
      "amount" => 0.05000000,
      "confirmations" => 6,
      "spendable" => true,
      "solvable" => true,
      "desc" =>
        "wpkh([d34db33f/0'/0'/0']03a34b99f22c790c4e36b2b3c2c35a36db06226e41c692fc82b8b56ac1c540c5bd)#8fhd9pwu",
      "safe" => true
    }
  end

  defp list_unspent_unconfirmed_overrides do
    %{
      "txid" => "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
      "vout" => 1,
      "address" => "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
      "scriptPubKey" => "0014751e76dc81",
      "amount" => 0.01000000,
      "confirmations" => 0,
      "safe" => false
    }
  end

  defp large_amount_overrides do
    %{
      "txid" => "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
      "vout" => 2,
      "address" => "bc1q02ad21edsxd23d32dfgqqsz4vv4nmtfzuklhy3",
      "scriptPubKey" => "001403ad21edsxd23d32dfgqqsz4vv4nmtfzuklhy3",
      "amount" => 1.50000000,
      "confirmations" => 100,
      "label" => "savings"
    }
  end

  defp p2sh_unspent_overrides do
    %{
      "txid" => "9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba",
      "vout" => 0,
      "address" => "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
      "scriptPubKey" => "a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2687",
      "amount" => 0.25000000,
      "confirmations" => 50,
      "redeemScript" =>
        "5221033add1f0e8e3c3e5119d0e274283c498d149df99d98ac93724d6a5b3c4c589d0ae5121033b3636a87b7c9bb1a6c17c0f9aee64c3b8b6b87b8a5a7b1c8c5b9b2d6f3a1b2f52ae",
      "witnessScript" =>
        "5221033add1f0e8e3c3e5119d0e274283c498d149df99d98ac93724d6a5b3c4c589d0ae5121033b3636a87b7c9bb1a6c17c0f9aee64c3b8b6b87b8a5a7b1c8c5b9b2d6f3a1b2f52ae",
      "spendable" => true,
      "solvable" => true,
      "desc" => "sh(multi(2,03add1f0e8e3c...,033b3636a87b...))#xyz123ab",
      "safe" => true
    }
  end

  defp watch_only_unspent_overrides do
    %{
      "txid" => "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      "vout" => 3,
      "address" => "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
      "scriptPubKey" => "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac",
      "amount" => 0.10000000,
      "confirmations" => 25,
      "spendable" => false,
      "solvable" => true,
      "desc" => nil,
      "safe" => true,
      "label" => "watch_only"
    }
  end

  defp unsafe_overrides do
    %{
      "txid" => "deadbeef12345678deadbeef12345678deadbeef12345678deadbeef12345678",
      "vout" => 1,
      "address" => "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
      "scriptPubKey" => "0014e8df018c7e326cc253faac7e46cdc51e68542c42",
      "amount" => 0.02500000,
      "confirmations" => 1,
      "spendable" => true,
      "solvable" => true,
      "safe" => false,
      "label" => "unsafe_tx"
    }
  end

  ## GetAddressesByLabel fixtures

  @doc """
  Returns a fixture for getaddressesbylabel RPC result.

  Returns a map where keys are Bitcoin addresses and values are maps with purpose info.

  ## Options

  You can override the default addresses by passing a map with custom addresses:

  ## Examples

      # Default addresses for a label
      get_addresses_by_label_result_fixture()

      # Custom addresses
      get_addresses_by_label_result_fixture(%{
        "1MyCustomAddress123" => %{"purpose" => "send"},
        "bc1qcustomaddress456" => %{"purpose" => "receive"}
      })

      # Empty result (no addresses for label)
      get_addresses_by_label_result_fixture(%{})

  """
  @spec get_addresses_by_label_result_fixture(map() | nil) :: map()
  def get_addresses_by_label_result_fixture(overrides \\ nil) do
    overrides || default_addresses_by_label_fixture()
  end

  @doc """
  Returns preset fixtures for common address label scenarios.

  ## Examples

      get_addresses_by_label_preset(:mixed_purposes)
      get_addresses_by_label_preset(:receive_only)
      get_addresses_by_label_preset(:send_only)
      get_addresses_by_label_preset(:empty)

  """
  @spec get_addresses_by_label_preset(atom()) :: map()
  def get_addresses_by_label_preset(type) do
    case type do
      :mixed_purposes -> get_addresses_by_label_result_fixture()
      :receive_only -> get_addresses_by_label_result_fixture(receive_only_addresses())
      :send_only -> get_addresses_by_label_result_fixture(send_only_addresses())
      :empty -> get_addresses_by_label_result_fixture(%{})
    end
  end

  ## Private functions for GetAddressesByLabel

  defp default_addresses_by_label_fixture do
    %{
      "bc1qxyz8a7zv50vvv4cnz0g44ux6a6q7gfqq0w0uhx" => %{"purpose" => "receive"},
      "bc1qkl4c9j8f8vy4h9kk9pr5n7frwx30r9kvppnnxz" => %{"purpose" => "receive"},
      "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2" => %{"purpose" => "send"},
      "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy" => %{"purpose" => "send"}
    }
  end

  defp receive_only_addresses do
    %{
      "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl" => %{"purpose" => "receive"},
      "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4" => %{"purpose" => "receive"},
      "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq" => %{"purpose" => "receive"}
    }
  end

  defp send_only_addresses do
    %{
      "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa" => %{"purpose" => "send"},
      "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2" => %{"purpose" => "send"}
    }
  end

  ## SignRawTransactionWithWallet fixtures

  @doc """
  Returns a fixture for signrawtransactionwithwallet request.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default request
      sign_raw_transaction_with_wallet_request_fixture()

      # Override specific fields
      sign_raw_transaction_with_wallet_request_fixture(%{
        "sighashtype" => "SINGLE",
        "wallet_name" => "custom_wallet"
      })

      # With previous transactions
      sign_raw_transaction_with_wallet_request_fixture(%{
        "prevtxs" => [
          %{
            "txid" => "abc123...",
            "vout" => 0,
            "scriptPubKey" => "76a914...",
            "amount" => 0.01
          }
        ]
      })

  """
  @spec sign_raw_transaction_with_wallet_request_fixture(map()) :: map()
  def sign_raw_transaction_with_wallet_request_fixture(overrides \\ %{}) do
    %{
      "hexstring" =>
        "0200000001abc123def456789abc123def456789abc123def456789abc123def456789ab00000000ffffffff0100e1f50500000000160014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2600000000",
      "prevtxs" => [],
      "sighashtype" => "ALL",
      "wallet_name" => "test_wallet"
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns a fixture for signrawtransactionwithwallet result.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default successful result
      sign_raw_transaction_with_wallet_result_fixture()

      # Override specific fields
      sign_raw_transaction_with_wallet_result_fixture(%{
        "complete" => false,
        "errors" => [
          %{
            "txid" => "abc123...",
            "vout" => 0,
            "error" => "Input not found or already spent"
          }
        ]
      })

      # Incomplete transaction
      sign_raw_transaction_with_wallet_result_fixture(%{
        "complete" => false
      })

  """
  @spec sign_raw_transaction_with_wallet_result_fixture(map()) :: map()
  def sign_raw_transaction_with_wallet_result_fixture(overrides \\ %{}) do
    %{
      "hex" =>
        "0200000001abc123def456789abc123def456789abc123def456789abc123def456789ab00000000484730440220123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef01022012345678901234567890123456789012345678901234567890123456789012340121023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456ffffffff0100e1f50500000000160014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2600000000",
      "complete" => true,
      "errors" => []
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns preset fixtures for common signrawtransactionwithwallet scenarios.

  ## Examples

      sign_raw_transaction_with_wallet_preset(:successful)
      sign_raw_transaction_with_wallet_preset(:incomplete)
      sign_raw_transaction_with_wallet_preset(:with_errors)
      sign_raw_transaction_with_wallet_preset(:with_prevtxs)

  """
  @spec sign_raw_transaction_with_wallet_preset(atom()) :: map()
  def sign_raw_transaction_with_wallet_preset(type) do
    case type do
      :successful -> sign_raw_transaction_with_wallet_result_fixture()
      :incomplete -> sign_raw_transaction_with_wallet_result_fixture(incomplete_overrides())
      :with_errors -> sign_raw_transaction_with_wallet_result_fixture(with_errors_overrides())
      :with_prevtxs -> sign_raw_transaction_with_wallet_request_fixture(with_prevtxs_overrides())
    end
  end

  ## Private functions

  defp incomplete_overrides do
    %{
      "complete" => false,
      "hex" =>
        "0200000001abc123def456789abc123def456789abc123def456789abc123def456789ab00000000ffffffff0100e1f50500000000160014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2600000000"
    }
  end

  defp with_errors_overrides do
    %{
      "complete" => false,
      "errors" => [
        %{
          "txid" => "abc123def456789abc123def456789abc123def456789abc123def456789ab",
          "vout" => 0,
          "scriptSig" =>
            "47304402203c2a7d8c8a4b5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1021034567890abcdef0123456789abcdef0123456789abcdef0123456789abcdef01",
          "sequence" => 4_294_967_295,
          "error" => "Input not found or already spent"
        }
      ]
    }
  end

  defp with_prevtxs_overrides do
    %{
      "prevtxs" => [
        %{
          "txid" => "abc123def456789abc123def456789abc123def456789abc123def456789ab",
          "vout" => 0,
          "scriptPubKey" => "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac",
          "redeemScript" =>
            "5221023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456",
          "amount" => 0.01000000
        }
      ]
    }
  end
end
