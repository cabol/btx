defmodule BTx.RPC.Mining.GenerateToAddressTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Mining, Request, Wallets}
  alias BTx.RPC.Mining.GenerateToAddress
  alias Ecto.{Changeset, UUID}

  # Valid Bitcoin addresses for testing
  @valid_legacy_address "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
  @valid_p2sh_address "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
  @valid_bech32_address "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
  @valid_testnet_address "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"
  @valid_regtest_address "bcrt1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a GenerateToAddress with required fields" do
      assert {:ok,
              %GenerateToAddress{
                nblocks: 10,
                address: @valid_bech32_address,
                maxtries: 1_000_000
              }} = GenerateToAddress.new(nblocks: 10, address: @valid_bech32_address)
    end

    test "creates a GenerateToAddress with all parameters" do
      assert {:ok,
              %GenerateToAddress{
                nblocks: 5,
                address: @valid_legacy_address,
                maxtries: 500_000
              }} =
               GenerateToAddress.new(
                 nblocks: 5,
                 address: @valid_legacy_address,
                 maxtries: 500_000
               )
    end

    test "uses default value for maxtries" do
      assert {:ok, %GenerateToAddress{maxtries: 1_000_000}} =
               GenerateToAddress.new(nblocks: 1, address: @valid_bech32_address)
    end

    test "accepts valid Bitcoin address types" do
      valid_addresses = [
        @valid_legacy_address,
        @valid_p2sh_address,
        @valid_bech32_address,
        @valid_testnet_address,
        @valid_regtest_address
      ]

      for address <- valid_addresses do
        assert {:ok, %GenerateToAddress{address: ^address}} =
                 GenerateToAddress.new(nblocks: 1, address: address)
      end
    end

    test "accepts valid nblocks values" do
      valid_nblocks = [1, 10, 100, 1000]

      for nblocks <- valid_nblocks do
        assert {:ok, %GenerateToAddress{nblocks: ^nblocks}} =
                 GenerateToAddress.new(nblocks: nblocks, address: @valid_bech32_address)
      end
    end

    test "accepts valid maxtries values" do
      valid_maxtries = [1, 100, 1000, 500_000, 1_000_000, 10_000_000]

      for maxtries <- valid_maxtries do
        assert {:ok, %GenerateToAddress{maxtries: ^maxtries}} =
                 GenerateToAddress.new(
                   nblocks: 1,
                   address: @valid_bech32_address,
                   maxtries: maxtries
                 )
      end
    end

    test "returns error for missing nblocks" do
      assert {:error, %Changeset{errors: errors}} =
               GenerateToAddress.new(address: @valid_bech32_address)

      assert Keyword.fetch!(errors, :nblocks) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for missing address" do
      assert {:error, %Changeset{errors: errors}} = GenerateToAddress.new(nblocks: 10)

      assert Keyword.fetch!(errors, :address) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for both missing required fields" do
      assert {:error, %Changeset{errors: errors}} = GenerateToAddress.new(%{})

      assert Keyword.fetch!(errors, :nblocks) == {"can't be blank", [{:validation, :required}]}
      assert Keyword.fetch!(errors, :address) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for invalid nblocks values" do
      invalid_nblocks = [0, -1, -10]

      for nblocks <- invalid_nblocks do
        assert {:error, %Changeset{errors: errors}} =
                 GenerateToAddress.new(nblocks: nblocks, address: @valid_bech32_address)

        assert Keyword.fetch!(errors, :nblocks) ==
                 {"must be greater than %{number}",
                  [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}
      end
    end

    test "returns error for invalid maxtries values" do
      invalid_maxtries = [0, -1, -100]

      for maxtries <- invalid_maxtries do
        assert {:error, %Changeset{errors: errors}} =
                 GenerateToAddress.new(
                   nblocks: 1,
                   address: @valid_bech32_address,
                   maxtries: maxtries
                 )

        assert Keyword.fetch!(errors, :maxtries) ==
                 {"must be greater than %{number}",
                  [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}
      end
    end

    test "returns error for invalid address" do
      invalid_addresses = [
        # Too short
        "1abc",
        # Too long
        String.duplicate("bc1q", 30),
        # Invalid characters for Base58
        "1InvalidChars0OIl",
        # Empty string
        ""
      ]

      for address <- invalid_addresses do
        assert {:error, %Changeset{} = changeset} =
                 GenerateToAddress.new(nblocks: 1, address: address)

        assert changeset.errors[:address] != nil
      end
    end

    test "returns error for address too short" do
      short_address = "1abc"

      assert {:error, %Changeset{} = changeset} =
               GenerateToAddress.new(nblocks: 1, address: short_address)

      assert "should be at least 26 character(s)" in errors_on(changeset).address
    end

    test "returns error for address too long" do
      long_address = String.duplicate("bc1q", 30)

      assert {:error, %Changeset{} = changeset} =
               GenerateToAddress.new(nblocks: 1, address: long_address)

      assert "should be at most 90 character(s)" in errors_on(changeset).address
    end

    test "accepts address at minimum valid length" do
      # Minimum valid Bitcoin address length
      min_address = String.duplicate("1", 26)

      assert {:ok, %GenerateToAddress{address: ^min_address}} =
               GenerateToAddress.new(nblocks: 1, address: min_address)
    end

    test "accepts address at maximum valid length" do
      # Maximum valid Bitcoin address length
      # 90 chars
      max_address = String.duplicate("bc1q", 22) <> "12"

      assert {:ok, %GenerateToAddress{address: ^max_address}} =
               GenerateToAddress.new(nblocks: 1, address: max_address)
    end

    test "returns multiple errors for multiple invalid fields" do
      assert {:error, %Changeset{errors: errors}} =
               GenerateToAddress.new(nblocks: -1, address: "invalid", maxtries: 0)

      assert Keyword.fetch!(errors, :nblocks) ==
               {"must be greater than %{number}",
                [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}

      assert Keyword.fetch!(errors, :maxtries) ==
               {"must be greater than %{number}",
                [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}

      assert errors[:address] != nil
    end
  end

  describe "new!/1" do
    test "creates a GenerateToAddress with required fields" do
      assert %GenerateToAddress{nblocks: 10, address: @valid_bech32_address} =
               GenerateToAddress.new!(nblocks: 10, address: @valid_bech32_address)
    end

    test "creates a GenerateToAddress with all options" do
      assert %GenerateToAddress{
               nblocks: 5,
               address: @valid_legacy_address,
               maxtries: 500_000
             } =
               GenerateToAddress.new!(
                 nblocks: 5,
                 address: @valid_legacy_address,
                 maxtries: 500_000
               )
    end

    test "raises error for invalid nblocks" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GenerateToAddress.new!(nblocks: 0, address: @valid_bech32_address)
      end
    end

    test "raises error for invalid address" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GenerateToAddress.new!(nblocks: 1, address: "invalid")
      end
    end

    test "raises error for missing required fields" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GenerateToAddress.new!([])
      end
    end

    test "raises error for multiple validation failures" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GenerateToAddress.new!(nblocks: -1, address: "invalid", maxtries: 0)
      end
    end
  end

  describe "encodable" do
    test "encodes method with required fields only" do
      assert %Request{
               params: [10, @valid_bech32_address, 1_000_000],
               method: "generatetoaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               GenerateToAddress.new!(nblocks: 10, address: @valid_bech32_address)
               |> Encodable.encode()
    end

    test "encodes method with custom maxtries" do
      assert %Request{
               params: [5, @valid_legacy_address, 500_000],
               method: "generatetoaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               GenerateToAddress.new!(
                 nblocks: 5,
                 address: @valid_legacy_address,
                 maxtries: 500_000
               )
               |> Encodable.encode()
    end

    test "encodes method with all address types" do
      addresses = [
        @valid_legacy_address,
        @valid_p2sh_address,
        @valid_bech32_address,
        @valid_testnet_address,
        @valid_regtest_address
      ]

      for address <- addresses do
        encoded =
          GenerateToAddress.new!(nblocks: 1, address: address)
          |> Encodable.encode()

        assert encoded.params == [1, address, 1_000_000]
        assert encoded.method == "generatetoaddress"
        assert encoded.path == "/"
      end
    end

    test "encodes method with minimum values" do
      assert %Request{
               params: [1, @valid_bech32_address, 1],
               method: "generatetoaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               GenerateToAddress.new!(
                 nblocks: 1,
                 address: @valid_bech32_address,
                 maxtries: 1
               )
               |> Encodable.encode()
    end

    test "encodes method with large values" do
      assert %Request{
               params: [1000, @valid_bech32_address, 10_000_000],
               method: "generatetoaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               GenerateToAddress.new!(
                 nblocks: 1000,
                 address: @valid_bech32_address,
                 maxtries: 10_000_000
               )
               |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = GenerateToAddress.changeset(%GenerateToAddress{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).nblocks
      assert "can't be blank" in errors_on(changeset).address
    end

    test "validates nblocks is positive" do
      # Valid values
      for nblocks <- [1, 10, 100, 1000] do
        changeset =
          GenerateToAddress.changeset(%GenerateToAddress{}, %{
            nblocks: nblocks,
            address: @valid_bech32_address
          })

        assert changeset.valid?
      end

      # Invalid values
      for nblocks <- [0, -1, -10] do
        changeset =
          GenerateToAddress.changeset(%GenerateToAddress{}, %{
            nblocks: nblocks,
            address: @valid_bech32_address
          })

        refute changeset.valid?
        assert "must be greater than 0" in errors_on(changeset).nblocks
      end
    end

    test "validates maxtries is positive" do
      # Valid values
      for maxtries <- [1, 100, 500_000, 1_000_000] do
        changeset =
          GenerateToAddress.changeset(%GenerateToAddress{}, %{
            nblocks: 1,
            address: @valid_bech32_address,
            maxtries: maxtries
          })

        assert changeset.valid?
      end

      # Invalid values
      for maxtries <- [0, -1, -100] do
        changeset =
          GenerateToAddress.changeset(%GenerateToAddress{}, %{
            nblocks: 1,
            address: @valid_bech32_address,
            maxtries: maxtries
          })

        refute changeset.valid?
        assert "must be greater than 0" in errors_on(changeset).maxtries
      end
    end

    test "validates address format" do
      # Valid addresses should pass
      for address <- [@valid_legacy_address, @valid_p2sh_address, @valid_bech32_address] do
        changeset =
          GenerateToAddress.changeset(%GenerateToAddress{}, %{
            nblocks: 1,
            address: address
          })

        assert changeset.valid?
      end

      # Invalid address should fail
      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 1,
          address: "invalid"
        })

      refute changeset.valid?
      assert changeset.errors[:address] != nil
    end

    test "validates address length" do
      # Too short
      short_address = "1abc"

      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 1,
          address: short_address
        })

      refute changeset.valid?
      assert "should be at least 26 character(s)" in errors_on(changeset).address

      # Too long
      long_address = String.duplicate("bc1q", 30)

      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 1,
          address: long_address
        })

      refute changeset.valid?
      assert "should be at most 90 character(s)" in errors_on(changeset).address

      # Just right
      valid_address = @valid_bech32_address

      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 1,
          address: valid_address
        })

      assert changeset.valid?
    end

    test "accepts valid changeset data" do
      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 10,
          address: @valid_bech32_address,
          maxtries: 500_000
        })

      assert changeset.valid?
      assert Changeset.get_change(changeset, :nblocks) == 10
      assert Changeset.get_change(changeset, :address) == @valid_bech32_address
      assert Changeset.get_change(changeset, :maxtries) == 500_000
    end

    test "uses default value for maxtries when not provided" do
      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 1,
          address: @valid_bech32_address
        })

      assert changeset.valid?

      # Test that default is applied when action is performed
      {:ok, result} =
        GenerateToAddress.new(%{
          nblocks: 1,
          address: @valid_bech32_address
        })

      assert result.maxtries == 1_000_000
    end
  end

  ## GenerateToAddress RPC

  describe "(RPC) Mining.generate_to_address/3" do
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

      assert {:error, %BTx.RPC.MethodError{code: -1, message: message, reason: :misc_error}} =
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

      assert {:error,
              %BTx.RPC.MethodError{
                code: -5,
                message: message,
                reason: :invalid_address_or_key
              }} =
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

      assert {:error,
              %BTx.RPC.MethodError{
                code: -6,
                message: message,
                reason: :wallet_insufficient_funds
              }} =
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

      assert {:error,
              %BTx.RPC.MethodError{
                code: -18,
                message: message,
                reason: :wallet_not_found
              }} =
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

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
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
      real_client = new_client(retry_opts: [max_retries: 10, delay: :timer.seconds(1)])

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
               Mining.generate_to_address(
                 real_client,
                 nblocks: 1,
                 address: address
               )

      assert is_list(blocks)
      assert length(blocks) == 1
      assert Enum.all?(blocks, &is_binary/1)
      assert Enum.all?(blocks, fn block -> String.length(block) == 64 end)
    end
  end

  describe "(RPC) Mining.generate_to_address!/3" do
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

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
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

      assert_raise BTx.RPC.MethodError, ~r/Mining timeout/, fn ->
        Mining.generate_to_address!(client,
          nblocks: 100,
          address: @valid_bech32_address
        )
      end
    end
  end
end
