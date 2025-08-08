defmodule BTx.RPC.Wallets.GetTransactionTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.WalletsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.{GetTransaction, GetTransactionResult}
  alias Ecto.Changeset

  # Valid Bitcoin transaction ID for testing
  @valid_txid "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  @invalid_txid_short "1234567890abcdef"
  @invalid_txid_long "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123"

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a new GetTransaction with valid txid" do
      assert {:ok, %GetTransaction{txid: @valid_txid, include_watchonly: true, verbose: false}} =
               GetTransaction.new(txid: @valid_txid)
    end

    test "creates a new GetTransaction with all options" do
      assert {:ok,
              %GetTransaction{
                txid: @valid_txid,
                include_watchonly: false,
                verbose: true,
                wallet_name: "test_wallet"
              }} =
               GetTransaction.new(
                 txid: @valid_txid,
                 include_watchonly: false,
                 verbose: true,
                 wallet_name: "test_wallet"
               )
    end

    test "uses default values for optional fields" do
      assert {:ok,
              %GetTransaction{
                include_watchonly: true,
                verbose: false,
                wallet_name: nil
              }} = GetTransaction.new(txid: @valid_txid)
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
        assert {:ok, %GetTransaction{wallet_name: ^name}} =
                 GetTransaction.new(txid: @valid_txid, wallet_name: name)
      end
    end

    test "returns an error if txid is missing" do
      assert {:error, %Changeset{errors: errors}} =
               GetTransaction.new(%{})

      assert Keyword.fetch!(errors, :txid) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns an error if txid is too short" do
      assert {:error, %Changeset{} = changeset} =
               GetTransaction.new(txid: @invalid_txid_short)

      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "returns an error if txid is too long" do
      assert {:error, %Changeset{} = changeset} =
               GetTransaction.new(txid: @invalid_txid_long)

      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "returns an error if txid is nil" do
      assert {:error, %Changeset{errors: errors}} =
               GetTransaction.new(txid: nil)

      assert Keyword.fetch!(errors, :txid) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns an error if txid is empty string" do
      assert {:error, %Changeset{errors: errors}} =
               GetTransaction.new(txid: "")

      assert Keyword.fetch!(errors, :txid) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               GetTransaction.new(txid: @valid_txid, wallet_name: long_name)

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end
  end

  describe "new!/1" do
    test "creates a new GetTransaction with valid txid" do
      assert %GetTransaction{txid: @valid_txid, include_watchonly: true, verbose: false} =
               GetTransaction.new!(txid: @valid_txid)
    end

    test "creates a new GetTransaction with all options" do
      assert %GetTransaction{
               txid: @valid_txid,
               include_watchonly: false,
               verbose: true,
               wallet_name: "test_wallet"
             } =
               GetTransaction.new!(
                 txid: @valid_txid,
                 include_watchonly: false,
                 verbose: true,
                 wallet_name: "test_wallet"
               )
    end

    test "raises an error if txid is invalid" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetTransaction.new!(txid: @invalid_txid_short)
      end
    end

    test "raises an error if txid is missing" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetTransaction.new!(%{})
      end
    end

    test "raises an error if wallet name is invalid" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetTransaction.new!(txid: @valid_txid, wallet_name: String.duplicate("a", 65))
      end
    end
  end

  describe "encodable" do
    test "encodes the request with default options" do
      assert %Request{
               params: [@valid_txid, true, false],
               method: "gettransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetTransaction.new!(txid: @valid_txid)
               |> Encodable.encode()
    end

    test "encodes the request with wallet name" do
      assert %Request{
               params: [@valid_txid, true, false],
               method: "gettransaction",
               jsonrpc: "1.0",
               path: "/wallet/test_wallet"
             } =
               GetTransaction.new!(txid: @valid_txid, wallet_name: "test_wallet")
               |> Encodable.encode()
    end

    test "encodes the request with custom options" do
      assert %Request{
               params: [@valid_txid, false, true],
               method: "gettransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetTransaction.new!(
                 txid: @valid_txid,
                 include_watchonly: false,
                 verbose: true
               )
               |> Encodable.encode()
    end

    test "encodes the request with all options" do
      assert %Request{
               params: [@valid_txid, false, true],
               method: "gettransaction",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               GetTransaction.new!(
                 txid: @valid_txid,
                 include_watchonly: false,
                 verbose: true,
                 wallet_name: "my_wallet"
               )
               |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = GetTransaction.changeset(%GetTransaction{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).txid
    end

    test "validates txid length" do
      # Too short
      changeset = GetTransaction.changeset(%GetTransaction{}, %{txid: @invalid_txid_short})
      refute changeset.valid?
      assert "should be 64 character(s)" in errors_on(changeset).txid

      # Too long
      changeset = GetTransaction.changeset(%GetTransaction{}, %{txid: @invalid_txid_long})
      refute changeset.valid?
      assert "should be 64 character(s)" in errors_on(changeset).txid

      # Just right
      changeset = GetTransaction.changeset(%GetTransaction{}, %{txid: @valid_txid})
      assert changeset.valid?
    end

    test "validates wallet name length" do
      # Too long
      long_name = String.duplicate("a", 65)

      changeset =
        GetTransaction.changeset(%GetTransaction{}, %{txid: @valid_txid, wallet_name: long_name})

      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "accepts valid boolean values for optional fields" do
      changeset =
        GetTransaction.changeset(%GetTransaction{}, %{
          txid: @valid_txid,
          include_watchonly: false,
          verbose: true
        })

      assert changeset.valid?
      assert Changeset.get_change(changeset, :include_watchonly) == false
      assert Changeset.get_change(changeset, :verbose) == true
    end

    test "accepts nil wallet_name" do
      changeset =
        GetTransaction.changeset(%GetTransaction{}, %{
          txid: @valid_txid,
          wallet_name: nil
        })

      assert changeset.valid?
    end
  end

  ## GetTransaction RPC

  describe "(RPC) Wallets.get_transaction/3" do
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

      assert {:ok, %GetTransactionResult{} = result} =
               Wallets.get_transaction(client, txid: @valid_txid)

      assert result.txid == response_data["txid"]
      assert result.amount == 0.05000000
      assert result.confirmations == 6
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

      assert {:ok, %GetTransactionResult{} = result} =
               Wallets.get_transaction(client, txid: @valid_txid, verbose: true)

      assert result.decoded["txid"] == @valid_txid
      assert result.decoded["version"] == 2
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

      assert {:ok, %GetTransactionResult{} = result} =
               Wallets.get_transaction(client, txid: send_txid)

      # Negative for send
      assert result.amount == -0.10000000
      assert result.fee == -0.00002500
      assert hd(result.details).category == "send"
      assert hd(result.details).involves_watchonly == false
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

      assert {:ok, %GetTransactionResult{} = result} =
               Wallets.get_transaction(client, txid: coinbase_txid)

      # Block reward
      assert result.amount == 6.25000000
      assert result.generated == true
      assert result.confirmations == 150
      assert hd(result.details).category == "generate"
      assert hd(result.details).involves_watchonly == false
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

      assert {:ok, %GetTransactionResult{} = result} =
               Wallets.get_transaction(client, txid: unconfirmed_txid)

      assert result.confirmations == 0
      assert result.trusted == false
      assert is_nil(result.blockhash)
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

      assert {:ok, %GetTransactionResult{} = result} =
               Wallets.get_transaction(client, txid: @valid_txid)

      assert result.amount == 2.5
      assert result.confirmations == 100
      assert result.comment == "Large payment"
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

      assert {:error,
              %BTx.RPC.MethodError{code: -5, message: message, reason: :invalid_address_or_key}} =
               Wallets.get_transaction(client, txid: @valid_txid)

      assert message =~ "Invalid or non-wallet transaction id"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_transaction!(client, txid: @valid_txid)
      end
    end

    test "handles invalid transaction result data", %{client: client} do
      # Test when Bitcoin Core returns malformed data
      invalid_data = %{
        # Invalid length - should fail validation
        "txid" => "invalid_short_txid",
        # Valid amount
        "amount" => 1.0,
        # Valid but negative
        "confirmations" => -999,
        "time" => 1_234_567_890,
        "timereceived" => 1_234_567_890,
        "hex" => "deadbeef"
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => invalid_data,
              "error" => nil
            }
          }
      end)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Wallets.get_transaction(client, txid: @valid_txid)

      # Should have txid validation error
      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "handles bip125-replaceable field mapping", %{client: client} do
      response_data =
        get_transaction_result_fixture(%{
          # Hyphenated field should map to bip125_replaceable
          "bip125-replaceable" => "yes"
        })

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

      assert {:ok, %GetTransactionResult{} = result} =
               Wallets.get_transaction(client, txid: @valid_txid)

      assert result.bip125_replaceable == "yes"
    end

    test "handles transaction with wallet conflicts", %{client: client} do
      conflicting_txid = "1111111111111111111111111111111111111111111111111111111111111111"

      response_data =
        get_transaction_result_fixture(%{
          "walletconflicts" => [conflicting_txid]
        })

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

      assert {:ok, %GetTransactionResult{} = result} =
               Wallets.get_transaction(client, txid: @valid_txid)

      assert result.walletconflicts == [conflicting_txid]
    end

    test "handles minimal transaction data", %{client: client} do
      # Test with only required fields
      minimal_data = %{
        "amount" => 1.0,
        "confirmations" => 1,
        "txid" => @valid_txid,
        "time" => 1_234_567_890,
        "timereceived" => 1_234_567_890,
        "hex" => "deadbeef"
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => minimal_data,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetTransactionResult{} = result} =
               Wallets.get_transaction(client, txid: @valid_txid)

      assert result.amount == 1.0
      assert result.confirmations == 1
      assert result.txid == @valid_txid
      # Optional fields should be nil
      assert is_nil(result.fee)
      assert is_nil(result.comment)
      assert is_nil(result.blockhash)
      # Array fields should have defaults
      assert result.walletconflicts == []
      assert result.details == []
    end

    test "handles invalid bip125_replaceable value", %{client: client} do
      response_data =
        get_transaction_result_fixture(%{
          # Should fail validation
          "bip125-replaceable" => "invalid_value"
        })

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

      assert {:error, %Ecto.Changeset{} = changeset} =
               Wallets.get_transaction(client, txid: @valid_txid)

      assert "is invalid" in errors_on(changeset).bip125_replaceable
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node with wallet and transactions
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

      # Step 3: Verify the transaction
      assert {:ok, %GetTransactionResult{} = result} =
               Wallets.get_transaction(
                 real_client,
                 [txid: send_result.txid, wallet_name: wallet_name],
                 retries: 10
               )

      assert is_binary(result.txid)
      assert is_number(result.amount)
      assert is_integer(result.confirmations)
    end
  end

  describe "(RPC) Wallets.get_transaction!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns transaction result", %{client: client} do
      response_data = get_transaction_preset(:receive)

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

      assert %GetTransactionResult{} = result = Wallets.get_transaction!(client, txid: @valid_txid)
      assert result.txid == response_data["txid"]
      assert result.amount == 0.05000000
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_transaction!(client, txid: @valid_txid)
      end
    end

    test "raises on invalid result data", %{client: client} do
      invalid_data = %{
        # Too short - should fail validation
        "txid" => "invalid",
        "amount" => 1.0,
        "confirmations" => 1,
        "time" => 1_234_567_890,
        "timereceived" => 1_234_567_890,
        "hex" => "deadbeef"
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => invalid_data,
              "error" => nil
            }
          }
      end)

      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.get_transaction!(client, txid: @valid_txid)
      end
    end
  end
end
