defmodule RawTransactions.SendRawTransactionTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.RawTransactionsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, RawTransactions, Request, Wallets}
  alias BTx.RPC.RawTransactions.SendRawTransaction
  alias Ecto.Changeset

  @valid_hex "0200000001abc123def456789abc123def456789abc123def456789abc123def456789ab00000000484730440220123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef01022012345678901234567890123456789012345678901234567890123456789012340121023456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456ffffffff0100e1f50500000000160014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2600000000"

  @url "http://localhost:18443/"

  ## Schema tests

  describe "SendRawTransaction.new/1" do
    test "creates a new SendRawTransaction with required fields" do
      assert {:ok, %SendRawTransaction{} = request} =
               SendRawTransaction.new(hexstring: @valid_hex)

      assert request.hexstring == @valid_hex
      assert request.method == "sendrawtransaction"
      assert request.maxfeerate == 0.10
    end

    test "creates a new SendRawTransaction with all parameters" do
      assert {:ok, %SendRawTransaction{} = request} =
               SendRawTransaction.new(
                 hexstring: @valid_hex,
                 maxfeerate: 0.05
               )

      assert request.hexstring == @valid_hex
      assert request.maxfeerate == 0.05
    end

    test "uses default values for optional fields" do
      assert {:ok, %SendRawTransaction{} = request} =
               SendRawTransaction.new(hexstring: @valid_hex)

      assert request.maxfeerate == 0.10
    end

    test "accepts valid maxfeerate values" do
      valid_rates = [0, 0.01, 0.10, 1.0, 10.0]

      for rate <- valid_rates do
        expected_rate = rate / 1

        assert {:ok, %SendRawTransaction{maxfeerate: ^expected_rate}} =
                 SendRawTransaction.new(
                   hexstring: @valid_hex,
                   maxfeerate: rate
                 )
      end
    end

    test "returns error for missing hexstring" do
      assert {:error, %Changeset{errors: errors}} = SendRawTransaction.new(%{})

      assert Keyword.fetch!(errors, :hexstring) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for empty hexstring" do
      assert {:error, %Changeset{errors: errors}} =
               SendRawTransaction.new(hexstring: "")

      assert Keyword.fetch!(errors, :hexstring) ==
               {"can't be blank", [validation: :required]}
    end

    test "returns error for invalid hexstring" do
      assert {:error, %Changeset{} = changeset} =
               SendRawTransaction.new(hexstring: "invalid_hex!")

      assert "must be a valid hex string" in errors_on(changeset).hexstring
    end

    test "returns error for negative maxfeerate" do
      assert {:error, %Changeset{} = changeset} =
               SendRawTransaction.new(
                 hexstring: @valid_hex,
                 maxfeerate: -0.01
               )

      assert "must be greater than or equal to 0" in errors_on(changeset).maxfeerate
    end

    test "accepts keyword list params" do
      assert {:ok, %SendRawTransaction{} = request} =
               SendRawTransaction.new(
                 hexstring: @valid_hex,
                 maxfeerate: 0.05
               )

      assert request.hexstring == @valid_hex
      assert request.maxfeerate == 0.05
    end
  end

  describe "SendRawTransaction.new!/1" do
    test "creates a new SendRawTransaction with valid data" do
      assert %SendRawTransaction{} =
               SendRawTransaction.new!(hexstring: @valid_hex)
    end

    test "raises error for invalid data" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        SendRawTransaction.new!(hexstring: "invalid_hex!")
      end
    end
  end

  describe "SendRawTransaction encodable" do
    test "encodes minimal request correctly" do
      request = SendRawTransaction.new!(hexstring: @valid_hex)

      assert %Request{
               method: "sendrawtransaction",
               path: "/",
               params: [@valid_hex, 0.10]
             } = Encodable.encode(request)
    end

    test "encodes request with custom maxfeerate" do
      request =
        SendRawTransaction.new!(
          hexstring: @valid_hex,
          maxfeerate: 0.05
        )

      assert %Request{
               method: "sendrawtransaction",
               path: "/",
               params: [@valid_hex, 0.05]
             } = Encodable.encode(request)
    end

    test "trims trailing default maxfeerate" do
      request = SendRawTransaction.new!(hexstring: @valid_hex, maxfeerate: 0.10)

      encoded = Encodable.encode(request)

      # Should not include default maxfeerate when it's the default value
      assert encoded.params == [@valid_hex, 0.10]
    end

    test "includes maxfeerate when different from default" do
      request = SendRawTransaction.new!(hexstring: @valid_hex, maxfeerate: 0.05)

      encoded = Encodable.encode(request)

      assert encoded.params == [@valid_hex, 0.05]
    end
  end

  describe "SendRawTransaction changeset/2" do
    test "accepts valid parameters" do
      attrs = %{
        hexstring: @valid_hex,
        maxfeerate: 0.05
      }

      changeset = SendRawTransaction.changeset(%SendRawTransaction{}, attrs)
      assert changeset.valid?
    end

    test "validates required hexstring field" do
      changeset = SendRawTransaction.changeset(%SendRawTransaction{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).hexstring
    end

    test "validates maxfeerate bounds" do
      # Valid values
      for rate <- [0, 0.01, 0.10, 1.0] do
        attrs = %{hexstring: @valid_hex, maxfeerate: rate}
        changeset = SendRawTransaction.changeset(%SendRawTransaction{}, attrs)
        assert changeset.valid?, "#{rate} should be valid"
      end

      # Invalid negative value
      attrs = %{hexstring: @valid_hex, maxfeerate: -0.01}
      changeset = SendRawTransaction.changeset(%SendRawTransaction{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).maxfeerate
    end
  end

  ## SendRawTransaction RPC

  describe "(RPC) RawTransactions.send_raw_transaction/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "calls sendrawtransaction RPC method", %{client: client} do
      txid = send_raw_transaction_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "sendrawtransaction",
                   "params" => [@valid_hex, 0.10],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => txid,
              "error" => nil
            }
          }
      end)

      assert {:ok, result_txid} =
               RawTransactions.send_raw_transaction(client, hexstring: @valid_hex)

      assert result_txid == txid
      assert is_binary(result_txid)
      assert String.length(result_txid) == 64
    end

    test "sends transaction with custom maxfeerate", %{client: client} do
      txid = send_raw_transaction_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)

          assert %{
                   "method" => "sendrawtransaction",
                   "params" => [@valid_hex, 0.05],
                   "jsonrpc" => "1.0"
                 } = decoded_body

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => txid,
              "error" => nil
            }
          }
      end)

      assert {:ok, result_txid} =
               RawTransactions.send_raw_transaction(client,
                 hexstring: @valid_hex,
                 maxfeerate: 0.05
               )

      assert result_txid == txid
    end

    test "sends transaction with no fee limit", %{client: client} do
      txid = send_raw_transaction_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)

          # Verify maxfeerate is 0 (no limit)
          assert [_hex, +0.0] = decoded_body["params"]

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => txid,
              "error" => nil
            }
          }
      end)

      assert {:ok, result_txid} =
               RawTransactions.send_raw_transaction(client,
                 hexstring: @valid_hex,
                 maxfeerate: 0
               )

      assert result_txid == txid
    end

    test "returns error for invalid request", %{client: client} do
      assert {:error, %Ecto.Changeset{}} =
               RawTransactions.send_raw_transaction(client, hexstring: "invalid_hex!")
    end

    test "returns error for RPC error - fee too high", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -26,
                "message" => "absurdly-high-fee"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -26, reason: :verify_rejected}} =
               RawTransactions.send_raw_transaction(client, hexstring: @valid_hex)
    end

    test "returns error for RPC error - invalid transaction", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -22,
                "message" => "TX decode failed"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -22, reason: :deserialization_error}} =
               RawTransactions.send_raw_transaction(client, hexstring: @valid_hex)
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        RawTransactions.send_raw_transaction!(client, hexstring: @valid_hex)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client(retry_opts: [max_retries: 10, delay: :timer.seconds(1)])

      # Wallet for this test
      wallet_name = "btx-shared-test-wallet"

      # Get a new address to send to
      address =
        Wallets.get_new_address!(
          real_client,
          wallet_name: wallet_name,
          label: "test_send"
        )

      assert_eventually do
        # Get unspent outputs
        unspent =
          Wallets.list_unspent!(
            real_client,
            wallet_name: wallet_name
          )

        utxo =
          unspent
          |> Enum.sort_by(& &1.amount, :desc)
          |> hd()

        # Create a raw transaction
        {:ok, raw_tx} =
          RawTransactions.create_raw_transaction(
            real_client,
            inputs: [%{txid: utxo.txid, vout: utxo.vout}],
            outputs: %{
              addresses: [%{address: address, amount: 0.0001}]
            }
          )

        # Sign the transaction
        {:ok, signed_result} =
          Wallets.sign_raw_transaction_with_wallet(
            real_client,
            hexstring: raw_tx,
            wallet_name: wallet_name
          )

        # Send the signed transaction
        assert {:ok, txid} =
                 RawTransactions.send_raw_transaction(
                   real_client,
                   hexstring: signed_result.hex,
                   maxfeerate: 0
                 )

        # Verify we got a valid transaction hash
        assert is_binary(txid)
        assert String.length(txid) == 64
        assert String.match?(txid, ~r/^[a-fA-F0-9]{64}$/)
      end
    end
  end

  describe "(RPC) RawTransactions.send_raw_transaction!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns transaction hash on success", %{client: client} do
      txid = send_raw_transaction_result_fixture()

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => txid,
              "error" => nil
            }
          }
      end)

      assert result_txid = RawTransactions.send_raw_transaction!(client, hexstring: @valid_hex)
      assert result_txid == txid
    end

    test "raises error for invalid request", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        RawTransactions.send_raw_transaction!(client, hexstring: "invalid_hex!")
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
                "code" => -26,
                "message" => "absurdly-high-fee"
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, fn ->
        RawTransactions.send_raw_transaction!(client, hexstring: @valid_hex)
      end
    end
  end
end
