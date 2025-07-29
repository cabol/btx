defmodule BTx.RPC.RawTransactions.GetRawTransactionTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.RawTransactionsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Blockchain, Encodable, RawTransactions, Request}
  alias BTx.RPC.RawTransactions.{GetRawTransaction, GetRawTransactionResult}
  alias BTx.RPC.RawTransactions.GetRawTransaction.{Vin, Vout}
  alias BTx.RPC.RawTransactions.GetRawTransaction.Vout.ScriptPubKey
  alias Ecto.Changeset

  @url "http://localhost:18443/"
  @valid_txid "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  @valid_blockhash "0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcd"

  ## GetRawTransaction schema tests

  describe "GetRawTransaction.new/1" do
    test "creates a new GetRawTransaction with required fields" do
      assert {:ok, %GetRawTransaction{} = request} =
               GetRawTransaction.new(txid: @valid_txid)

      assert request.txid == @valid_txid
      assert request.verbose == false
      assert request.blockhash == nil
    end

    test "creates a new GetRawTransaction with all fields" do
      assert {:ok, %GetRawTransaction{} = request} =
               GetRawTransaction.new(
                 txid: @valid_txid,
                 verbose: true,
                 blockhash: @valid_blockhash
               )

      assert request.txid == @valid_txid
      assert request.verbose == true
      assert request.blockhash == @valid_blockhash
    end

    test "validates required txid field" do
      assert {:error, %Changeset{} = changeset} = GetRawTransaction.new(%{})
      assert "can't be blank" in errors_on(changeset).txid
    end

    test "validates txid format" do
      assert {:error, %Changeset{} = changeset} =
               GetRawTransaction.new(txid: "invalid")

      errors = errors_on(changeset).txid
      assert "has invalid format" in errors
      assert "should be 64 character(s)" in errors
    end

    test "validates blockhash format" do
      assert {:error, %Changeset{} = changeset} =
               GetRawTransaction.new(txid: @valid_txid, blockhash: "invalid")

      errors = errors_on(changeset).blockhash
      assert "has invalid format" in errors
      assert "should be 64 character(s)" in errors
    end
  end

  describe "GetRawTransaction.new!/1" do
    test "creates a new GetRawTransaction with valid params" do
      assert %GetRawTransaction{} =
               GetRawTransaction.new!(txid: @valid_txid, verbose: true)
    end

    test "raises error for invalid params" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetRawTransaction.new!(txid: "invalid")
      end
    end
  end

  describe "GetRawTransaction encodable" do
    test "encodes method with required fields only" do
      assert %Request{
               params: [@valid_txid, false, nil],
               method: "getrawtransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetRawTransaction.new!(txid: @valid_txid)
               |> Encodable.encode()
    end

    test "encodes method with verbose parameter" do
      assert %Request{
               params: [@valid_txid, true, nil],
               method: "getrawtransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetRawTransaction.new!(txid: @valid_txid, verbose: true)
               |> Encodable.encode()
    end

    test "encodes method with all parameters" do
      assert %Request{
               params: [@valid_txid, true, @valid_blockhash],
               method: "getrawtransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetRawTransaction.new!(
                 txid: @valid_txid,
                 verbose: true,
                 blockhash: @valid_blockhash
               )
               |> Encodable.encode()
    end

    test "encodes method with blockhash but no verbose (false by default)" do
      assert %Request{
               params: [@valid_txid, false, @valid_blockhash],
               method: "getrawtransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetRawTransaction.new!(
                 txid: @valid_txid,
                 blockhash: @valid_blockhash
               )
               |> Encodable.encode()
    end
  end

  ## Nested schema tests

  describe "Vin changeset/2" do
    test "validates valid vin data" do
      attrs = vin_fixture()
      changeset = Vin.changeset(%Vin{}, attrs)
      assert changeset.valid?
    end

    test "validates txid format" do
      attrs = vin_fixture(%{"txid" => "invalid"})
      changeset = Vin.changeset(%Vin{}, attrs)
      refute changeset.valid?
      assert "has invalid format" in errors_on(changeset).txid
      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "validates vout is non-negative" do
      attrs = vin_fixture(%{"vout" => -1})
      changeset = Vin.changeset(%Vin{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).vout
    end
  end

  describe "ScriptPubKey changeset/2" do
    test "validates valid script data" do
      attrs = script_pub_key_fixture()
      changeset = ScriptPubKey.changeset(%ScriptPubKey{}, attrs)
      assert changeset.valid?
    end

    test "validates script type inclusion" do
      valid_types = ~w(nonstandard pubkey pubkeyhash scripthash multisig nulldata
                       witness_v0_keyhash witness_v0_scripthash witness_v1_taproot
                       witness_unknown)

      for script_type <- valid_types do
        attrs = script_pub_key_fixture(%{"type" => script_type})
        changeset = ScriptPubKey.changeset(%ScriptPubKey{}, attrs)
        assert changeset.valid?
      end

      # Invalid type
      attrs = script_pub_key_fixture(%{"type" => "invalid"})
      changeset = ScriptPubKey.changeset(%ScriptPubKey{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).type
    end
  end

  describe "Vout changeset/2" do
    test "validates valid vout data" do
      attrs = vout_fixture()
      changeset = Vout.changeset(%Vout{}, attrs)
      assert changeset.valid?
    end

    test "validates value is non-negative" do
      attrs = vout_fixture(%{"value" => -1.0})
      changeset = Vout.changeset(%Vout{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).value
    end

    test "validates n is non-negative" do
      attrs = vout_fixture(%{"n" => -1})
      changeset = Vout.changeset(%Vout{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).n
    end

    test "normalizes scriptPubKey field" do
      attrs = %{"scriptPubKey" => script_pub_key_fixture()}
      changeset = Vout.changeset(%Vout{}, attrs)
      assert changeset.valid?
      # Check that the field was normalized and embedded properly
      vout = Changeset.apply_changes(changeset)
      assert %ScriptPubKey{} = vout.script_pub_key
    end
  end

  ## GetRawTransactionResult tests

  describe "GetRawTransactionResult.new/1" do
    test "creates result from valid transaction data" do
      attrs = get_raw_transaction_preset(:standard)

      assert {:ok, %GetRawTransactionResult{} = result} =
               GetRawTransactionResult.new(attrs)

      assert result.txid == "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
      assert result.confirmations == 100
      assert length(result.vin) == 1
      assert length(result.vout) == 2
    end

    test "handles segwit transaction" do
      attrs = get_raw_transaction_preset(:segwit)

      assert {:ok, %GetRawTransactionResult{} = result} =
               GetRawTransactionResult.new(attrs)

      # Check witness data
      assert [vin] = result.vin
      assert length(vin.txinwitness) > 0

      # Check witness output
      assert [vout | _] = result.vout
      assert vout.script_pub_key.type == "witness_v0_keyhash"
    end

    test "handles unconfirmed transaction" do
      attrs = get_raw_transaction_preset(:unconfirmed)

      assert {:ok, %GetRawTransactionResult{} = result} =
               GetRawTransactionResult.new(attrs)

      assert result.confirmations == 0
      assert result.blockhash == nil
      assert result.blocktime == nil
    end

    test "validates txid format" do
      attrs = get_raw_transaction_result_fixture(%{"txid" => "invalid"})

      assert {:error, %Changeset{} = changeset} = GetRawTransactionResult.new(attrs)
      assert "has invalid format" in errors_on(changeset).txid
      assert "should be 64 character(s)" in errors_on(changeset).txid
    end
  end

  ## RawTransactions RPC tests

  describe "(RPC) RawTransactions.get_raw_transaction/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns hex string when verbose=false", %{client: client} do
      hex_result = get_raw_transaction_hex_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getrawtransaction",
                   "params" => [@valid_txid, false, nil],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => hex_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, ^hex_result} =
               RawTransactions.get_raw_transaction(client, txid: @valid_txid)
    end

    test "successful call returns structured object when verbose=true", %{client: client} do
      tx_result = get_raw_transaction_preset(:standard)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getrawtransaction",
                   "params" => [@valid_txid, true, nil],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => tx_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetRawTransactionResult{} = result} =
               RawTransactions.get_raw_transaction(client, txid: @valid_txid, verbose: true)

      assert result.txid == "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
      assert length(result.vin) == 1
      assert length(result.vout) == 2
    end

    test "call with blockhash parameter", %{client: client} do
      tx_result = get_raw_transaction_preset(:standard)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getrawtransaction",
                   "params" => [@valid_txid, true, @valid_blockhash],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => tx_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetRawTransactionResult{}} =
               RawTransactions.get_raw_transaction(client,
                 txid: @valid_txid,
                 verbose: true,
                 blockhash: @valid_blockhash
               )
    end

    test "handles transaction not found error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -5,
                "message" => "No such mempool or blockchain transaction"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -5}} =
               RawTransactions.get_raw_transaction(client, txid: @valid_txid)
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node with transactions
      real_client = new_client()

      # Get the best block hash first
      assert {:ok, blockchain_info} = Blockchain.get_blockchain_info(real_client, retries: 10)
      blockhash = blockchain_info.bestblockhash

      # Get the first transaction from the block
      {:ok, %{tx: [txid | _]}} =
        Blockchain.get_block(real_client, [blockhash: blockhash], retries: 10)

      # Test hex format (verbose=false)
      assert {:ok, hex_string} =
               RawTransactions.get_raw_transaction(
                 real_client,
                 [txid: txid, verbose: false],
                 retries: 10
               )

      assert is_binary(hex_string)
      assert String.match?(hex_string, ~r/^[a-fA-F0-9]+$/)

      # Test verbose format (verbose=true)
      assert {:ok, %GetRawTransactionResult{} = result} =
               RawTransactions.get_raw_transaction(
                 real_client,
                 [txid: txid, verbose: true],
                 retries: 10
               )

      assert result.txid == txid
      assert is_list(result.vin)
      assert is_list(result.vout)
      assert is_integer(result.size)
      assert result.size > 0
    end
  end

  describe "(RPC) RawTransactions.get_raw_transaction!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns hex string on success", %{client: client} do
      hex_result = get_raw_transaction_hex_fixture()

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => hex_result,
              "error" => nil
            }
          }
      end)

      assert ^hex_result =
               RawTransactions.get_raw_transaction!(client, txid: @valid_txid)
    end

    test "returns structured object when verbose=true", %{client: client} do
      tx_result = get_raw_transaction_preset(:standard)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => tx_result,
              "error" => nil
            }
          }
      end)

      assert %GetRawTransactionResult{} =
               result =
               RawTransactions.get_raw_transaction!(client, txid: @valid_txid, verbose: true)

      assert result.txid == "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
      assert length(result.vin) == 1
      assert length(result.vout) == 2
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        RawTransactions.get_raw_transaction!(client, txid: @valid_txid)
      end
    end
  end
end
