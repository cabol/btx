defmodule BTx.RPC.RawTransactions.SignRawTransactionWithKeyTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.RawTransactionsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Blockchain, Encodable, RawTransactions, Request}
  alias BTx.RPC.RawTransactions.{SignRawTransactionWithKey, SignRawTransactionWithKeyResult}
  alias BTx.RPC.RawTransactions.RawTransaction.{PrevTx, ScriptVerificationError}
  alias Ecto.Changeset

  @url "http://localhost:18443/"
  @valid_hex get_raw_transaction_hex_fixture()
  @valid_privkey "L1aW4aubDFB7yfras2S1mME3bFqiXgYF73PvvrLXa8hT8VwQDfV3"
  @valid_txid "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

  ## PrevTx schema tests

  describe "PrevTx changeset/2" do
    test "validates valid prevtx data" do
      attrs = sign_raw_transaction_prevtx_fixture()

      changeset = PrevTx.changeset(%PrevTx{}, attrs)
      assert changeset.valid?

      prevtx = Changeset.apply_changes(changeset)
      assert prevtx.txid == attrs["txid"]
      assert prevtx.vout == attrs["vout"]
      assert prevtx.script_pub_key == attrs["scriptPubKey"]
    end

    test "validates required fields" do
      changeset = PrevTx.changeset(%PrevTx{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).txid
      assert "can't be blank" in errors_on(changeset).vout
      assert "can't be blank" in errors_on(changeset).script_pub_key
    end

    test "validates txid format" do
      attrs = sign_raw_transaction_prevtx_fixture(%{"txid" => "invalid"})
      changeset = PrevTx.changeset(%PrevTx{}, attrs)
      refute changeset.valid?
      assert "has invalid format" in errors_on(changeset).txid
      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "validates vout is non-negative" do
      attrs = sign_raw_transaction_prevtx_fixture(%{"vout" => -1})
      changeset = PrevTx.changeset(%PrevTx{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).vout
    end

    test "validates hex fields" do
      attrs = sign_raw_transaction_prevtx_fixture(%{"scriptPubKey" => "invalid hex"})
      changeset = PrevTx.changeset(%PrevTx{}, attrs)
      refute changeset.valid?
      assert "must be a valid hex string" in errors_on(changeset).script_pub_key
    end

    test "validates amount is positive when provided" do
      attrs = sign_raw_transaction_prevtx_fixture(%{"amount" => -1.0})
      changeset = PrevTx.changeset(%PrevTx{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).amount
    end

    test "accepts optional fields" do
      attrs = %{
        "txid" => @valid_txid,
        "vout" => 0,
        "scriptPubKey" => "deadbeef"
      }

      changeset = PrevTx.changeset(%PrevTx{}, attrs)
      assert changeset.valid?
    end
  end

  describe "PrevTx to_map/1" do
    test "converts a PrevTx schema to a map" do
      attrs = sign_raw_transaction_prevtx_fixture()

      changeset = PrevTx.changeset(%PrevTx{}, attrs)
      assert changeset.valid?

      prevtx = Changeset.apply_changes(changeset)
      map = PrevTx.to_map(prevtx)
      assert map == attrs
    end

    test "converts a PrevTx schema to a map with nil fields" do
      attrs =
        sign_raw_transaction_prevtx_fixture(%{
          "redeemScript" => nil,
          "witnessScript" => nil
        })

      changeset = PrevTx.changeset(%PrevTx{}, attrs)
      assert changeset.valid?

      prevtx = Changeset.apply_changes(changeset)
      map = PrevTx.to_map(prevtx)
      assert map == attrs |> Map.drop(["redeemScript", "witnessScript"])
    end
  end

  ## ScriptVerificationError schema tests

  describe "ScriptVerificationError changeset/2" do
    test "validates valid error data" do
      attrs = sign_raw_transaction_error_fixture()

      changeset = ScriptVerificationError.changeset(%ScriptVerificationError{}, attrs)
      assert changeset.valid?

      error = Changeset.apply_changes(changeset)
      assert error.txid == attrs["txid"]
      assert error.vout == attrs["vout"]
      assert error.error == attrs["error"]
    end

    test "accepts all optional fields" do
      changeset = ScriptVerificationError.changeset(%ScriptVerificationError{}, %{})
      assert changeset.valid?
    end

    test "validates txid format when provided" do
      attrs = sign_raw_transaction_error_fixture(%{"txid" => "invalid"})
      changeset = ScriptVerificationError.changeset(%ScriptVerificationError{}, attrs)
      refute changeset.valid?
      assert "has invalid format" in errors_on(changeset).txid
    end

    test "validates vout is non-negative when provided" do
      attrs = sign_raw_transaction_error_fixture(%{"vout" => -1})
      changeset = ScriptVerificationError.changeset(%ScriptVerificationError{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).vout
    end
  end

  ## SignRawTransactionWithKeyResult schema tests

  describe "SignRawTransactionWithKeyResult.new/1" do
    test "creates a new result with valid data" do
      attrs = sign_raw_transaction_with_key_result_fixture()

      assert {:ok, %SignRawTransactionWithKeyResult{} = result} =
               SignRawTransactionWithKeyResult.new(attrs)

      assert result.hex == attrs["hex"]
      assert result.complete == attrs["complete"]
      assert Enum.empty?(result.errors)
    end

    test "handles result with errors" do
      attrs =
        sign_raw_transaction_with_key_result_fixture(%{
          "complete" => false,
          "errors" => [sign_raw_transaction_error_fixture()]
        })

      assert {:ok, %SignRawTransactionWithKeyResult{} = result} =
               SignRawTransactionWithKeyResult.new(attrs)

      assert result.complete == false
      assert length(result.errors) == 1
      assert hd(result.errors).error == "Script verification failed"
    end

    test "validates hex format" do
      attrs = sign_raw_transaction_with_key_result_fixture(%{"hex" => "invalid hex"})

      assert {:error, %Changeset{} = changeset} = SignRawTransactionWithKeyResult.new(attrs)
      assert "must be a valid hex string" in errors_on(changeset).hex
    end
  end

  ## SignRawTransactionWithKey schema tests

  describe "SignRawTransactionWithKey.new/1" do
    test "creates a new request with required fields" do
      attrs = %{
        hexstring: @valid_hex,
        privkeys: [@valid_privkey]
      }

      assert {:ok, %SignRawTransactionWithKey{} = request} =
               SignRawTransactionWithKey.new(attrs)

      assert request.hexstring == @valid_hex
      assert request.privkeys == [@valid_privkey]
      assert request.sighashtype == "ALL"
      assert request.prevtxs == []
    end

    test "creates a new request with all fields" do
      attrs = %{
        hexstring: @valid_hex,
        privkeys: [@valid_privkey],
        prevtxs: [sign_raw_transaction_prevtx_fixture()],
        sighashtype: "SINGLE"
      }

      assert {:ok, %SignRawTransactionWithKey{} = request} =
               SignRawTransactionWithKey.new(attrs)

      assert request.hexstring == @valid_hex
      assert request.privkeys == [@valid_privkey]
      assert request.sighashtype == "SINGLE"
      assert length(request.prevtxs) == 1
    end

    test "validates required fields" do
      assert {:error, %Changeset{} = changeset} = SignRawTransactionWithKey.new(%{})
      assert "can't be blank" in errors_on(changeset).hexstring
      assert "can't be blank" in errors_on(changeset).privkeys
    end

    test "validates hexstring format" do
      attrs = %{
        hexstring: "invalid hex",
        privkeys: [@valid_privkey]
      }

      assert {:error, %Changeset{} = changeset} = SignRawTransactionWithKey.new(attrs)
      assert "must be a valid hex string" in errors_on(changeset).hexstring
    end

    test "validates privkeys array is not empty" do
      attrs = %{
        hexstring: @valid_hex,
        privkeys: []
      }

      assert {:error, %Changeset{} = changeset} = SignRawTransactionWithKey.new(attrs)
      assert "should have at least 1 item(s)" in errors_on(changeset).privkeys
    end

    test "validates privkey format" do
      attrs = %{
        hexstring: @valid_hex,
        privkeys: ["invalid_privkey"]
      }

      assert {:error, %Changeset{} = changeset} = SignRawTransactionWithKey.new(attrs)
      assert "contains invalid private keys" in errors_on(changeset).privkeys
    end

    test "validates sighashtype inclusion" do
      attrs = %{
        hexstring: @valid_hex,
        privkeys: [@valid_privkey],
        sighashtype: "INVALID"
      }

      assert {:error, %Changeset{} = changeset} = SignRawTransactionWithKey.new(attrs)
      assert "is invalid" in errors_on(changeset).sighashtype
    end

    test "accepts valid sighash types" do
      valid_types = ~w(ALL NONE SINGLE ALL|ANYONECANPAY NONE|ANYONECANPAY SINGLE|ANYONECANPAY)

      for sighash_type <- valid_types do
        attrs = %{
          hexstring: @valid_hex,
          privkeys: [@valid_privkey],
          sighashtype: sighash_type
        }

        assert {:ok, %SignRawTransactionWithKey{}} = SignRawTransactionWithKey.new(attrs)
      end
    end
  end

  describe "SignRawTransactionWithKey.new!/1" do
    test "creates a new request with valid params" do
      attrs = %{
        hexstring: @valid_hex,
        privkeys: [@valid_privkey]
      }

      assert %SignRawTransactionWithKey{} = SignRawTransactionWithKey.new!(attrs)
    end

    test "raises error for invalid params" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        SignRawTransactionWithKey.new!(%{hexstring: "invalid", privkeys: []})
      end
    end
  end

  describe "SignRawTransactionWithKey encodable" do
    test "encodes method with required fields only" do
      attrs = %{
        hexstring: @valid_hex,
        privkeys: [@valid_privkey]
      }

      request = SignRawTransactionWithKey.new!(attrs)
      encoded = Encodable.encode(request)

      assert %Request{
               params: [@valid_hex, [@valid_privkey], [], "ALL"],
               method: "signrawtransactionwithkey",
               jsonrpc: "1.0",
               path: "/"
             } = encoded
    end

    test "encodes method with prevtxs" do
      prevtx_attrs = sign_raw_transaction_prevtx_fixture()

      attrs = %{
        hexstring: @valid_hex,
        privkeys: [@valid_privkey],
        prevtxs: [prevtx_attrs]
      }

      request = SignRawTransactionWithKey.new!(attrs)
      encoded = Encodable.encode(request)

      assert %{encoded | id: nil} == %Request{
               params: [
                 @valid_hex,
                 [@valid_privkey],
                 [
                   %{
                     "txid" => prevtx_attrs["txid"],
                     "vout" => prevtx_attrs["vout"],
                     "scriptPubKey" => prevtx_attrs["scriptPubKey"],
                     "redeemScript" => prevtx_attrs["redeemScript"],
                     "witnessScript" => prevtx_attrs["witnessScript"],
                     "amount" => prevtx_attrs["amount"]
                   }
                 ],
                 "ALL"
               ],
               method: "signrawtransactionwithkey"
             }
    end

    test "encodes method with custom sighashtype" do
      attrs = %{
        hexstring: @valid_hex,
        privkeys: [@valid_privkey],
        sighashtype: "NONE|ANYONECANPAY"
      }

      request = SignRawTransactionWithKey.new!(attrs)
      encoded = Encodable.encode(request)

      assert %Request{
               params: [@valid_hex, [@valid_privkey], [], "NONE|ANYONECANPAY"]
             } = encoded
    end
  end

  ## RawTransactions RPC tests

  describe "(RPC) RawTransactions.sign_raw_transaction_with_key/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns signed transaction", %{client: client} do
      response_data = sign_raw_transaction_with_key_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "signrawtransactionwithkey",
                   "params" => [@valid_hex, [@valid_privkey], [], "ALL"],
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

      assert {:ok, %SignRawTransactionWithKeyResult{} = result} =
               RawTransactions.sign_raw_transaction_with_key(client,
                 hexstring: @valid_hex,
                 privkeys: [@valid_privkey]
               )

      assert result.hex == response_data["hex"]
      assert result.complete == response_data["complete"]
    end

    test "successful call with prevtxs", %{client: client} do
      response_data = sign_raw_transaction_with_key_result_fixture()
      prevtx_attrs = sign_raw_transaction_prevtx_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)
          assert decoded_body["method"] == "signrawtransactionwithkey"
          # prevtxs array has 1 item
          assert length(hd(tl(tl(decoded_body["params"])))) == 1

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => response_data,
              "error" => nil
            }
          }
      end)

      assert {:ok, %SignRawTransactionWithKeyResult{}} =
               RawTransactions.sign_raw_transaction_with_key(client,
                 hexstring: @valid_hex,
                 privkeys: [@valid_privkey],
                 prevtxs: [prevtx_attrs]
               )
    end

    test "handles incomplete signing with errors", %{client: client} do
      response_data =
        sign_raw_transaction_with_key_result_fixture(%{
          "complete" => false,
          "errors" => [sign_raw_transaction_error_fixture()]
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

      assert {:ok, %SignRawTransactionWithKeyResult{} = result} =
               RawTransactions.sign_raw_transaction_with_key(client,
                 hexstring: @valid_hex,
                 privkeys: [@valid_privkey]
               )

      assert result.complete == false
      assert length(result.errors) == 1
      assert hd(result.errors).error == "Script verification failed"
    end

    test "handles RPC error response", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -8,
                "message" => "Invalid private key"
              }
            }
          }
      end)

      assert {:error,
              %BTx.RPC.MethodError{
                code: -8,
                message: "Invalid private key",
                reason: :invalid_parameter
              }} =
               RawTransactions.sign_raw_transaction_with_key(client,
                 hexstring: @valid_hex,
                 privkeys: ["5HueCGU8rMjxEXxiPuD5BDuRaU9tGm4b5NxkREAJnFsZVDa3sZH"]
               )
    end

    test "handles validation error for invalid hexstring", %{client: client} do
      assert {:error, %Changeset{}} =
               RawTransactions.sign_raw_transaction_with_key(client,
                 hexstring: "invalid hex",
                 privkeys: [@valid_privkey]
               )
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node with wallet and funds
      real_client = new_client()

      # Get the best block hash first
      assert {:ok, blockchain_info} = Blockchain.get_blockchain_info(real_client, retries: 10)
      blockhash = blockchain_info.bestblockhash

      # Get a transaction from the block
      {:ok, %{tx: [txid | _]}} =
        Blockchain.get_block(real_client, [blockhash: blockhash], retries: 10)

      # Get the raw transaction to use as a template
      {:ok, hex_string} =
        RawTransactions.get_raw_transaction(
          real_client,
          [txid: txid, verbose: false],
          retries: 10
        )

      # TODO: Provide a successful case scenario.
      # For a real test, we would need actual private keys and a properly
      # constructed unsigned transaction. This is a basic test to ensure the
      # function works.
      # Note: This will likely fail with "Invalid private key" which is expected
      # since we're using a test key, but it proves the RPC call structure is
      # correct.
      private_key = "5HueCGU8rMjxEXxiPuD5BDuRaU9tGm4b5NxkREAJnFsZVDa3sZH"

      result =
        RawTransactions.sign_raw_transaction_with_key(
          real_client,
          [
            hexstring: hex_string,
            privkeys: [private_key]
          ],
          retries: 10
        )

      # The call should either succeed or fail with a specific Bitcoin Core error
      case result do
        {:ok, %SignRawTransactionWithKeyResult{} = signed_result} ->
          assert is_binary(signed_result.hex)
          assert is_boolean(signed_result.complete)

        {:error, %BTx.RPC.MethodError{} = error} ->
          assert error.code == -5
          assert error.message == "Invalid private key"
      end
    end
  end

  describe "(RPC) RawTransactions.sign_raw_transaction_with_key!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns signed transaction", %{client: client} do
      response_data = sign_raw_transaction_with_key_result_fixture()

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

      assert %SignRawTransactionWithKeyResult{} =
               result =
               RawTransactions.sign_raw_transaction_with_key!(client,
                 hexstring: @valid_hex,
                 privkeys: [@valid_privkey]
               )

      assert result.hex == response_data["hex"]
      assert result.complete == response_data["complete"]
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        RawTransactions.sign_raw_transaction_with_key!(client,
          hexstring: @valid_hex,
          privkeys: [@valid_privkey]
        )
      end
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        RawTransactions.sign_raw_transaction_with_key!(client,
          hexstring: "invalid hex",
          privkeys: [@valid_privkey]
        )
      end
    end
  end
end
