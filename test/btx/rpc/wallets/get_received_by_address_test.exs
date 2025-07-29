defmodule BTx.RPC.Wallets.GetReceivedByAddressTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.GetReceivedByAddress
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
    test "creates a new GetReceivedByAddress with required fields" do
      assert {:ok, %GetReceivedByAddress{address: @valid_bech32_address, minconf: 1}} =
               GetReceivedByAddress.new(address: @valid_bech32_address)
    end

    test "creates a new GetReceivedByAddress with all parameters" do
      assert {:ok,
              %GetReceivedByAddress{
                address: @valid_legacy_address,
                minconf: 6,
                wallet_name: "test_wallet"
              }} =
               GetReceivedByAddress.new(
                 address: @valid_legacy_address,
                 minconf: 6,
                 wallet_name: "test_wallet"
               )
    end

    test "uses default value for minconf" do
      assert {:ok, %GetReceivedByAddress{minconf: 1}} =
               GetReceivedByAddress.new(address: @valid_bech32_address)
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
        assert {:ok, %GetReceivedByAddress{address: ^address}} =
                 GetReceivedByAddress.new(address: address)
      end
    end

    test "accepts valid minconf values" do
      valid_minconf = [0, 1, 6, 100]

      for minconf <- valid_minconf do
        assert {:ok, %GetReceivedByAddress{minconf: ^minconf}} =
                 GetReceivedByAddress.new(address: @valid_bech32_address, minconf: minconf)
      end
    end

    test "accepts valid wallet names" do
      valid_names = [
        "simple",
        "wallet123",
        "my-wallet",
        "my_wallet",
        # minimum length
        "a",
        # maximum length
        String.duplicate("a", 64)
      ]

      for name <- valid_names do
        assert {:ok, %GetReceivedByAddress{wallet_name: ^name}} =
                 GetReceivedByAddress.new(address: @valid_bech32_address, wallet_name: name)
      end
    end

    test "returns error for missing address" do
      assert {:error, %Changeset{errors: errors}} = GetReceivedByAddress.new(%{})

      assert Keyword.fetch!(errors, :address) == {"can't be blank", [{:validation, :required}]}
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
                 GetReceivedByAddress.new(address: address)

        assert changeset.errors[:address] != nil
      end
    end

    test "returns error for negative minconf" do
      assert {:error, %Changeset{errors: errors}} =
               GetReceivedByAddress.new(address: @valid_bech32_address, minconf: -1)

      assert Keyword.fetch!(errors, :minconf) ==
               {"must be greater than or equal to %{number}",
                [{:validation, :number}, {:kind, :greater_than_or_equal_to}, {:number, 0}]}
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               GetReceivedByAddress.new(address: @valid_bech32_address, wallet_name: long_name)

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "returns error for address too short" do
      short_address = "1abc"

      assert {:error, %Changeset{} = changeset} =
               GetReceivedByAddress.new(address: short_address)

      assert "should be at least 26 character(s)" in errors_on(changeset).address
    end

    test "returns error for address too long" do
      long_address = String.duplicate("bc1q", 30)

      assert {:error, %Changeset{} = changeset} =
               GetReceivedByAddress.new(address: long_address)

      assert "should be at most 90 character(s)" in errors_on(changeset).address
    end
  end

  describe "new!/1" do
    test "creates a new GetReceivedByAddress with required fields" do
      assert %GetReceivedByAddress{address: @valid_bech32_address, minconf: 1} =
               GetReceivedByAddress.new!(address: @valid_bech32_address)
    end

    test "creates a new GetReceivedByAddress with all options" do
      assert %GetReceivedByAddress{
               address: @valid_legacy_address,
               minconf: 6,
               wallet_name: "test_wallet"
             } =
               GetReceivedByAddress.new!(
                 address: @valid_legacy_address,
                 minconf: 6,
                 wallet_name: "test_wallet"
               )
    end

    test "raises error for invalid address" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetReceivedByAddress.new!(address: "invalid")
      end
    end

    test "raises error for missing required fields" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetReceivedByAddress.new!([])
      end
    end

    test "raises error for multiple validation failures" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetReceivedByAddress.new!(address: "invalid", minconf: -1)
      end
    end
  end

  describe "encodable" do
    test "encodes method with required fields only" do
      assert %Request{
               params: [@valid_bech32_address, 1],
               method: "getreceivedbyaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetReceivedByAddress.new!(address: @valid_bech32_address)
               |> Encodable.encode()
    end

    test "encodes method with wallet name" do
      assert %Request{
               params: [@valid_bech32_address, 1],
               method: "getreceivedbyaddress",
               jsonrpc: "1.0",
               path: "/wallet/test_wallet"
             } =
               GetReceivedByAddress.new!(
                 address: @valid_bech32_address,
                 wallet_name: "test_wallet"
               )
               |> Encodable.encode()
    end

    test "encodes method with custom minconf" do
      assert %Request{
               params: [@valid_legacy_address, 6],
               method: "getreceivedbyaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetReceivedByAddress.new!(
                 address: @valid_legacy_address,
                 minconf: 6
               )
               |> Encodable.encode()
    end

    test "encodes method with all parameters" do
      assert %Request{
               params: [@valid_p2sh_address, 3],
               method: "getreceivedbyaddress",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               GetReceivedByAddress.new!(
                 address: @valid_p2sh_address,
                 minconf: 3,
                 wallet_name: "my_wallet"
               )
               |> Encodable.encode()
    end

    test "encodes all valid address types correctly" do
      addresses = [
        @valid_legacy_address,
        @valid_p2sh_address,
        @valid_bech32_address,
        @valid_testnet_address,
        @valid_regtest_address
      ]

      for address <- addresses do
        encoded =
          GetReceivedByAddress.new!(address: address, minconf: 0)
          |> Encodable.encode()

        assert encoded.params == [address, 0]
        assert encoded.method == "getreceivedbyaddress"
      end
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).address
    end

    test "validates address format" do
      # Valid addresses should pass
      for address <- [@valid_legacy_address, @valid_p2sh_address, @valid_bech32_address] do
        changeset =
          GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{address: address})

        assert changeset.valid?
      end

      # Invalid address should fail
      changeset =
        GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{address: "invalid"})

      refute changeset.valid?
      assert changeset.errors[:address] != nil
    end

    test "validates minconf is non-negative" do
      # Valid values
      for minconf <- [0, 1, 6, 100] do
        changeset =
          GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{
            address: @valid_bech32_address,
            minconf: minconf
          })

        assert changeset.valid?
      end

      # Invalid negative value
      changeset =
        GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{
          address: @valid_bech32_address,
          minconf: -1
        })

      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).minconf
    end

    test "validates wallet name length" do
      # Valid length
      valid_name = String.duplicate("a", 64)

      changeset =
        GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{
          address: @valid_bech32_address,
          wallet_name: valid_name
        })

      assert changeset.valid?

      # Too long
      long_name = String.duplicate("a", 65)

      changeset =
        GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{
          address: @valid_bech32_address,
          wallet_name: long_name
        })

      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "validates address length" do
      # Too short
      short_address = "1abc"

      changeset =
        GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{address: short_address})

      refute changeset.valid?
      assert "should be at least 26 character(s)" in errors_on(changeset).address

      # Too long
      long_address = String.duplicate("bc1q", 30)

      changeset =
        GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{address: long_address})

      refute changeset.valid?
      assert "should be at most 90 character(s)" in errors_on(changeset).address

      # Just right
      changeset =
        GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{
          address: @valid_bech32_address
        })

      assert changeset.valid?
    end

    test "accepts all optional fields" do
      changeset =
        GetReceivedByAddress.changeset(%GetReceivedByAddress{}, %{
          address: @valid_bech32_address,
          minconf: 6,
          wallet_name: "test_wallet"
        })

      assert changeset.valid?
      assert Changeset.get_change(changeset, :minconf) == 6
      assert Changeset.get_change(changeset, :wallet_name) == "test_wallet"
    end
  end

  ## GetReceivedByAddress RPC

  describe "(RPC) Wallets.get_received_by_address/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns received amount", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      expected_amount = 0.05000000

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "getreceivedbyaddress",
                   "params" => [^address, 1],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => expected_amount,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_received_by_address(client, address: address)

      assert result == expected_amount
    end

    test "call with wallet name", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      url = Path.join(@url, "/wallet/test-wallet")
      expected_amount = 0.10000000

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "getreceivedbyaddress",
                   "params" => [^address, 1],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_amount,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_received_by_address(client,
                 address: address,
                 wallet_name: "test-wallet"
               )

      assert result == expected_amount
    end

    test "call with custom minimum confirmations", %{client: client} do
      address = "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
      expected_amount = 0.02500000

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getreceivedbyaddress",
                   "params" => [^address, 6],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_amount,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_received_by_address(client,
                 address: address,
                 minconf: 6
               )

      assert result == expected_amount
    end

    test "call with zero confirmations (include unconfirmed)", %{client: client} do
      address = "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
      expected_amount = 0.15000000

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getreceivedbyaddress",
                   "params" => [^address, 0],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_amount,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_received_by_address(client,
                 address: address,
                 minconf: 0
               )

      assert result == expected_amount
    end

    test "call with all parameters", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      url = Path.join(@url, "/wallet/my-wallet")
      expected_amount = 0.75000000

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "getreceivedbyaddress",
                   "params" => [^address, 3],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_amount,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_received_by_address(client,
                 address: address,
                 minconf: 3,
                 wallet_name: "my-wallet"
               )

      assert result == expected_amount
    end

    test "handles address not found (zero amount)", %{client: client} do
      address = "bc1qnew0dd3ess4ge4y5r3zarvary0c5xw7kv8f3t4"

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 0.00000000,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_received_by_address(client, address: address)

      assert result == 0.00000000
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

      assert {:error, %BTx.RPC.MethodError{code: -5, message: message}} =
               Wallets.get_received_by_address(client, address: invalid_address)

      assert message == "Invalid Bitcoin address"
    end

    test "handles wallet not found error", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      url = Path.join(@url, "/wallet/nonexistent")

      mock(fn
        %{method: :post, url: ^url} ->
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

      assert {:error, %BTx.RPC.MethodError{code: -18, message: message}} =
               Wallets.get_received_by_address(client,
                 address: address,
                 wallet_name: "nonexistent"
               )

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "verifies all address types work", %{client: client} do
      address_types = [
        {@valid_legacy_address, "legacy"},
        {@valid_p2sh_address, "p2sh-segwit"},
        {@valid_bech32_address, "bech32"},
        {@valid_testnet_address, "testnet"},
        {@valid_regtest_address, "regtest"}
      ]

      for {address, _type} <- address_types do
        expected_amount = 0.01000000

        mock(fn
          %{method: :post, url: @url, body: body} ->
            # Verify correct parameters are sent
            assert %{
                     "method" => "getreceivedbyaddress",
                     "params" => [^address, 1]
                   } = BTx.json_module().decode!(body)

            %Tesla.Env{
              status: 200,
              body: %{
                "id" => "test-id",
                "result" => expected_amount,
                "error" => nil
              }
            }
        end)

        assert {:ok, result} =
                 Wallets.get_received_by_address(client, address: address)

        assert result == expected_amount
      end
    end

    test "call! raises on error", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_received_by_address!(client, address: address)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client()

      # First ensure we have a wallet loaded, create one if needed
      wallet_name = "get-received-test-#{UUID.generate()}"

      # Create wallet
      %BTx.RPC.Wallets.CreateWalletResult{name: ^wallet_name} =
        Wallets.create_wallet!(
          real_client,
          [wallet_name: wallet_name, passphrase: "test"],
          retries: 10
        )

      # Get a new address
      address = Wallets.get_new_address!(real_client, [wallet_name: wallet_name], retries: 10)

      # Check received amount (should be 0.0 for new address)
      assert {:ok, amount} =
               Wallets.get_received_by_address(
                 real_client,
                 [address: address, wallet_name: wallet_name],
                 retries: 10
               )

      assert is_number(amount)
      assert amount >= 0.0
    end
  end

  describe "(RPC) Wallets.get_received_by_address!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns received amount", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      expected_amount = 0.05000000

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_amount,
              "error" => nil
            }
          }
      end)

      assert result = Wallets.get_received_by_address!(client, address: address)
      assert result == expected_amount
    end

    test "raises on error", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_received_by_address!(client, address: address)
      end
    end
  end
end
