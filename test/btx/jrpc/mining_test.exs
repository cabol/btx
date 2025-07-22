defmodule BTx.JRPC.MiningTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.JRPC.{Mining, Wallets}
  alias Ecto.UUID

  @url "http://localhost:18443/"

  # Valid Bitcoin addresses for testing
  @valid_legacy_address "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
  @valid_p2sh_address "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
  @valid_bech32_address "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
  @valid_testnet_address "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"
  @valid_regtest_address "bcrt1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"

  describe "generate_to_address/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful mining returns block hashes", %{client: client} do
      expected_blocks = [
        "0000000000000000001a2b3c4d5e6f7890abcdef1234567890abcdef1234567890",
        "0000000000000000002b3c4d5e6f7890abcdef1234567890abcdef1234567890ab",
        "0000000000000000003c4d5e6f7890abcdef1234567890abcdef1234567890abcd"
      ]

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the method body structure
          assert %{
                   "method" => "generatetoaddress",
                   "params" => [3, @valid_bech32_address, 1_000_000],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          # Should have auto-generated ID
          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => expected_blocks,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Mining.generate_to_address(client,
                 nblocks: 3,
                 address: @valid_bech32_address
               )

      assert result == expected_blocks
      assert length(result) == 3
      assert Enum.all?(result, &is_binary/1)
    end

    test "generates single block", %{client: client} do
      single_block = ["0000000000000000001a2b3c4d5e6f7890abcdef1234567890abcdef1234567890"]

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "generatetoaddress",
                   "params" => [1, @valid_legacy_address, 1_000_000],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => single_block,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Mining.generate_to_address(client,
                 nblocks: 1,
                 address: @valid_legacy_address
               )

      assert result == single_block
      assert length(result) == 1
    end

    test "generates blocks with custom max tries", %{client: client} do
      expected_blocks = [
        "0000000000000000004d5e6f7890abcdef1234567890abcdef1234567890abcdef",
        "0000000000000000005e6f7890abcdef1234567890abcdef1234567890abcdef12"
      ]

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "generatetoaddress",
                   "params" => [2, @valid_p2sh_address, 500_000],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_blocks,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Mining.generate_to_address(client,
                 nblocks: 2,
                 address: @valid_p2sh_address,
                 maxtries: 500_000
               )

      assert result == expected_blocks
      assert length(result) == 2
    end

    test "generates blocks with high max tries", %{client: client} do
      expected_blocks = [
        "0000000000000000006f7890abcdef1234567890abcdef1234567890abcdef1234"
      ]

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "generatetoaddress",
                   "params" => [1, @valid_testnet_address, 10_000_000],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_blocks,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Mining.generate_to_address(client,
                 nblocks: 1,
                 address: @valid_testnet_address,
                 maxtries: 10_000_000
               )

      assert result == expected_blocks
    end

    test "handles mining timeout error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -1,
                "message" => "Mining timeout"
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{code: -1, message: message}} =
               Mining.generate_to_address(client,
                 nblocks: 100,
                 address: @valid_bech32_address
               )

      assert message == "Mining timeout"
    end

    test "handles invalid address error", %{client: client} do
      invalid_address = String.duplicate("1", 64)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -5,
                "message" => "Invalid Bitcoin address"
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{code: -5, message: message}} =
               Mining.generate_to_address(client,
                 nblocks: 1,
                 address: invalid_address
               )

      assert message == "Invalid Bitcoin address"
    end

    test "handles insufficient funds error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -6,
                "message" => "Insufficient funds"
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{code: -6, message: message}} =
               Mining.generate_to_address(client,
                 nblocks: 1,
                 address: @valid_bech32_address
               )

      assert message == "Insufficient funds"
    end

    test "handles wallet not found error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -18,
                "message" => "Requested wallet does not exist or is not loaded"
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{code: -18, message: message}} =
               Mining.generate_to_address(client,
                 nblocks: 1,
                 address: @valid_bech32_address
               )

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Mining.generate_to_address!(client,
          nblocks: 1,
          address: @valid_bech32_address
        )
      end
    end

    test "verifies all address types work", %{client: client} do
      address_types = [
        {@valid_legacy_address, "legacy"},
        {@valid_p2sh_address, "p2sh-segwit"},
        {@valid_bech32_address, "bech32"},
        {@valid_testnet_address, "testnet"},
        {@valid_regtest_address, "regtest"}
      ]

      for {address, type} <- address_types do
        expected_blocks = [
          "000000000000000000#{type}1234567890abcdef1234567890abcdef1234567890"
        ]

        mock(fn
          %{method: :post, url: @url, body: body} ->
            # Verify correct parameters are sent
            assert %{
                     "method" => "generatetoaddress",
                     "params" => [1, ^address, 1_000_000]
                   } = BTx.json_module().decode!(body)

            %Tesla.Env{
              status: 200,
              body: %{
                "id" => "test-id",
                "result" => expected_blocks,
                "error" => nil
              }
            }
        end)

        assert {:ok, result} =
                 Mining.generate_to_address(client,
                   nblocks: 1,
                   address: address
                 )

        assert result == expected_blocks
        assert length(result) == 1
      end
    end

    test "handles large number of blocks", %{client: client} do
      large_block_count = 100

      expected_blocks =
        for i <- 1..large_block_count do
          "000000000000000000#{String.pad_leading("#{i}", 3, "0")}1234567890abcdef1234567890abcdef1234567890"
        end

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "generatetoaddress",
                   "params" => [^large_block_count, @valid_bech32_address, 1_000_000],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_blocks,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Mining.generate_to_address(client,
                 nblocks: large_block_count,
                 address: @valid_bech32_address
               )

      assert result == expected_blocks
      assert length(result) == large_block_count
    end

    test "handles empty result (no blocks generated)", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => [],
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Mining.generate_to_address(client,
                 nblocks: 1,
                 address: @valid_bech32_address
               )

      assert result == []
    end

    test "handles malformed response data", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => "not_an_array",
              "error" => nil
            }
          }
      end)

      assert_raise RuntimeError, ~r/Expected a list, got "not_an_array"/, fn ->
        Mining.generate_to_address(client,
          nblocks: 1,
          address: @valid_bech32_address
        )
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client()

      # First ensure we have a wallet loaded, create one if needed
      wallet_name =
        Wallets.create_wallet!(
          real_client,
          wallet_name: "mining-test-#{UUID.generate()}",
          passphrase: "test"
        ).name

      # Get a new address for mining
      address = Wallets.get_new_address!(real_client, wallet_name: wallet_name)

      # Mine a block
      assert {:ok, blocks} =
               Mining.generate_to_address(real_client,
                 nblocks: 1,
                 address: address
               )

      assert is_list(blocks)
      assert length(blocks) == 1
      assert Enum.all?(blocks, &is_binary/1)
      assert Enum.all?(blocks, fn block -> String.length(block) == 64 end)
    end
  end

  describe "generate_to_address!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns block hashes", %{client: client} do
      expected_blocks = [
        "0000000000000000001a2b3c4d5e6f7890abcdef1234567890abcdef1234567890",
        "0000000000000000002b3c4d5e6f7890abcdef1234567890abcdef1234567890ab"
      ]

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_blocks,
              "error" => nil
            }
          }
      end)

      assert result =
               Mining.generate_to_address!(client,
                 nblocks: 2,
                 address: @valid_bech32_address
               )

      assert result == expected_blocks
      assert length(result) == 2
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Mining.generate_to_address!(client,
          nblocks: 1,
          address: @valid_bech32_address
        )
      end
    end

    test "raises on invalid result data", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => "not_an_array",
              "error" => nil
            }
          }
      end)

      # Should raise an error for malformed data
      assert_raise RuntimeError, ~r/Expected a list, got "not_an_array"/, fn ->
        Mining.generate_to_address!(client,
          nblocks: 1,
          address: @valid_bech32_address
        )
      end
    end

    test "raises on mining timeout", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -1,
                "message" => "Mining timeout"
              }
            }
          }
      end)

      assert_raise BTx.JRPC.MethodError, ~r/Mining timeout/, fn ->
        Mining.generate_to_address!(client,
          nblocks: 100,
          address: @valid_bech32_address
        )
      end
    end
  end
end
