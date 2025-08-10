defmodule BTx.RPC.RawTransactions.DecodeRawTransactionTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.RawTransactionsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Blockchain, Encodable, RawTransactions, Request}
  alias BTx.RPC.RawTransactions.{DecodeRawTransaction, DecodeRawTransactionResult}
  alias BTx.RPC.RawTransactions.RawTransaction.{Vin, Vout}
  alias Ecto.Changeset

  @url "http://localhost:18443/"
  @valid_hex get_raw_transaction_hex_fixture()

  ## DecodeRawTransaction schema tests

  describe "DecodeRawTransaction.new/1" do
    test "creates a new DecodeRawTransaction with required fields" do
      assert {:ok, %DecodeRawTransaction{} = request} =
               DecodeRawTransaction.new(hexstring: @valid_hex)

      assert request.hexstring == @valid_hex
      assert request.iswitness == nil
    end

    test "creates a new DecodeRawTransaction with all fields" do
      assert {:ok, %DecodeRawTransaction{} = request} =
               DecodeRawTransaction.new(
                 hexstring: @valid_hex,
                 iswitness: true
               )

      assert request.hexstring == @valid_hex
      assert request.iswitness == true
    end

    test "validates required hexstring field" do
      assert {:error, %Changeset{} = changeset} = DecodeRawTransaction.new(%{})
      assert "can't be blank" in errors_on(changeset).hexstring
    end

    test "validates hexstring format" do
      assert {:error, %Changeset{} = changeset} =
               DecodeRawTransaction.new(hexstring: "invalid hex")

      assert "must be a valid hex string" in errors_on(changeset).hexstring
    end

    test "accepts valid hex string" do
      assert {:ok, %DecodeRawTransaction{}} =
               DecodeRawTransaction.new(hexstring: "deadbeef")
    end

    test "accepts empty hexstring" do
      assert {:error, %Changeset{} = changeset} =
               DecodeRawTransaction.new(hexstring: "$")

      assert "must be a valid hex string" in errors_on(changeset).hexstring
    end
  end

  describe "DecodeRawTransaction.new!/1" do
    test "creates a new DecodeRawTransaction with valid params" do
      assert %DecodeRawTransaction{} =
               DecodeRawTransaction.new!(hexstring: @valid_hex, iswitness: false)
    end

    test "raises error for invalid params" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        DecodeRawTransaction.new!(hexstring: "invalid hex")
      end
    end
  end

  describe "DecodeRawTransaction encodable" do
    test "encodes method with required fields only" do
      assert %Request{
               params: [@valid_hex],
               method: "decoderawtransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               DecodeRawTransaction.new!(hexstring: @valid_hex)
               |> Encodable.encode()
    end

    test "encodes method with iswitness parameter" do
      assert %Request{
               params: [@valid_hex, true],
               method: "decoderawtransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               DecodeRawTransaction.new!(hexstring: @valid_hex, iswitness: true)
               |> Encodable.encode()
    end

    test "encodes method with iswitness false" do
      assert %Request{
               params: [@valid_hex, false],
               method: "decoderawtransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               DecodeRawTransaction.new!(hexstring: @valid_hex, iswitness: false)
               |> Encodable.encode()
    end
  end

  ## DecodeRawTransactionResult schema tests

  describe "DecodeRawTransactionResult.new/1" do
    test "creates a new DecodeRawTransactionResult with valid data" do
      attrs = decode_raw_transaction_result_fixture()

      assert {:ok, %DecodeRawTransactionResult{} = result} =
               DecodeRawTransactionResult.new(attrs)

      assert result.txid == attrs["txid"]
      assert result.hash == attrs["hash"]
      assert result.size == attrs["size"]
      assert result.vsize == attrs["vsize"]
      assert result.weight == attrs["weight"]
      assert result.version == attrs["version"]
      assert result.locktime == attrs["locktime"]
      assert length(result.vin) == 1
      assert length(result.vout) == 2
    end

    test "validates vin and vout embedded schemas" do
      attrs = decode_raw_transaction_result_fixture()

      assert {:ok, %DecodeRawTransactionResult{} = result} =
               DecodeRawTransactionResult.new(attrs)

      # Verify vin structure
      vin = hd(result.vin)
      assert %Vin{} = vin
      assert vin.txid
      assert vin.vout == 0

      # Verify vout structure
      vout = hd(result.vout)
      assert %Vout{} = vout
      assert vout.value
      assert vout.n == 0
    end

    test "accepts empty vin and vout arrays" do
      attrs =
        decode_raw_transaction_result_fixture(%{
          "vin" => [],
          "vout" => []
        })

      assert {:ok, %DecodeRawTransactionResult{} = result} =
               DecodeRawTransactionResult.new(attrs)

      assert result.vin == []
      assert result.vout == []
    end
  end

  describe "DecodeRawTransactionResult.new!/1" do
    test "creates a new DecodeRawTransactionResult with valid data" do
      attrs = decode_raw_transaction_result_fixture()

      assert %DecodeRawTransactionResult{} = DecodeRawTransactionResult.new!(attrs)
    end

    test "raises error for invalid data" do
      attrs = decode_raw_transaction_result_fixture(%{"size" => -1})

      assert_raise Ecto.InvalidChangesetError, fn ->
        DecodeRawTransactionResult.new!(attrs)
      end
    end
  end

  describe "DecodeRawTransactionResult changeset/2" do
    test "validates numeric fields are non-negative" do
      attrs = decode_raw_transaction_result_fixture()

      # Valid positive values
      changeset = DecodeRawTransactionResult.changeset(%DecodeRawTransactionResult{}, attrs)
      assert changeset.valid?

      # Invalid negative size
      invalid_attrs = Map.put(attrs, "size", -1)
      changeset = DecodeRawTransactionResult.changeset(%DecodeRawTransactionResult{}, invalid_attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).size

      # Invalid negative weight
      invalid_attrs = Map.put(attrs, "weight", -1)
      changeset = DecodeRawTransactionResult.changeset(%DecodeRawTransactionResult{}, invalid_attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).weight

      # Version can be 0
      valid_attrs = Map.put(attrs, "version", 0)
      changeset = DecodeRawTransactionResult.changeset(%DecodeRawTransactionResult{}, valid_attrs)
      assert changeset.valid?

      # Locktime can be 0
      valid_attrs = Map.put(attrs, "locktime", 0)
      changeset = DecodeRawTransactionResult.changeset(%DecodeRawTransactionResult{}, valid_attrs)
      assert changeset.valid?
    end

    test "accepts minimal valid data" do
      attrs = %{
        "vin" => [],
        "vout" => []
      }

      changeset = DecodeRawTransactionResult.changeset(%DecodeRawTransactionResult{}, attrs)
      assert changeset.valid?
    end
  end

  ## RawTransactions RPC tests

  describe "(RPC) RawTransactions.decode_raw_transaction/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns decoded transaction", %{client: client} do
      response_data = decode_raw_transaction_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "decoderawtransaction",
                   "params" => [@valid_hex],
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

      assert {:ok, %DecodeRawTransactionResult{} = result} =
               RawTransactions.decode_raw_transaction(client, hexstring: @valid_hex)

      assert result.txid == response_data["txid"]
      assert result.hash == response_data["hash"]
      assert result.size == response_data["size"]
      assert length(result.vin) == 1
      assert length(result.vout) == 2
    end

    test "successful call with iswitness parameter", %{client: client} do
      response_data = decode_raw_transaction_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "decoderawtransaction",
                   "params" => [@valid_hex, true],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => response_data,
              "error" => nil
            }
          }
      end)

      assert {:ok, %DecodeRawTransactionResult{}} =
               RawTransactions.decode_raw_transaction(client,
                 hexstring: @valid_hex,
                 iswitness: true
               )
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
                "code" => -22,
                "message" => "TX decode failed"
              }
            }
          }
      end)

      assert {:error,
              %BTx.RPC.MethodError{
                code: -22,
                message: "TX decode failed",
                reason: :deserialization_error
              }} =
               RawTransactions.decode_raw_transaction(client, hexstring: @valid_hex)
    end

    test "handles validation error for invalid hexstring", %{client: client} do
      assert {:error, %Changeset{}} =
               RawTransactions.decode_raw_transaction(client, hexstring: "invalid hex")
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node with transactions
      real_client = new_client(retry_opts: [max_retries: 10, delay: :timer.seconds(1)])

      # Get the best block hash first
      assert {:ok, blockchain_info} = Blockchain.get_blockchain_info(real_client)
      blockhash = blockchain_info.bestblockhash

      # Get the first transaction from the block
      {:ok, %{tx: [txid | _]}} =
        Blockchain.get_block(real_client, blockhash: blockhash)

      # Get the raw transaction hex first
      assert {:ok, hex_string} =
               RawTransactions.get_raw_transaction(
                 real_client,
                 txid: txid,
                 verbose: false
               )

      assert is_binary(hex_string)
      assert String.match?(hex_string, ~r/^[a-fA-F0-9]+$/)

      # Test decoding the raw transaction
      assert {:ok, %DecodeRawTransactionResult{} = result} =
               RawTransactions.decode_raw_transaction(
                 real_client,
                 hexstring: hex_string
               )

      # Verify the decoded transaction matches the original
      assert result.txid == txid
      assert is_list(result.vin)
      assert is_list(result.vout)
      assert is_integer(result.size)
      assert result.size > 0
      assert is_integer(result.vsize)
      assert result.vsize > 0
      assert is_integer(result.weight)
      assert result.weight > 0
      assert is_integer(result.version)
      assert is_integer(result.locktime)

      # Test with witness flag
      assert {:ok, %DecodeRawTransactionResult{} = witness_result} =
               RawTransactions.decode_raw_transaction(
                 real_client,
                 hexstring: hex_string,
                 iswitness: true
               )

      # Should decode to the same transaction
      assert witness_result.txid == txid
      assert witness_result.size == result.size
    end
  end

  describe "(RPC) RawTransactions.decode_raw_transaction!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns decoded transaction", %{client: client} do
      response_data = decode_raw_transaction_result_fixture()

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

      assert %DecodeRawTransactionResult{} =
               result =
               RawTransactions.decode_raw_transaction!(client, hexstring: @valid_hex)

      assert result.txid == response_data["txid"]
      assert result.hash == response_data["hash"]
      assert result.size == response_data["size"]
      assert length(result.vin) == 1
      assert length(result.vout) == 2
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        RawTransactions.decode_raw_transaction!(client, hexstring: @valid_hex)
      end
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        RawTransactions.decode_raw_transaction!(client, hexstring: "invalid hex")
      end
    end
  end
end
