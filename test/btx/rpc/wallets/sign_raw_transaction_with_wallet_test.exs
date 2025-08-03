defmodule BTx.RPC.Wallets.SignRawTransactionWithWalletTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.WalletsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.{SignRawTransactionWithWallet, SignRawTransactionWithWalletResult}
  alias Ecto.{Changeset, UUID}

  @valid_txid "abc123def456789abc123def456789abc123def456789abc123def456789ab00"
  @valid_hex "0200000001abc123def456789abc123def456789abc123def456789abc123def456789ab00000000ffffffff0100e1f50500000000160014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2600000000"
  @valid_wallet_name "test_wallet"

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a new SignRawTransactionWithWallet with required fields" do
      assert {:ok, %SignRawTransactionWithWallet{} = request} =
               SignRawTransactionWithWallet.new(hexstring: @valid_hex)

      assert request.hexstring == @valid_hex
      assert request.sighashtype == "ALL"
      assert request.prevtxs == []
      assert is_nil(request.wallet_name)
    end

    test "creates a new SignRawTransactionWithWallet with all parameters" do
      assert {:ok, %SignRawTransactionWithWallet{} = request} =
               SignRawTransactionWithWallet.new(
                 hexstring: @valid_hex,
                 prevtxs: [
                   %{
                     txid: @valid_txid,
                     vout: 0,
                     script_pub_key: "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac",
                     amount: 0.01
                   }
                 ],
                 sighashtype: "SINGLE",
                 wallet_name: @valid_wallet_name
               )

      assert request.hexstring == @valid_hex
      assert request.sighashtype == "SINGLE"
      assert length(request.prevtxs) == 1
      assert request.wallet_name == @valid_wallet_name
    end

    test "uses default values for optional fields" do
      assert {:ok, %SignRawTransactionWithWallet{} = request} =
               SignRawTransactionWithWallet.new(hexstring: @valid_hex)

      assert request.sighashtype == "ALL"
      assert request.prevtxs == []
      assert is_nil(request.wallet_name)
    end

    test "accepts valid signature hash types" do
      valid_types = ~w(ALL NONE SINGLE ALL|ANYONECANPAY NONE|ANYONECANPAY SINGLE|ANYONECANPAY)

      for sighash_type <- valid_types do
        assert {:ok, %SignRawTransactionWithWallet{} = request} =
                 SignRawTransactionWithWallet.new(
                   hexstring: @valid_hex,
                   sighashtype: sighash_type
                 )

        assert request.sighashtype == sighash_type
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
        assert {:ok, %SignRawTransactionWithWallet{wallet_name: ^name}} =
                 SignRawTransactionWithWallet.new(
                   hexstring: @valid_hex,
                   wallet_name: name
                 )
      end
    end

    test "returns error for missing hexstring" do
      assert {:error, %Changeset{errors: errors}} = SignRawTransactionWithWallet.new(%{})

      assert Keyword.fetch!(errors, :hexstring) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for empty hexstring" do
      assert {:error, %Changeset{errors: errors}} =
               SignRawTransactionWithWallet.new(hexstring: "")

      assert Keyword.fetch!(errors, :hexstring) == {"can't be blank", [validation: :required]}
    end

    test "returns error for invalid hexstring" do
      assert {:error, %Changeset{} = changeset} =
               SignRawTransactionWithWallet.new(hexstring: "invalid_hex!")

      assert "must be a valid hex string" in errors_on(changeset).hexstring
    end

    test "returns error for invalid sighashtype" do
      assert {:error, %Changeset{} = changeset} =
               SignRawTransactionWithWallet.new(
                 hexstring: @valid_hex,
                 sighashtype: "INVALID"
               )

      assert "is invalid" in errors_on(changeset).sighashtype
    end

    test "returns error for invalid wallet name" do
      assert {:error, %Changeset{} = changeset} =
               SignRawTransactionWithWallet.new(
                 hexstring: @valid_hex,
                 wallet_name: "invalid-wallet-name!"
               )

      assert changeset.errors[:wallet_name] != nil
    end

    test "accepts keyword list params" do
      assert {:ok, %SignRawTransactionWithWallet{} = request} =
               SignRawTransactionWithWallet.new(
                 hexstring: @valid_hex,
                 sighashtype: "NONE",
                 wallet_name: @valid_wallet_name
               )

      assert request.hexstring == @valid_hex
      assert request.sighashtype == "NONE"
      assert request.wallet_name == @valid_wallet_name
    end
  end

  describe "new!/1" do
    test "creates a new SignRawTransactionWithWallet with valid data" do
      assert %SignRawTransactionWithWallet{} =
               SignRawTransactionWithWallet.new!(hexstring: @valid_hex)
    end

    test "raises error for invalid data" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        SignRawTransactionWithWallet.new!(hexstring: "invalid_hex!")
      end
    end
  end

  describe "encodable" do
    test "encodes minimal request correctly" do
      request = SignRawTransactionWithWallet.new!(hexstring: @valid_hex)

      assert %Request{
               method: "signrawtransactionwithwallet",
               path: "/",
               params: [@valid_hex, [], "ALL"]
             } = Encodable.encode(request)
    end

    test "encodes request with wallet name" do
      request =
        SignRawTransactionWithWallet.new!(
          hexstring: @valid_hex,
          wallet_name: @valid_wallet_name
        )

      assert %Request{
               method: "signrawtransactionwithwallet",
               path: "/wallet/#{@valid_wallet_name}",
               params: [@valid_hex, [], "ALL"]
             } = Encodable.encode(request)
    end

    test "encodes request with all parameters" do
      request =
        SignRawTransactionWithWallet.new!(
          hexstring: @valid_hex,
          prevtxs: [
            %{
              txid: @valid_txid,
              vout: 0,
              script_pub_key: "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac",
              redeem_script:
                "5221023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456",
              amount: 0.01
            }
          ],
          sighashtype: "SINGLE",
          wallet_name: @valid_wallet_name
        )

      encoded = Encodable.encode(request)

      assert encoded.method == "signrawtransactionwithwallet"
      assert encoded.path == "/wallet/#{@valid_wallet_name}"
      assert [_hex, [prevtx_map], "SINGLE"] = encoded.params

      # Verify prevtx encoding with correct field mappings
      assert prevtx_map["txid"] == @valid_txid
      assert prevtx_map["vout"] == 0
      assert prevtx_map["scriptPubKey"] == "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac"

      assert prevtx_map["redeemScript"] ==
               "5221023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456"

      assert prevtx_map["amount"] == 0.01
    end

    test "filters out nil values in prevtxs" do
      request =
        SignRawTransactionWithWallet.new!(
          hexstring: @valid_hex,
          prevtxs: [
            %{
              txid: @valid_txid,
              vout: 0,
              script_pub_key: "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac"
              # redeem_script, witness_script, amount are nil
            }
          ]
        )

      encoded = Encodable.encode(request)
      [_hex, [prevtx_map], _] = encoded.params

      # Should only include non-nil values
      assert Map.keys(prevtx_map) == ["scriptPubKey", "txid", "vout"]
      refute Map.has_key?(prevtx_map, "redeemScript")
      refute Map.has_key?(prevtx_map, "witnessScript")
      refute Map.has_key?(prevtx_map, "amount")
    end

    test "trims trailing nil params" do
      request = SignRawTransactionWithWallet.new!(hexstring: @valid_hex, sighashtype: "ALL")

      encoded = Encodable.encode(request)

      # Should not include trailing nil prevtxs and default sighashtype
      assert encoded.params == [@valid_hex, [], "ALL"]
    end
  end

  describe "changeset/2" do
    test "validates prevtxs embedded schema" do
      # Valid prevtx
      attrs = %{
        hexstring: @valid_hex,
        prevtxs: [
          %{
            txid: @valid_txid,
            vout: 0,
            script_pub_key: "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac"
          }
        ]
      }

      changeset = SignRawTransactionWithWallet.changeset(%SignRawTransactionWithWallet{}, attrs)
      assert changeset.valid?

      # Invalid prevtx - missing required fields
      attrs = %{
        hexstring: @valid_hex,
        prevtxs: [%{txid: "invalid"}]
      }

      changeset = SignRawTransactionWithWallet.changeset(%SignRawTransactionWithWallet{}, attrs)
      refute changeset.valid?
    end

    test "accepts empty parameters" do
      changeset = SignRawTransactionWithWallet.changeset(%SignRawTransactionWithWallet{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).hexstring
    end
  end

  ## SignRawTransactionWithWalletResult schema tests

  describe "SignRawTransactionWithWalletResult.new/1" do
    test "creates result with valid data" do
      attrs = sign_raw_transaction_with_wallet_result_fixture()

      assert {:ok, %SignRawTransactionWithWalletResult{} = result} =
               SignRawTransactionWithWalletResult.new(attrs)

      assert result.hex == attrs["hex"]
      assert result.complete == attrs["complete"]
      assert result.errors == []
    end

    test "creates result with errors" do
      attrs =
        sign_raw_transaction_with_wallet_result_fixture(%{
          "complete" => false,
          "errors" => [
            %{
              "txid" => "abc123def456789abc123def456789abc123def456789abc123def456789ab00",
              "vout" => 0,
              "scriptSig" =>
                "47304402203c2a7d8c8a4b5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1021034567890abcdef0123456789abcdef0123456789abcdef0123456789abcdef01",
              "sequence" => 4_294_967_295,
              "error" => "Input not found or already spent"
            }
          ]
        })

      assert {:ok, %SignRawTransactionWithWalletResult{} = result} =
               SignRawTransactionWithWalletResult.new(attrs)

      assert result.complete == false
      assert length(result.errors) == 1

      error = hd(result.errors)
      assert error.txid == @valid_txid
      assert error.error == "Input not found or already spent"
    end

    test "handles minimal result data" do
      attrs = %{"hex" => @valid_hex}

      assert {:ok, %SignRawTransactionWithWalletResult{} = result} =
               SignRawTransactionWithWalletResult.new(attrs)

      assert result.hex == @valid_hex
      assert is_nil(result.complete)
      assert result.errors == []
    end

    test "validates hex field format" do
      attrs = %{"hex" => "invalid_hex_string!"}

      assert {:error, %Changeset{} = changeset} =
               SignRawTransactionWithWalletResult.new(attrs)

      assert "must be a valid hex string" in errors_on(changeset).hex
    end
  end

  describe "SignRawTransactionWithWalletResult.new!/1" do
    test "creates result with valid data" do
      attrs = sign_raw_transaction_with_wallet_result_fixture()

      assert %SignRawTransactionWithWalletResult{} =
               SignRawTransactionWithWalletResult.new!(attrs)
    end

    test "raises error for invalid data" do
      attrs = %{"hex" => "invalid_hex!"}

      assert_raise Ecto.InvalidChangesetError, fn ->
        SignRawTransactionWithWalletResult.new!(attrs)
      end
    end
  end

  ## SignRawTransactionWithWallet RPC

  describe "(RPC) Wallets.sign_raw_transaction_with_wallet/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "calls signrawtransactionwithwallet RPC method", %{client: client} do
      result_fixture = sign_raw_transaction_with_wallet_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "signrawtransactionwithwallet",
                   "params" => [@valid_hex, [], "ALL"],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %SignRawTransactionWithWalletResult{} = result} =
               Wallets.sign_raw_transaction_with_wallet(client, hexstring: @valid_hex)

      assert result.complete == true
      assert result.errors == []
    end

    test "calls with wallet name", %{client: client} do
      result_fixture = sign_raw_transaction_with_wallet_result_fixture()
      url = Path.join(@url, "/wallet/#{@valid_wallet_name}")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "signrawtransactionwithwallet",
                   "params" => [@valid_hex, [], "ALL"],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %SignRawTransactionWithWalletResult{}} =
               Wallets.sign_raw_transaction_with_wallet(client,
                 hexstring: @valid_hex,
                 wallet_name: @valid_wallet_name
               )
    end

    test "handles incomplete transaction signing", %{client: client} do
      result_fixture =
        sign_raw_transaction_with_wallet_result_fixture(%{
          "complete" => false,
          "errors" => [
            %{
              "txid" => @valid_txid,
              "vout" => 0,
              "error" => "Input not found or already spent"
            }
          ]
        })

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %SignRawTransactionWithWalletResult{} = result} =
               Wallets.sign_raw_transaction_with_wallet(client, hexstring: @valid_hex)

      assert result.complete == false
      assert length(result.errors) == 1

      error = hd(result.errors)
      assert error.error == "Input not found or already spent"
    end

    test "signs with previous transactions", %{client: client} do
      result_fixture = sign_raw_transaction_with_wallet_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)

          # Verify prevtxs parameter
          assert [_hex, [prevtx], _] = decoded_body["params"]
          assert prevtx["txid"] == @valid_txid
          assert prevtx["amount"] == 0.01

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %SignRawTransactionWithWalletResult{}} =
               Wallets.sign_raw_transaction_with_wallet(client,
                 hexstring: @valid_hex,
                 prevtxs: [
                   %{
                     txid: @valid_txid,
                     vout: 0,
                     script_pub_key: "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac",
                     amount: 0.01
                   }
                 ]
               )
    end

    test "signs with custom signature hash type", %{client: client} do
      result_fixture = sign_raw_transaction_with_wallet_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)

          # Verify sighashtype parameter
          assert [_hex, [], "SINGLE"] = decoded_body["params"]

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %SignRawTransactionWithWalletResult{}} =
               Wallets.sign_raw_transaction_with_wallet(client,
                 hexstring: @valid_hex,
                 sighashtype: "SINGLE"
               )
    end

    test "returns error for invalid request", %{client: client} do
      assert {:error, %Ecto.Changeset{}} =
               Wallets.sign_raw_transaction_with_wallet(client, hexstring: "invalid_hex!")
    end

    test "returns error for RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -18,
                "message" => "Wallet not loaded"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -18}} =
               Wallets.sign_raw_transaction_with_wallet(client, hexstring: @valid_hex)
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.sign_raw_transaction_with_wallet!(client, hexstring: @valid_hex)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client()

      # Create a new wallet for testing
      wallet_name = "sign-raw-tx-test-#{UUID.generate()}"

      wallet =
        Wallets.create_wallet!(
          real_client,
          [wallet_name: wallet_name, passphrase: "test"],
          retries: 10
        )

      # TODO: Provide a successful case scenario.
      # This test would need a valid raw transaction hex to sign
      # For now, we just test that the function exists and can be called
      assert {:error, %BTx.RPC.MethodError{}} =
               Wallets.sign_raw_transaction_with_wallet(
                 real_client,
                 [hexstring: @valid_hex, wallet_name: wallet.name],
                 retries: 10
               )
    end
  end

  describe "(RPC) Wallets.sign_raw_transaction_with_wallet!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns result on success", %{client: client} do
      result_fixture = sign_raw_transaction_with_wallet_result_fixture()

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert %SignRawTransactionWithWalletResult{} =
               Wallets.sign_raw_transaction_with_wallet!(client, hexstring: @valid_hex)
    end

    test "raises error for invalid request", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.sign_raw_transaction_with_wallet!(client, hexstring: "invalid_hex!")
      end
    end

    test "raises error for RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -18,
                "message" => "Wallet not loaded"
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, fn ->
        Wallets.sign_raw_transaction_with_wallet!(client, hexstring: @valid_hex)
      end
    end
  end
end
