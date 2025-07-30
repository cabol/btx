defmodule BTx.RPC.Wallets.ListTransactionsTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.{ListTransactions, ListTransactionsItem}
  alias Ecto.Changeset

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a new ListTransactions with default values" do
      assert {:ok, %ListTransactions{count: 10, skip: 0}} = ListTransactions.new()
    end

    test "creates a new ListTransactions with all parameters" do
      assert {:ok,
              %ListTransactions{
                label: "customer_payments",
                count: 20,
                skip: 100,
                include_watchonly: true,
                wallet_name: "my_wallet"
              }} =
               ListTransactions.new(
                 label: "customer_payments",
                 count: 20,
                 skip: 100,
                 include_watchonly: true,
                 wallet_name: "my_wallet"
               )
    end

    test "accepts valid parameters" do
      valid_params = [
        %{label: "*"},
        %{label: "test_label"},
        %{count: 50},
        %{skip: 25},
        %{include_watchonly: false},
        %{wallet_name: "test_wallet"}
      ]

      for params <- valid_params do
        assert {:ok, %ListTransactions{}} = ListTransactions.new(params)
      end
    end

    test "returns error for invalid count" do
      assert {:error, %Changeset{} = changeset} = ListTransactions.new(count: 0)
      assert "must be greater than 0" in errors_on(changeset).count

      assert {:error, %Changeset{} = changeset} = ListTransactions.new(count: -1)
      assert "must be greater than 0" in errors_on(changeset).count
    end

    test "returns error for invalid skip" do
      assert {:error, %Changeset{} = changeset} = ListTransactions.new(skip: -1)
      assert "must be greater than or equal to 0" in errors_on(changeset).skip
    end

    test "returns error for label too long" do
      long_label = String.duplicate("a", 256)

      assert {:error, %Changeset{} = changeset} = ListTransactions.new(label: long_label)
      assert "should be at most 255 character(s)" in errors_on(changeset).label
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} = ListTransactions.new(wallet_name: long_name)
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end
  end

  describe "new!/1" do
    test "creates a new ListTransactions with default values" do
      assert %ListTransactions{count: 10, skip: 0} = ListTransactions.new!()
    end

    test "raises error for invalid parameters" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        ListTransactions.new!(count: -1)
      end
    end
  end

  describe "encodable" do
    test "encodes method with default values" do
      assert %Request{
               params: [nil, 10, 0],
               method: "listtransactions",
               jsonrpc: "1.0",
               path: "/"
             } = ListTransactions.new!() |> Encodable.encode()
    end

    test "encodes method with wallet name" do
      assert %Request{
               params: [nil, 10, 0],
               method: "listtransactions",
               jsonrpc: "1.0",
               path: "/wallet/test_wallet"
             } = ListTransactions.new!(wallet_name: "test_wallet") |> Encodable.encode()
    end

    test "encodes method with all parameters" do
      assert %Request{
               params: ["customer_payments", 20, 100, true],
               method: "listtransactions",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               ListTransactions.new!(
                 label: "customer_payments",
                 count: 20,
                 skip: 100,
                 include_watchonly: true,
                 wallet_name: "my_wallet"
               )
               |> Encodable.encode()
    end
  end

  ## ListTransactionsItem tests

  describe "ListTransactionsItem.new/1" do
    test "creates item with required fields" do
      attrs = %{
        "category" => "receive",
        "amount" => 0.05,
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "time" => 1_640_995_200,
        "timereceived" => 1_640_995_205
      }

      assert {:ok, %ListTransactionsItem{} = item} = ListTransactionsItem.new(attrs)
      assert item.category == "receive"
      assert item.amount == 0.05
      assert item.txid == "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    end

    test "creates item with all fields" do
      attrs = %{
        "involvesWatchonly" => false,
        "address" => "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
        "category" => "send",
        "amount" => -0.1,
        "label" => "test_payment",
        "vout" => 0,
        "fee" => -0.0001,
        "confirmations" => 6,
        "generated" => false,
        "trusted" => true,
        "blockhash" => "0000000000000000000a1b2c3d4e5f6789abcdef0123456789abcdef01234567",
        "blockheight" => 750_123,
        "blockindex" => 2,
        "blocktime" => 1_640_995_200,
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "walletconflicts" => [],
        "time" => 1_640_995_200,
        "timereceived" => 1_640_995_205,
        "comment" => "Test payment",
        "bip125-replaceable" => "no",
        "abandoned" => false
      }

      assert {:ok, %ListTransactionsItem{} = item} = ListTransactionsItem.new(attrs)
      assert item.bip125_replaceable == "no"
      assert item.blockhash == "0000000000000000000a1b2c3d4e5f6789abcdef0123456789abcdef01234567"
    end

    test "validates required fields" do
      incomplete_attrs = %{
        "category" => "receive"
        # Missing other required fields
      }

      assert {:error, %Changeset{errors: errors}} = ListTransactionsItem.new(incomplete_attrs)
      assert Keyword.has_key?(errors, :amount)
      assert Keyword.has_key?(errors, :txid)
    end

    test "validates category field" do
      attrs = %{
        "category" => "invalid_category",
        "amount" => 0.05,
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "time" => 1_640_995_200,
        "timereceived" => 1_640_995_205
      }

      assert {:error, %Changeset{} = changeset} = ListTransactionsItem.new(attrs)
      assert "is invalid" in errors_on(changeset).category
    end

    test "validates txid format" do
      attrs = %{
        "category" => "receive",
        "amount" => 0.05,
        "txid" => "invalid_txid",
        "time" => 1_640_995_200,
        "timereceived" => 1_640_995_205
      }

      assert {:error, %Changeset{} = changeset} = ListTransactionsItem.new(attrs)
      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "validates blockhash format" do
      attrs = %{
        "category" => "receive",
        "amount" => 0.05,
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "time" => 1_640_995_200,
        "timereceived" => 1_640_995_205,
        "blockhash" => "invalid_hash"
      }

      assert {:error, %Changeset{} = changeset} = ListTransactionsItem.new(attrs)
      assert "has invalid format" in errors_on(changeset).blockhash
      assert "should be 64 character(s)" in errors_on(changeset).blockhash
    end

    test "validates empty blockhash" do
      attrs = %{
        "category" => "receive",
        "amount" => 0.05,
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "time" => 1_640_995_200,
        "timereceived" => 1_640_995_205,
        "blockhash" => nil
      }

      assert {:ok, %ListTransactionsItem{} = item} = ListTransactionsItem.new(attrs)
      assert item.blockhash == nil
    end

    test "validates bip125_replaceable field" do
      attrs = %{
        "category" => "receive",
        "amount" => 0.05,
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "time" => 1_640_995_200,
        "timereceived" => 1_640_995_205,
        "bip125-replaceable" => "invalid_value"
      }

      assert {:error, %Changeset{} = changeset} = ListTransactionsItem.new(attrs)
      assert "is invalid" in errors_on(changeset).bip125_replaceable
    end
  end

  ## ListTransactions RPC

  describe "(RPC) Wallets.list_transactions/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns list of transactions", %{client: client} do
      url = Path.join(@url, "/wallet/test_wallet")

      transactions = [
        %{
          "category" => "receive",
          "amount" => 0.05,
          "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
          "time" => 1_640_995_200,
          "timereceived" => 1_640_995_205,
          "confirmations" => 6
        },
        %{
          "category" => "send",
          "amount" => -0.1,
          "txid" => "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
          "time" => 1_640_995_300,
          "timereceived" => 1_640_995_302,
          "confirmations" => 3,
          "fee" => -0.0001
        }
      ]

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "listtransactions",
                   "params" => [nil, 10, 0],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => transactions,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.list_transactions(client, wallet_name: "test_wallet")
      assert is_list(result)
      assert length(result) == 2
      assert Enum.all?(result, &match?(%ListTransactionsItem{}, &1))
    end

    test "call with label filter", %{client: client} do
      url = Path.join(@url, "/wallet/test_wallet")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "listtransactions",
                   "params" => ["customer_payments", 10, 0],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

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
               Wallets.list_transactions(client,
                 wallet_name: "test_wallet",
                 label: "customer_payments"
               )

      assert result == []
    end

    test "call with pagination", %{client: client} do
      url = Path.join(@url, "/wallet/test_wallet")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "listtransactions",
                   "params" => ["*", 20, 100, true],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

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
               Wallets.list_transactions(client,
                 wallet_name: "test_wallet",
                 label: "*",
                 count: 20,
                 skip: 100,
                 include_watchonly: true
               )

      assert result == []
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

      assert {:error, %BTx.RPC.MethodError{code: -18, message: message}} =
               Wallets.list_transactions(client, wallet_name: "nonexistent")

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "handles invalid transaction data", %{client: client} do
      url = Path.join(@url, "/wallet/test_wallet")

      invalid_transactions = [
        %{
          "category" => "receive",
          "amount" => 0.05,
          # Invalid txid length
          "txid" => "invalid_short_txid",
          "time" => 1_640_995_200,
          "timereceived" => 1_640_995_205
        }
      ]

      mock(fn
        %{method: :post, url: ^url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => invalid_transactions,
              "error" => nil
            }
          }
      end)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Wallets.list_transactions(client, wallet_name: "test_wallet")

      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "handles invalid response data", %{client: client} do
      url = Path.join(@url, "/wallet/test_wallet")

      mock(fn
        %{method: :post, url: ^url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{},
              "error" => nil
            }
          }
      end)

      assert_raise RuntimeError, ~r/Expected a list of transactions/, fn ->
        Wallets.list_transactions(client, wallet_name: "test_wallet")
      end
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url <> "wallet/test_wallet"} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.list_transactions!(client, wallet_name: "test_wallet")
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client()

      # Wallet for this test
      wallet_name = "btx-shared-test-wallet"

      # Step 1: Create a destination address (different wallet or address)
      address =
        Wallets.get_new_address!(real_client, [wallet_name: wallet_name, label: "destination"],
          retries: 10
        )

      # Step 2: Send a transaction
      {:ok, send_result} =
        Wallets.send_to_address(
          real_client,
          [
            address: address,
            amount: 0.001,
            wallet_name: wallet_name,
            comment: "Integration test transaction"
          ],
          retries: 10
        )

      # Step 3: Try to list transactions
      assert {:ok, transactions} =
               Wallets.list_transactions(
                 real_client,
                 [wallet_name: wallet_name],
                 retries: 10
               )

      assert send_result.txid in Enum.map(transactions, & &1.txid)
    end
  end

  describe "(RPC) Wallets.list_transactions!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns list of transactions directly", %{client: client} do
      url = Path.join(@url, "/wallet/test_wallet")

      transactions = [
        %{
          "category" => "receive",
          "amount" => 0.05,
          "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
          "time" => 1_640_995_200,
          "timereceived" => 1_640_995_205
        }
      ]

      mock(fn
        %{method: :post, url: ^url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => transactions,
              "error" => nil
            }
          }
      end)

      assert [%ListTransactionsItem{} = item] =
               Wallets.list_transactions!(client, wallet_name: "test_wallet")

      assert item.category == "receive"
      assert item.amount == 0.05
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.list_transactions!(client, count: -1)
      end
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url <> "wallet/test_wallet"} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.list_transactions!(client, wallet_name: "test_wallet")
      end
    end

    test "raises on invalid transaction data", %{client: client} do
      url = Path.join(@url, "/wallet/test_wallet")

      invalid_transactions = [
        %{
          "category" => "invalid_category",
          "amount" => 0.05,
          "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
          "time" => 1_640_995_200,
          "timereceived" => 1_640_995_205
        }
      ]

      mock(fn
        %{method: :post, url: ^url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => invalid_transactions,
              "error" => nil
            }
          }
      end)

      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.list_transactions!(client, wallet_name: "test_wallet")
      end
    end

    test "raises on invalid response data", %{client: client} do
      url = Path.join(@url, "/wallet/test_wallet")

      mock(fn
        %{method: :post, url: ^url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{},
              "error" => nil
            }
          }
      end)

      assert_raise RuntimeError, ~r/Expected a list of transactions/, fn ->
        Wallets.list_transactions!(client, wallet_name: "test_wallet")
      end
    end
  end
end
