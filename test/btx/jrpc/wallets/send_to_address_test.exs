defmodule BTx.JRPC.Wallets.SendToAddressTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.JRPC.{Encodable, Request, Wallets}
  alias BTx.JRPC.Wallets.{SendToAddress, SendToAddressResult}
  alias Ecto.{Changeset, UUID}

  # Valid Bitcoin addresses for testing
  @valid_legacy_address "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
  @valid_p2sh_address "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
  @valid_bech32_address "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
  @valid_testnet_address "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx"
  @valid_regtest_address "bcrt1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a SendToAddress with required fields" do
      assert {:ok, %SendToAddress{address: @valid_bech32_address, amount: 0.1}} =
               SendToAddress.new(address: @valid_bech32_address, amount: 0.1)
    end

    test "creates a SendToAddress with all parameters" do
      assert {:ok,
              %SendToAddress{
                address: @valid_bech32_address,
                amount: 0.05,
                comment: "Payment for services",
                comment_to: "Alice",
                subtract_fee_from_amount: true,
                replaceable: false,
                conf_target: 6,
                estimate_mode: "economical",
                avoid_reuse: false,
                fee_rate: 25.0,
                verbose: true,
                wallet_name: "my_wallet"
              }} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.05,
                 comment: "Payment for services",
                 comment_to: "Alice",
                 subtract_fee_from_amount: true,
                 replaceable: false,
                 conf_target: 6,
                 estimate_mode: "economical",
                 avoid_reuse: false,
                 fee_rate: 25.0,
                 verbose: true,
                 wallet_name: "my_wallet"
               )
    end

    test "uses default values for optional fields" do
      assert {:ok,
              %SendToAddress{
                subtract_fee_from_amount: false,
                estimate_mode: "unset",
                avoid_reuse: true,
                verbose: false
              }} = SendToAddress.new(address: @valid_bech32_address, amount: 0.1)
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
        assert {:ok, %SendToAddress{address: ^address}} =
                 SendToAddress.new(address: address, amount: 0.1)
      end
    end

    test "accepts valid amounts" do
      valid_amounts = [0.00000001, 0.1, 1.0, 21.0, 21_000_000.0]

      for amount <- valid_amounts do
        assert {:ok, %SendToAddress{amount: ^amount}} =
                 SendToAddress.new(address: @valid_bech32_address, amount: amount)
      end
    end

    test "accepts valid estimate modes" do
      for estimate_mode <- ["unset", "economical", "conservative"] do
        assert {:ok, %SendToAddress{estimate_mode: ^estimate_mode}} =
                 SendToAddress.new(
                   address: @valid_bech32_address,
                   amount: 0.1,
                   estimate_mode: estimate_mode
                 )
      end
    end

    test "returns error for missing address" do
      assert {:error, %Changeset{errors: errors}} = SendToAddress.new(amount: 0.1)

      assert Keyword.fetch!(errors, :address) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for missing amount" do
      assert {:error, %Changeset{errors: errors}} =
               SendToAddress.new(address: @valid_bech32_address)

      assert Keyword.fetch!(errors, :amount) == {"can't be blank", [{:validation, :required}]}
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
                 SendToAddress.new(address: address, amount: 0.1)

        assert changeset.errors[:address] != nil
      end
    end

    test "returns error for invalid amount" do
      invalid_amounts = [0, -0.1, -1.0]

      for amount <- invalid_amounts do
        assert {:error, %Changeset{errors: errors}} =
                 SendToAddress.new(address: @valid_bech32_address, amount: amount)

        assert Keyword.fetch!(errors, :amount) ==
                 {"must be greater than %{number}",
                  [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}
      end
    end

    test "returns error for invalid estimate mode" do
      assert {:error, %Changeset{errors: errors}} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 estimate_mode: "invalid"
               )

      assert Keyword.fetch!(errors, :estimate_mode) ==
               {"is invalid",
                [{:validation, :inclusion}, {:enum, ["unset", "economical", "conservative"]}]}
    end

    test "returns error for invalid conf_target" do
      assert {:error, %Changeset{errors: errors}} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 conf_target: 0
               )

      assert Keyword.fetch!(errors, :conf_target) ==
               {"must be greater than %{number}",
                [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}
    end

    test "returns error for invalid fee_rate" do
      assert {:error, %Changeset{errors: errors}} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 fee_rate: -1.0
               )

      assert Keyword.fetch!(errors, :fee_rate) ==
               {"must be greater than %{number}",
                [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}
    end

    test "returns error for comment too long" do
      long_comment = String.duplicate("a", 1025)

      assert {:error, %Changeset{} = changeset} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 comment: long_comment
               )

      assert "should be at most 1024 character(s)" in errors_on(changeset).comment
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 wallet_name: long_name
               )

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end
  end

  describe "new!/1" do
    test "creates a SendToAddress with required fields" do
      assert %SendToAddress{address: @valid_bech32_address, amount: 0.1} =
               SendToAddress.new!(address: @valid_bech32_address, amount: 0.1)
    end

    test "raises error for invalid data" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        SendToAddress.new!(address: "invalid", amount: 0.1)
      end
    end
  end

  describe "encodable" do
    test "encodes method with required fields only" do
      assert %Request{
               params: [
                 @valid_bech32_address,
                 0.1,
                 nil,
                 nil,
                 false,
                 nil,
                 nil,
                 "unset",
                 true,
                 nil,
                 false
               ],
               method: "sendtoaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               SendToAddress.new!(address: @valid_bech32_address, amount: 0.1)
               |> Encodable.encode()
    end

    test "encodes method with wallet name" do
      assert %Request{
               params: [
                 @valid_bech32_address,
                 0.1,
                 nil,
                 nil,
                 false,
                 nil,
                 nil,
                 "unset",
                 true,
                 nil,
                 false
               ],
               method: "sendtoaddress",
               jsonrpc: "1.0",
               path: "/wallet/test_wallet"
             } =
               SendToAddress.new!(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 wallet_name: "test_wallet"
               )
               |> Encodable.encode()
    end

    test "encodes method with all parameters" do
      assert %Request{
               params: [
                 @valid_bech32_address,
                 0.05,
                 "Payment",
                 "Alice",
                 true,
                 false,
                 6,
                 "economical",
                 false,
                 25.0,
                 true
               ],
               method: "sendtoaddress",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               SendToAddress.new!(
                 address: @valid_bech32_address,
                 amount: 0.05,
                 comment: "Payment",
                 comment_to: "Alice",
                 subtract_fee_from_amount: true,
                 replaceable: false,
                 conf_target: 6,
                 estimate_mode: "economical",
                 avoid_reuse: false,
                 fee_rate: 25.0,
                 verbose: true,
                 wallet_name: "my_wallet"
               )
               |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = SendToAddress.changeset(%SendToAddress{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).address
      assert "can't be blank" in errors_on(changeset).amount
    end

    test "validates address format" do
      # Valid addresses should pass
      for address <- [@valid_legacy_address, @valid_p2sh_address, @valid_bech32_address] do
        changeset =
          SendToAddress.changeset(%SendToAddress{}, %{address: address, amount: 0.1})

        assert changeset.valid?
      end

      # Invalid address should fail
      changeset =
        SendToAddress.changeset(%SendToAddress{}, %{address: "invalid", amount: 0.1})

      refute changeset.valid?
      assert changeset.errors[:address] != nil
    end

    test "validates amount is positive" do
      changeset =
        SendToAddress.changeset(%SendToAddress{}, %{
          address: @valid_bech32_address,
          amount: -0.1
        })

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).amount
    end

    test "validates estimate_mode inclusion" do
      # Valid modes
      for mode <- ["unset", "economical", "conservative"] do
        changeset =
          SendToAddress.changeset(%SendToAddress{}, %{
            address: @valid_bech32_address,
            amount: 0.1,
            estimate_mode: mode
          })

        assert changeset.valid?
      end

      # Invalid mode
      changeset =
        SendToAddress.changeset(%SendToAddress{}, %{
          address: @valid_bech32_address,
          amount: 0.1,
          estimate_mode: "invalid"
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).estimate_mode
    end
  end

  ## SendToAddress RPC

  describe "(RPC) Wallets.send_to_address/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns transaction ID", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      expected_txid = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "sendtoaddress",
                   "params" => [^address, 0.1, nil, nil, false, nil, nil, "unset", true, nil, false],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => expected_txid,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.send_to_address(client,
                 address: address,
                 amount: 0.1
               )

      assert %SendToAddressResult{} = result
      assert result.txid == expected_txid
      assert is_nil(result.fee_reason)
    end

    test "call with wallet name", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      url = Path.join(@url, "/wallet/test-wallet")
      expected_txid = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "sendtoaddress",
                   "params" => [
                     ^address,
                     0.05,
                     nil,
                     nil,
                     false,
                     nil,
                     nil,
                     "unset",
                     true,
                     nil,
                     false
                   ],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_txid,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.send_to_address(client,
                 address: address,
                 amount: 0.05,
                 wallet_name: "test-wallet"
               )

      assert %SendToAddressResult{} = result
      assert result.txid == expected_txid
    end

    test "call with comments and fee deduction", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      expected_txid = "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "sendtoaddress",
                   "params" => [
                     ^address,
                     0.02,
                     "Payment for services",
                     "Alice",
                     true,
                     nil,
                     nil,
                     "unset",
                     true,
                     nil,
                     false
                   ],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_txid,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.send_to_address(client,
                 address: address,
                 amount: 0.02,
                 comment: "Payment for services",
                 comment_to: "Alice",
                 subtract_fee_from_amount: true
               )

      assert %SendToAddressResult{} = result
      assert result.txid == expected_txid
    end

    test "call with verbose output", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      expected_txid = "567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234"

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "sendtoaddress",
                   "params" => [^address, 0.1, nil, nil, false, nil, nil, "unset", true, nil, true],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{
                "txid" => expected_txid,
                "fee reason" => "Fallback fee"
              },
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.send_to_address(client,
                 address: address,
                 amount: 0.1,
                 verbose: true
               )

      assert %SendToAddressResult{} = result
      assert result.txid == expected_txid
      assert result.fee_reason == "Fallback fee"
    end

    test "call with fee rate and confirmation target", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      expected_txid = String.duplicate("1", 64)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "sendtoaddress",
                   "params" => [
                     ^address,
                     0.5,
                     nil,
                     nil,
                     false,
                     true,
                     6,
                     "economical",
                     false,
                     25.0,
                     false
                   ],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_txid,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.send_to_address(client,
                 address: address,
                 amount: 0.5,
                 replaceable: true,
                 conf_target: 6,
                 estimate_mode: "economical",
                 avoid_reuse: false,
                 fee_rate: 25.0
               )

      assert %SendToAddressResult{} = result
      assert result.txid == expected_txid
    end

    test "handles insufficient funds error", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

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
               Wallets.send_to_address(client,
                 address: address,
                 amount: 100.0
               )

      assert message == "Insufficient funds"
    end

    test "handles invalid address error", %{client: client} do
      address = String.duplicate("1", 64)

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
               Wallets.send_to_address(client,
                 address: address,
                 amount: 0.1
               )

      assert message == "Invalid Bitcoin address"
    end

    test "handles wallet encrypted error", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -13,
                "message" =>
                  "Error: Please enter the wallet passphrase with walletpassphrase first."
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{code: -13, message: message}} =
               Wallets.send_to_address(client,
                 address: address,
                 amount: 0.1
               )

      assert message =~ "passphrase"
    end

    test "call! raises on error", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Wallets.send_to_address!(client, address: address, amount: 0.1)
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
          wallet_name: "test-wallet-#{UUID.generate()}",
          avoid_reuse: true
        ).name

      # Now try to get a new address
      address = Wallets.get_new_address!(real_client, wallet_name: wallet_name)

      assert_raise BTx.JRPC.MethodError, ~r/Insufficient funds/, fn ->
        Wallets.send_to_address!(real_client,
          address: address,
          amount: 0.001,
          wallet_name: wallet_name,
          avoid_reuse: true
        )
      end
    end
  end

  describe "(RPC) Wallets.send_to_address!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns transaction result", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      expected_txid = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => expected_txid,
              "error" => nil
            }
          }
      end)

      assert %SendToAddressResult{} =
               result =
               Wallets.send_to_address!(client, address: address, amount: 0.1)

      assert result.txid == expected_txid
    end

    test "raises on error", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Wallets.send_to_address!(client, address: address, amount: 0.1)
      end
    end

    test "raises on invalid result data", %{client: client} do
      address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => "invalid_short_txid",
              "error" => nil
            }
          }
      end)

      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.send_to_address!(client, address: address, amount: 0.1)
      end
    end
  end
end
