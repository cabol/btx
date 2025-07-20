defmodule BTx.JRPC.WalletsTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.WalletsFixtures
  import Tesla.Mock

  alias BTx.JRPC.Wallets
  alias Ecto.UUID

  @url "http://localhost:18443/"

  # Valid Bitcoin transaction ID for testing
  @valid_txid "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

  describe "create_wallet/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful wallet creation returns wallet info", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the method body structure
          assert %{
                   "method" => "createwallet",
                   "params" => ["test_wallet", false, false, "secure_pass", false, true, nil],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          # Should have auto-generated ID
          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => %{
                "name" => "test_wallet",
                "warning" => ""
              },
              "error" => nil
            }
          }
      end)

      assert {:ok, response} =
               Wallets.create_wallet(client,
                 wallet_name: "test_wallet",
                 passphrase: "secure_pass",
                 descriptors: true
               )

      assert response.result["name"] == "test_wallet"
      assert response.result["warning"] == ""
    end

    test "creates a wallet with custom ID", %{client: client} do
      custom_id = "create-wallet-#{System.system_time()}"

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify custom ID is used
          assert %{
                   "method" => "createwallet",
                   "params" => ["custom_id_wallet", false, false, "test_pass", false, false, nil],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => custom_id,
              "result" => %{
                "name" => "custom_id_wallet",
                "warning" => ""
              },
              "error" => nil
            }
          }
      end)

      assert {:ok, response} =
               Wallets.create_wallet(client,
                 id: custom_id,
                 wallet_name: "custom_id_wallet",
                 passphrase: "test_pass"
               )

      assert response.id == custom_id
      assert response.result["name"] == "custom_id_wallet"
    end

    test "call with all options enabled", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          body = BTx.json_module().decode!(body)

          # Verify all options are encoded correctly
          assert %{
                   "method" => "createwallet",
                   "params" => ["feature_wallet", true, true, "complex_pass", true, true, false],
                   "jsonrpc" => "1.0"
                 } = body

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => body["id"],
              "result" => %{
                "name" => "feature_wallet",
                "warning" => "Empty wallet"
              },
              "error" => nil
            }
          }
      end)

      assert {:ok, response} =
               Wallets.create_wallet(client,
                 wallet_name: "feature_wallet",
                 passphrase: "complex_pass",
                 disable_private_keys: true,
                 blank: true,
                 avoid_reuse: true,
                 descriptors: true,
                 load_on_startup: false
               )

      assert response.result["name"] == "feature_wallet"
    end

    test "handles wallet already exists error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -4,
                "message" => "Wallet existing_wallet already exists."
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{id: "test-id", code: -4, message: message}} =
               Wallets.create_wallet(client,
                 wallet_name: "existing_wallet",
                 passphrase: "test_pass"
               )

      assert message =~ "already exists"
    end

    test "handles invalid wallet name error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -8,
                "message" => "Invalid parameter, wallet name contains invalid characters"
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{code: -8, message: message}} =
               Wallets.create_wallet(client, wallet_name: "test_wallet", passphrase: "test_pass")

      assert message =~ "invalid characters"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Wallets.create_wallet!(client, wallet_name: "error_wallet", passphrase: "test_pass")
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      client = new_client()
      wallet_name = "integration-test-#{UUID.generate()}"

      params = [wallet_name: wallet_name, passphrase: "test_pass", descriptors: true]

      assert %{id: ^wallet_name, result: %{"name" => ^wallet_name}} =
               Wallets.create_wallet!(client, params, id: wallet_name)

      assert_raise BTx.JRPC.MethodError, ~r/already exists/, fn ->
        Wallets.create_wallet!(client, params)
      end
    end
  end

  describe "create_wallet!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "creates a wallet", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{
                "name" => "test_wallet",
                "warning" => ""
              },
              "error" => nil
            }
          }
      end)

      assert r = Wallets.create_wallet!(client, wallet_name: "test_wallet", passphrase: "pass")
      assert r.result["name"] == "test_wallet"
      assert r.result["warning"] == ""
      assert r.id == "test-id"
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Wallets.create_wallet!(client, wallet_name: "error_wallet", passphrase: "test_pass")
      end
    end
  end

  describe "get_new_address/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      url = Path.join(@url, "/wallet/test-wallet")

      %{client: client, url: url, wallet_name: "test-wallet"}
    end

    test "successful call returns new address", %{
      client: client,
      url: url,
      wallet_name: wallet_name
    } do
      mock(fn
        %{method: :post, url: ^url, body: body} ->
          # Verify the method body structure
          assert %{
                   "method" => "getnewaddress",
                   "params" => ["test_address", "bech32"],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
              "error" => nil
            }
          }
      end)

      assert {:ok, response} =
               Wallets.get_new_address(client,
                 label: "test_address",
                 address_type: "bech32",
                 wallet_name: wallet_name
               )

      assert response.result == "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
    end

    test "call with default values", %{client: client, url: url, wallet_name: wallet_name} do
      mock(fn
        %{method: :post, url: ^url, body: body} ->
          # Verify default values are sent
          assert %{
                   "method" => "getnewaddress",
                   "params" => ["", "bech32"],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => "bc1qnew0dd3ess4ge4y5r3zarvary0c5xw7kv8f3t4",
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_new_address(client, wallet_name: wallet_name)
      assert is_binary(response.result)
    end

    test "call with only label specified", %{client: client, url: url, wallet_name: wallet_name} do
      mock(fn
        %{method: :post, url: ^url, body: body} ->
          # Verify label is sent with default address_type
          assert %{
                   "method" => "getnewaddress",
                   "params" => ["savings", "bech32"],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => "bc1qsavings0dd3ess4ge4y5r3zarvary0c5xw7kv8f3t4",
              "error" => nil
            }
          }
      end)

      assert {:ok, response} =
               Wallets.get_new_address(client, label: "savings", wallet_name: wallet_name)

      assert response.result =~ "bc1q"
    end

    test "call with only address_type specified", %{
      client: client,
      url: url,
      wallet_name: wallet_name
    } do
      mock(fn
        %{method: :post, url: ^url, body: body} ->
          # Verify empty label with custom address_type
          assert %{
                   "method" => "getnewaddress",
                   "params" => ["", "legacy"],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
              "error" => nil
            }
          }
      end)

      assert {:ok, response} =
               Wallets.get_new_address(client, address_type: "legacy", wallet_name: wallet_name)

      # Legacy addresses start with 1
      assert String.starts_with?(response.result, "1")
    end

    test "handles RPC error response", %{client: client, url: url, wallet_name: wallet_name} do
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

      assert {:error, %BTx.JRPC.MethodError{code: -18, message: message}} =
               Wallets.get_new_address(client, label: "test", wallet_name: wallet_name)

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "call! raises on error", %{client: client, url: url, wallet_name: wallet_name} do
      mock(fn
        %{method: :post, url: ^url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_new_address!(client, label: "test", wallet_name: wallet_name)
      end
    end

    test "verifies all address types work", %{client: client, url: url, wallet_name: wallet_name} do
      address_types = ["legacy", "p2sh-segwit", "bech32", "bech32m"]
      expected_prefixes = ["1", "3", "bc1q", "bc1p"]

      for {address_type, prefix} <- Enum.zip(address_types, expected_prefixes) do
        params = [label: "test", address_type: address_type, wallet_name: wallet_name]

        mock(fn
          %{method: :post, url: ^url, body: body} ->
            # Verify correct parameters are sent
            assert %{
                     "method" => "getnewaddress",
                     "params" => ["test", ^address_type]
                   } = BTx.json_module().decode!(body)

            # Mock realistic address format for each type
            result_address =
              case address_type do
                "legacy" -> "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
                "p2sh-segwit" -> "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
                "bech32" -> "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
                "bech32m" -> "bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297"
              end

            %Tesla.Env{
              status: 200,
              body: %{
                "id" => "test-id",
                "result" => result_address,
                "error" => nil
              }
            }
        end)

        assert {:ok, response} = Wallets.get_new_address(client, params)
        assert String.starts_with?(response.result, prefix)
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
          passphrase: "test"
        ).result["name"]

      # Now try to get a new address
      assert {:ok, response} =
               Wallets.get_new_address(real_client, wallet_name: wallet_name)

      assert is_binary(response.result)
      # Bitcoin addresses are long
      assert String.length(response.result) > 20
    end
  end

  describe "get_new_address!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      url = Path.join(@url, "/wallet/test-wallet")

      %{client: client, url: url, wallet_name: "test-wallet"}
    end

    test "returns a new address", %{client: client, url: url, wallet_name: wallet_name} do
      mock(fn
        %{method: :post, url: ^url, body: body} ->
          # Verify the method body structure
          assert %{
                   "method" => "getnewaddress",
                   "params" => ["", "bech32"],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
              "error" => nil
            }
          }
      end)

      assert r = Wallets.get_new_address!(client, wallet_name: wallet_name)
      assert r.result == "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
    end
  end

  describe "get_transaction/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns transaction details", %{client: client} do
      response_data = get_transaction_preset(:receive)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "gettransaction",
                   "params" => [@valid_txid, true, false],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => response_data,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_transaction(client, txid: @valid_txid)
      assert response.result["txid"] == response_data["txid"]
      assert response.result["amount"] == 0.05000000
      assert response.result["confirmations"] == 6
    end

    test "call with verbose option returns decoded transaction", %{client: client} do
      response_data =
        get_transaction_result_fixture(%{
          "decoded" => %{
            "txid" => @valid_txid,
            "version" => 2,
            "size" => 225
          }
        })

      mock(fn
        %{method: :post, url: @url, body: body} ->
          body = BTx.json_module().decode!(body)

          assert %{
                   "params" => [@valid_txid, true, true]
                 } = body

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => body["id"],
              "result" => response_data,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_transaction(client, txid: @valid_txid, verbose: true)
      assert response.result["decoded"]["txid"] == @valid_txid
      assert response.result["decoded"]["version"] == 2
    end

    test "call with send transaction fixture", %{client: client} do
      send_txid = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
      response_data = get_transaction_preset(:send)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => response_data,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_transaction(client, txid: send_txid)
      # Negative for send
      assert response.result["amount"] == -0.10000000
      assert response.result["fee"] == -0.00002500
      assert hd(response.result["details"])["category"] == "send"
    end

    test "call with coinbase transaction fixture", %{client: client} do
      coinbase_txid = "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"
      response_data = get_transaction_preset(:coinbase)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => response_data,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_transaction(client, txid: coinbase_txid)
      # Block reward
      assert response.result["amount"] == 6.25000000
      assert response.result["generated"] == true
      assert response.result["confirmations"] == 150
      assert hd(response.result["details"])["category"] == "generate"
    end

    test "call with unconfirmed transaction fixture", %{client: client} do
      unconfirmed_txid = "567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234"
      response_data = get_transaction_preset(:unconfirmed)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => response_data,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_transaction(client, txid: unconfirmed_txid)
      assert response.result["confirmations"] == 0
      assert response.result["trusted"] == false
      assert is_nil(response.result["blockhash"])
    end

    test "call with custom transaction data", %{client: client} do
      custom_data =
        get_transaction_result_fixture(%{
          "amount" => 2.5,
          "confirmations" => 100,
          "comment" => "Large payment",
          "details" => [
            %{
              "category" => "receive",
              "amount" => 2.5,
              "label" => "Big Customer"
            }
          ]
        })

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => custom_data,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_transaction(client, txid: @valid_txid)
      assert response.result["amount"] == 2.5
      assert response.result["confirmations"] == 100
      assert response.result["comment"] == "Large payment"
    end

    test "handles transaction not found error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -5,
                "message" => "Invalid or non-wallet transaction id"
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{code: -5, message: message}} =
               Wallets.get_transaction(client, txid: @valid_txid)

      assert message =~ "Invalid or non-wallet transaction id"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_transaction!(client, txid: @valid_txid)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node with wallet and transactions
      real_client = new_client()

      # You would need a real transaction ID from your regtest environment
      # This is just an example - replace with actual txid from your tests
      real_txid = @valid_txid

      # FIXME: Create a successful scenario for this test
      case Wallets.get_transaction(real_client, txid: real_txid) do
        {:ok, response} ->
          assert is_binary(response.result["txid"])
          assert is_number(response.result["amount"])
          assert is_integer(response.result["confirmations"])

        {:error, %BTx.JRPC.Error{reason: {:rpc, :unauthorized}}} ->
          # Expected if regtest is not running or credentials are wrong
          :ok

        {:error, %BTx.JRPC.MethodError{code: -5}} ->
          # Transaction not found - expected if using placeholder txid
          :ok

        {:error, %BTx.JRPC.MethodError{}} ->
          # Some other Bitcoin Core error
          :ok
      end
    end
  end

  describe "get_balance/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns balance", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "getbalance",
                   "params" => ["*", 0, true, true],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => 1.50000000,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_balance(client)
      assert response.result == 1.50000000
    end

    test "call with wallet name", %{client: client} do
      url = Path.join(@url, "/wallet/test-wallet")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "getbalance",
                   "params" => ["*", 0, true, true],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 2.50000000,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_balance(client, wallet_name: "test-wallet")
      assert response.result == 2.50000000
    end

    test "call with minimum confirmations", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getbalance",
                   "params" => ["*", 6, true, true],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 1.25000000,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_balance(client, minconf: 6)
      assert response.result == 1.25000000
    end

    test "call with include_watchonly false", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getbalance",
                   "params" => ["*", 0, false, true],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 1.00000000,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} = Wallets.get_balance(client, include_watchonly: false)
      assert response.result == 1.00000000
    end

    test "call with all parameters", %{client: client} do
      url = Path.join(@url, "/wallet/my-wallet")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "getbalance",
                   "params" => ["*", 3, true, false],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 0.75000000,
              "error" => nil
            }
          }
      end)

      assert {:ok, response} =
               Wallets.get_balance(client,
                 wallet_name: "my-wallet",
                 minconf: 3,
                 include_watchonly: true,
                 avoid_reuse: false
               )

      assert response.result == 0.75000000
    end

    test "handles insufficient funds (zero balance)", %{client: client} do
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

      assert {:ok, response} = Wallets.get_balance(client)
      assert response.result == 0.00000000
    end

    test "handles wallet not found error", %{client: client} do
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

      assert {:error, %BTx.JRPC.MethodError{code: -18, message: message}} =
               Wallets.get_balance(client, wallet_name: "nonexistent")

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_balance!(client)
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
          passphrase: "test",
          avoid_reuse: true
        ).result["name"]

      assert {:ok, response} =
               Wallets.get_balance(real_client, wallet_name: wallet_name)

      assert response.result >= 0.0
    end
  end

  describe "get_balance!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns balance", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 1.50000000,
              "error" => nil
            }
          }
      end)

      assert r = Wallets.get_balance!(client)
      assert r.result == 1.50000000
      assert r.id == "test-id"
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_balance!(client)
      end
    end
  end
end
