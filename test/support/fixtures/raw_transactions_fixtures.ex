defmodule BTx.RawTransactionsFixtures do
  @moduledoc """
  Test fixtures for Bitcoin Raw Transaction RPC responses and test data.
  """

  import BTx.TestUtils

  ## CreateRawTransaction result

  @doc """
  Returns a fixture for createrawtransaction inputs.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default input
      create_raw_transaction_input_fixture()

      # Override specific fields
      create_raw_transaction_input_fixture(%{
        "sequence" => 1000
      })

  """
  @spec create_raw_transaction_input_fixture(map()) :: map()
  def create_raw_transaction_input_fixture(overrides \\ %{}) do
    %{
      "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      "vout" => 0,
      "sequence" => 4_294_967_295
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns a fixture for createrawtransaction address outputs.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default address output
      create_raw_transaction_address_output_fixture()

      # Override specific fields
      create_raw_transaction_address_output_fixture(%{
        "amount" => 2.5
      })

  """
  @spec create_raw_transaction_address_output_fixture(map()) :: map()
  def create_raw_transaction_address_output_fixture(overrides \\ %{}) do
    %{
      "address" => "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
      "amount" => 1.0
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns a fixture for createrawtransaction outputs.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default output with addresses
      create_raw_transaction_output_fixture()

      # Output with data
      create_raw_transaction_output_fixture(%{
        "addresses" => [],
        "data" => "deadbeef"
      })

      # Mixed output
      create_raw_transaction_output_fixture(%{
        "data" => "cafebabe"
      })

  """
  @spec create_raw_transaction_output_fixture(map()) :: map()
  def create_raw_transaction_output_fixture(overrides \\ %{}) do
    %{
      "addresses" => [create_raw_transaction_address_output_fixture()],
      "data" => nil
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns a fixture for createrawtransaction request.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default create raw transaction request
      create_raw_transaction_fixture()

      # Override specific fields
      create_raw_transaction_fixture(%{
        "locktime" => 500000,
        "replaceable" => true
      })

  """
  @spec create_raw_transaction_fixture(map()) :: map()
  def create_raw_transaction_fixture(overrides \\ %{}) do
    %{
      "inputs" => [create_raw_transaction_input_fixture()],
      "outputs" => create_raw_transaction_output_fixture(),
      "locktime" => 0,
      "replaceable" => false
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns preset fixtures for common createrawtransaction scenarios.

  ## Examples

      create_raw_transaction_preset(:address_only)
      create_raw_transaction_preset(:data_only)
      create_raw_transaction_preset(:mixed_outputs)
      create_raw_transaction_preset(:with_locktime)

  """
  @spec create_raw_transaction_preset(atom()) :: map()
  def create_raw_transaction_preset(type) do
    case type do
      :address_only -> create_raw_transaction_fixture()
      :data_only -> create_raw_transaction_fixture(data_only_overrides())
      :mixed_outputs -> create_raw_transaction_fixture(mixed_outputs_overrides())
      :with_locktime -> create_raw_transaction_fixture(with_locktime_overrides())
    end
  end

  ## Private functions for createrawtransaction presets

  defp data_only_overrides do
    %{
      "outputs" => %{
        "addresses" => [],
        "data" => "deadbeef"
      }
    }
  end

  defp mixed_outputs_overrides do
    %{
      "outputs" => %{
        "addresses" => [
          create_raw_transaction_address_output_fixture(),
          create_raw_transaction_address_output_fixture(%{
            "address" => "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
            "amount" => 0.5
          })
        ],
        "data" => "cafebabe"
      }
    }
  end

  defp with_locktime_overrides do
    %{
      "inputs" => [
        create_raw_transaction_input_fixture(%{"sequence" => 1000})
      ],
      "outputs" =>
        create_raw_transaction_output_fixture(%{
          "addresses" => [
            create_raw_transaction_address_output_fixture(%{"amount" => 2.0})
          ]
        }),
      "locktime" => 500_000,
      "replaceable" => true
    }
  end

  ## GetRawTransaction result

  @doc """
  Returns a fixture for getrawtransaction RPC result (verbose=true).

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default verbose transaction result
      get_raw_transaction_result_fixture()

      # Override specific fields
      get_raw_transaction_result_fixture(%{
        "confirmations" => 50,
        "blocktime" => 1641000000
      })

      # Transaction with multiple inputs/outputs
      get_raw_transaction_result_fixture(%{
        "vin" => [
          vin_fixture(%{"txid" => "abcd..."}),
          vin_fixture(%{"txid" => "efgh..."})
        ],
        "vout" => [
          vout_fixture(%{"value" => 1.5}),
          vout_fixture(%{"value" => 0.25, "n" => 1})
        ]
      })

  """
  @spec get_raw_transaction_result_fixture(map()) :: map()
  def get_raw_transaction_result_fixture(overrides \\ %{}) do
    default_raw_transaction_fixture()
    |> deep_merge(overrides)
  end

  @doc """
  Returns a fixture for getrawtransaction RPC result (verbose=false).

  ## Examples

      # Default hex string result
      get_raw_transaction_hex_fixture()

      # Custom hex string
      get_raw_transaction_hex_fixture("0200000001...")

  """
  @spec get_raw_transaction_hex_fixture(String.t() | nil) :: String.t()
  def get_raw_transaction_hex_fixture(hex \\ nil) do
    hex ||
      "0200000000010123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef00000000006a47304402207fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff02207fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff0121023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef012345ffffffff0200e1f50500000000160014abcdef0123456789abcdef0123456789abcdef0123456789000000000000000016001456789abcdef0123456789abcdef0123456789abcdef0100000000"
  end

  @doc """
  Returns preset fixtures for common raw transaction scenarios.

  ## Examples

      get_raw_transaction_preset(:standard)
      get_raw_transaction_preset(:coinbase)
      get_raw_transaction_preset(:multisig)
      get_raw_transaction_preset(:segwit)
      get_raw_transaction_preset(:unconfirmed)

  """
  @spec get_raw_transaction_preset(atom()) :: map()
  def get_raw_transaction_preset(type) do
    case type do
      :standard -> get_raw_transaction_result_fixture()
      :coinbase -> get_raw_transaction_result_fixture(coinbase_overrides())
      :multisig -> get_raw_transaction_result_fixture(multisig_overrides())
      :segwit -> get_raw_transaction_result_fixture(segwit_overrides())
      :unconfirmed -> get_raw_transaction_result_fixture(unconfirmed_overrides())
    end
  end

  @doc """
  Returns a fixture for a transaction input (vin).
  """
  @spec vin_fixture(map()) :: map()
  def vin_fixture(overrides \\ %{}) do
    %{
      "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      "vout" => 0,
      "scriptSig" => %{
        "asm" =>
          "304402207fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff02207fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff01 023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef012345",
        "hex" =>
          "47304402207fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff02207fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff0121023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef012345"
      },
      "sequence" => 4_294_967_295,
      "txinwitness" => []
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns a fixture for a transaction output (vout).
  """
  @spec vout_fixture(map()) :: map()
  def vout_fixture(overrides \\ %{}) do
    %{
      "value" => 1.0,
      "n" => 0,
      "scriptPubKey" => script_pub_key_fixture()
    }
    |> deep_merge(overrides)
  end

  @doc """
  Returns a fixture for a script public key.
  """
  @spec script_pub_key_fixture(map()) :: map()
  def script_pub_key_fixture(overrides \\ %{}) do
    %{
      "asm" =>
        "OP_DUP OP_HASH160 abcdef0123456789abcdef0123456789abcdef01 OP_EQUALVERIFY OP_CHECKSIG",
      "hex" => "76a914abcdef0123456789abcdef0123456789abcdef0188ac",
      "reqSigs" => 1,
      "type" => "pubkeyhash",
      "addresses" => ["1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"]
    }
    |> deep_merge(overrides)
  end

  ## Private functions

  defp default_raw_transaction_fixture do
    %{
      "in_active_chain" => true,
      "hex" => get_raw_transaction_hex_fixture(),
      "txid" => "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
      "hash" => "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
      "size" => 225,
      "vsize" => 144,
      "weight" => 573,
      "version" => 2,
      "locktime" => 0,
      "vin" => [vin_fixture()],
      "vout" => [
        vout_fixture(%{"value" => 0.99, "n" => 0}),
        vout_fixture(%{"value" => 0.01, "n" => 1})
      ],
      "blockhash" => String.duplicate("0", 64),
      "confirmations" => 100,
      "blocktime" => 1_640_995_200,
      "time" => 1_640_995_200
    }
  end

  defp coinbase_overrides do
    %{
      "vin" => [
        %{
          "coinbase" => "03abcd1234567890",
          "sequence" => 4_294_967_295,
          "txinwitness" => []
        }
      ],
      "vout" => [
        vout_fixture(%{
          "value" => 6.25,
          "n" => 0,
          "scriptPubKey" =>
            script_pub_key_fixture(%{
              "type" => "witness_v0_keyhash",
              "addresses" => ["bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"]
            })
        })
      ]
    }
  end

  defp multisig_overrides do
    %{
      "vout" => [
        vout_fixture(%{
          "scriptPubKey" =>
            script_pub_key_fixture(%{
              "asm" =>
                "2 023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef012345 02abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789ab 02fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321 3 OP_CHECKMULTISIG",
              "hex" =>
                "5221023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef01234521021234567890abcdef0123456789abcdef0123456789abcdef0123456789abcdef02134521021234567890abcdef0123456789abcdef0123456789abcdef0123456789abcdef0321353ae",
              "reqSigs" => 2,
              "type" => "multisig",
              "addresses" => [
                "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
                "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
                "1C1mCxRukix1KfegAY5zQQJV7samAciZpv"
              ]
            })
        })
      ]
    }
  end

  defp segwit_overrides do
    %{
      "vin" => [
        vin_fixture(%{
          "txinwitness" => [
            "304402207fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff02207fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff7fffffff01",
            "023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef012345"
          ]
        })
      ],
      "vout" => [
        vout_fixture(%{
          "scriptPubKey" =>
            script_pub_key_fixture(%{
              "asm" => "0 abcdef0123456789abcdef0123456789abcdef01",
              "hex" => "0014abcdef0123456789abcdef0123456789abcdef01",
              "reqSigs" => 1,
              "type" => "witness_v0_keyhash",
              "addresses" => ["bc1q40x77qfnx4ncn2ldacrxz5nkn2lnmhq5r2q2q8"]
            })
        })
      ]
    }
  end

  defp unconfirmed_overrides do
    %{
      "in_active_chain" => nil,
      "blockhash" => nil,
      "confirmations" => 0,
      "blocktime" => nil
    }
  end

  @doc """
  Returns a fixture for decoderawtransaction RPC result.

  ## Options

  You can override any field by passing a map with the desired values:

  ## Examples

      # Default decoded transaction result
      decode_raw_transaction_result_fixture()

      # Override specific fields
      decode_raw_transaction_result_fixture(%{
        "version" => 1,
        "locktime" => 500000
      })

      # Transaction with different vin/vout
      decode_raw_transaction_result_fixture(%{
        "vin" => [
          vin_fixture(%{"txid" => "abcd..."}),
          vin_fixture(%{"txid" => "efgh..."})
        ],
        "vout" => [
          vout_fixture(%{"value" => 2.5}),
          vout_fixture(%{"value" => 0.5, "n" => 1})
        ]
      })

  """
  @spec decode_raw_transaction_result_fixture(map()) :: map()
  def decode_raw_transaction_result_fixture(overrides \\ %{}) do
    %{
      "txid" => "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
      "hash" => "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
      "size" => 225,
      "vsize" => 144,
      "weight" => 573,
      "version" => 2,
      "locktime" => 0,
      "vin" => [vin_fixture()],
      "vout" => [
        vout_fixture(%{"value" => 0.99, "n" => 0}),
        vout_fixture(%{"value" => 0.01, "n" => 1})
      ]
    }
    |> deep_merge(overrides)
  end
end
