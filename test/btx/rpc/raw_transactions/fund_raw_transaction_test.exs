defmodule BTx.RPC.RawTransactions.FundRawTransactionTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.RawTransactionsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, RawTransactions, Request, Wallets}
  alias BTx.RPC.RawTransactions.{FundRawTransaction, FundRawTransactionResult}
  alias BTx.RPC.RawTransactions.FundRawTransaction.Options
  alias Ecto.Changeset

  @valid_hex "0200000000010100e1f50500000000160014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2600000000"

  @url "http://localhost:18443/"

  ## FundRawTransaction.Options schema tests

  describe "FundRawTransaction.Options changeset/2" do
    test "accepts valid options" do
      attrs = fund_raw_transaction_options_fixture()
      changeset = Options.changeset(%Options{}, attrs)
      assert changeset.valid?
    end

    test "validates change_type inclusion" do
      # Valid change types
      valid_types = ~w(legacy p2sh-segwit bech32)

      for change_type <- valid_types do
        attrs = fund_raw_transaction_options_fixture(%{"change_type" => change_type})
        changeset = Options.changeset(%Options{}, attrs)
        assert changeset.valid?, "#{change_type} should be valid"
      end

      # Invalid change type
      attrs = fund_raw_transaction_options_fixture(%{"change_type" => "invalid"})
      changeset = Options.changeset(%Options{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).change_type
    end

    test "validates estimate_mode inclusion" do
      # Valid estimate modes
      valid_modes = ~w(unset economical conservative)

      for mode <- valid_modes do
        attrs = fund_raw_transaction_options_fixture(%{"estimate_mode" => mode})
        changeset = Options.changeset(%Options{}, attrs)
        assert changeset.valid?, "#{mode} should be valid"
      end

      # Invalid estimate mode
      attrs = fund_raw_transaction_options_fixture(%{"estimate_mode" => "invalid"})
      changeset = Options.changeset(%Options{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).estimate_mode
    end

    test "validates fee rates are positive" do
      attrs = fund_raw_transaction_options_fixture()

      # Valid positive fee rates
      attrs = Map.put(attrs, "fee_rate", 25.0)
      changeset = Options.changeset(%Options{}, attrs)
      assert changeset.valid?

      attrs = attrs |> Map.delete("fee_rate") |> Map.put("fee_rate_btc", 0.00010000)
      changeset = Options.changeset(%Options{}, attrs)
      assert changeset.valid?

      # Invalid zero/negative fee rates
      attrs = Map.put(attrs, "fee_rate", 0)
      changeset = Options.changeset(%Options{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).fee_rate

      attrs = Map.put(attrs, "fee_rate", -1.0)
      changeset = Options.changeset(%Options{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).fee_rate
    end

    test "validates exclusive fee rates" do
      # Cannot specify both fee_rate and fee_rate_btc
      attrs =
        fund_raw_transaction_options_fixture(%{
          "fee_rate" => 25.0,
          "fee_rate_btc" => 0.00010000
        })

      changeset = Options.changeset(%Options{}, attrs)
      refute changeset.valid?
      assert "cannot specify both fee_rate and fee_rate_btc" in errors_on(changeset).fee_rate
    end

    test "validates change_position is non-negative" do
      # Valid positions
      for pos <- [0, 1, 5, 10] do
        attrs = fund_raw_transaction_options_fixture(%{"change_position" => pos})
        changeset = Options.changeset(%Options{}, attrs)
        assert changeset.valid?, "#{pos} should be valid"
      end

      # Invalid negative position
      attrs = fund_raw_transaction_options_fixture(%{"change_position" => -2})
      changeset = Options.changeset(%Options{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).change_position
    end

    test "validates subtract_fee_from_outputs indices" do
      # Valid output indices
      attrs = fund_raw_transaction_options_fixture(%{"subtract_fee_from_outputs" => [0, 1, 2]})
      changeset = Options.changeset(%Options{}, attrs)
      assert changeset.valid?

      # Invalid negative indices
      attrs = fund_raw_transaction_options_fixture(%{"subtract_fee_from_outputs" => [0, -1, 2]})
      changeset = Options.changeset(%Options{}, attrs)
      refute changeset.valid?

      assert "all output indices must be non-negative" in errors_on(changeset).subtract_fee_from_outputs
    end

    test "validates conf_target is positive" do
      # Valid conf_target
      attrs = fund_raw_transaction_options_fixture(%{"conf_target" => 6})
      changeset = Options.changeset(%Options{}, attrs)
      assert changeset.valid?

      # Invalid zero/negative conf_target
      attrs = fund_raw_transaction_options_fixture(%{"conf_target" => 0})
      changeset = Options.changeset(%Options{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).conf_target
    end

    test "validates change_address format" do
      valid_addresses = [
        "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
        "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
        "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
      ]

      for address <- valid_addresses do
        attrs = fund_raw_transaction_options_fixture(%{"change_address" => address})
        changeset = Options.changeset(%Options{}, attrs)
        assert changeset.valid?, "#{address} should be valid"
      end

      # Invalid address
      attrs = fund_raw_transaction_options_fixture(%{"change_address" => "invalid_address"})
      changeset = Options.changeset(%Options{}, attrs)
      refute changeset.valid?
    end

    test "uses default values" do
      changeset = Options.changeset(%Options{}, %{})
      assert changeset.valid?

      output = Changeset.apply_changes(changeset)
      assert output.add_inputs == true
      assert output.lock_unspents == false
      assert output.subtract_fee_from_outputs == []
    end
  end

  describe "FundRawTransaction.Options to_map/1" do
    test "converts options to correct JSON format" do
      options = %Options{
        add_inputs: true,
        change_address: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
        change_position: 1,
        change_type: "bech32",
        include_watching: false,
        lock_unspents: true,
        fee_rate: 25.0,
        subtract_fee_from_outputs: [0, 1],
        replaceable: true,
        conf_target: 6,
        estimate_mode: "economical"
      }

      result = Options.to_map(options)

      # Verify field name mappings
      assert result["add_inputs"] == true
      assert result["changeAddress"] == "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      assert result["changePosition"] == 1
      assert result["change_type"] == "bech32"
      assert result["includeWatching"] == false
      assert result["lockUnspents"] == true
      assert result["fee_rate"] == 25.0
      assert result["subtractFeeFromOutputs"] == [0, 1]
      assert result["replaceable"] == true
      assert result["conf_target"] == 6
      assert result["estimate_mode"] == "economical"
    end

    test "maps fee_rate_btc to feeRate" do
      options = %Options{fee_rate_btc: 0.00010000}
      result = Options.to_map(options)

      assert result["feeRate"] == 0.00010000
      refute Map.has_key?(result, "fee_rate_btc")
    end

    test "filters out nil values" do
      options = %Options{
        add_inputs: true,
        change_address: nil,
        fee_rate: 25.0
      }

      result = Options.to_map(options)

      assert Map.has_key?(result, "add_inputs")
      assert Map.has_key?(result, "fee_rate")
      refute Map.has_key?(result, "changeAddress")
    end
  end

  ## FundRawTransaction schema tests

  describe "FundRawTransaction.new/1" do
    test "creates a new FundRawTransaction with required fields" do
      assert {:ok, %FundRawTransaction{} = request} =
               FundRawTransaction.new(hexstring: @valid_hex)

      assert request.hexstring == @valid_hex
      assert request.method == "fundrawtransaction"
      assert is_nil(request.options)
      assert is_nil(request.iswitness)
    end

    test "creates a new FundRawTransaction with all parameters" do
      assert {:ok, %FundRawTransaction{} = request} =
               FundRawTransaction.new(
                 hexstring: @valid_hex,
                 options: %{
                   fee_rate: 25.0,
                   change_type: "bech32"
                 },
                 iswitness: true
               )

      assert request.hexstring == @valid_hex
      assert request.options.fee_rate == 25.0
      assert request.options.change_type == "bech32"
      assert request.iswitness == true
    end

    test "returns error for missing hexstring" do
      assert {:error, %Changeset{errors: errors}} = FundRawTransaction.new(%{})

      assert Keyword.fetch!(errors, :hexstring) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for empty hexstring" do
      assert {:error, %Changeset{errors: errors}} =
               FundRawTransaction.new(hexstring: "")

      assert Keyword.fetch!(errors, :hexstring) ==
               {"can't be blank", [validation: :required]}
    end

    test "returns error for invalid hexstring" do
      assert {:error, %Changeset{} = changeset} =
               FundRawTransaction.new(hexstring: "invalid_hex!")

      assert "must be a valid hex string" in errors_on(changeset).hexstring
    end

    test "validates embedded options" do
      # Valid options
      assert {:ok, %FundRawTransaction{}} =
               FundRawTransaction.new(
                 hexstring: @valid_hex,
                 options: %{fee_rate: 25.0}
               )

      # Invalid options
      assert {:error, %Changeset{} = changeset} =
               FundRawTransaction.new(
                 hexstring: @valid_hex,
                 options: %{fee_rate: -1.0}
               )

      refute changeset.valid?
    end

    test "accepts keyword list params" do
      assert {:ok, %FundRawTransaction{} = request} =
               FundRawTransaction.new(
                 hexstring: @valid_hex,
                 options: %{fee_rate: 25.0},
                 iswitness: false
               )

      assert request.hexstring == @valid_hex
      assert request.options.fee_rate == 25.0
      assert request.iswitness == false
    end
  end

  describe "FundRawTransaction.new!/1" do
    test "creates a new FundRawTransaction with valid data" do
      assert %FundRawTransaction{} =
               FundRawTransaction.new!(hexstring: @valid_hex)
    end

    test "raises error for invalid data" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        FundRawTransaction.new!(hexstring: "invalid_hex!")
      end
    end
  end

  describe "FundRawTransaction encodable" do
    test "encodes minimal request correctly" do
      request = FundRawTransaction.new!(hexstring: @valid_hex)

      assert %Request{
               method: "fundrawtransaction",
               path: "/",
               params: [@valid_hex]
             } = Encodable.encode(request)
    end

    test "encodes request with options" do
      request =
        FundRawTransaction.new!(
          hexstring: @valid_hex,
          options: %{
            fee_rate: 25.0,
            change_type: "bech32",
            lock_unspents: true
          }
        )

      encoded = Encodable.encode(request)

      assert encoded.method == "fundrawtransaction"
      assert encoded.path == "/"
      assert [_hex, options_map] = encoded.params

      assert options_map["fee_rate"] == 25.0
      assert options_map["change_type"] == "bech32"
      assert options_map["lockUnspents"] == true
    end

    test "encodes request with iswitness flag" do
      request =
        FundRawTransaction.new!(
          hexstring: @valid_hex,
          options: %{fee_rate: 25.0},
          iswitness: true
        )

      encoded = Encodable.encode(request)

      assert [_hex, _options, true] = encoded.params
    end

    test "trims trailing nil params" do
      request = FundRawTransaction.new!(hexstring: @valid_hex, iswitness: nil)

      encoded = Encodable.encode(request)

      # Should not include trailing nil
      assert encoded.params == [@valid_hex]
    end

    test "encodes with legacy fee rate" do
      request =
        FundRawTransaction.new!(
          hexstring: @valid_hex,
          options: %{fee_rate_btc: 0.00010000}
        )

      encoded = Encodable.encode(request)
      [_hex, options_map] = encoded.params

      # Should map fee_rate_btc to feeRate
      assert options_map["feeRate"] == 0.00010000
      refute Map.has_key?(options_map, "fee_rate_btc")
    end
  end

  ## FundRawTransactionResult schema tests

  describe "FundRawTransactionResult.new/1" do
    test "creates result with valid data" do
      attrs = fund_raw_transaction_result_fixture()

      assert {:ok, %FundRawTransactionResult{} = result} =
               FundRawTransactionResult.new(attrs)

      assert result.hex == attrs["hex"]
      assert result.fee == attrs["fee"]
      assert result.changepos == attrs["changepos"]
    end

    test "creates result with no change output" do
      attrs =
        fund_raw_transaction_result_fixture(%{
          "changepos" => -1,
          "fee" => 0.00002500
        })

      assert {:ok, %FundRawTransactionResult{} = result} =
               FundRawTransactionResult.new(attrs)

      assert result.changepos == -1
      assert result.fee == 0.00002500
    end

    test "validates hex field format" do
      attrs = %{"hex" => "invalid_hex_string!"}

      assert {:error, %Changeset{} = changeset} =
               FundRawTransactionResult.new(attrs)

      assert "must be a valid hex string" in errors_on(changeset).hex
    end

    test "validates fee is non-negative" do
      attrs = fund_raw_transaction_result_fixture(%{"fee" => -0.001})

      assert {:error, %Changeset{} = changeset} =
               FundRawTransactionResult.new(attrs)

      assert "must be greater than or equal to 0" in errors_on(changeset).fee
    end

    test "validates changepos bounds" do
      # Valid changepos values
      for pos <- [-1, 0, 1, 5] do
        attrs = fund_raw_transaction_result_fixture(%{"changepos" => pos})

        assert {:ok, %FundRawTransactionResult{changepos: ^pos}} =
                 FundRawTransactionResult.new(attrs)
      end

      # Invalid changepos
      attrs = fund_raw_transaction_result_fixture(%{"changepos" => -2})

      assert {:error, %Changeset{} = changeset} =
               FundRawTransactionResult.new(attrs)

      assert "must be -1 (no change) or a non-negative integer" in errors_on(changeset).changepos
    end

    test "handles minimal result data" do
      attrs = %{"hex" => @valid_hex}

      assert {:ok, %FundRawTransactionResult{} = result} =
               FundRawTransactionResult.new(attrs)

      assert result.hex == @valid_hex
      assert is_nil(result.fee)
      assert is_nil(result.changepos)
    end
  end

  describe "FundRawTransactionResult.new!/1" do
    test "creates result with valid data" do
      attrs = fund_raw_transaction_result_fixture()

      assert %FundRawTransactionResult{} = FundRawTransactionResult.new!(attrs)
    end

    test "raises error for invalid data" do
      attrs = %{"hex" => "invalid_hex!"}

      assert_raise Ecto.InvalidChangesetError, fn ->
        FundRawTransactionResult.new!(attrs)
      end
    end
  end

  ## FundRawTransaction RPC

  describe "(RPC) RawTransactions.fund_raw_transaction/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "calls fundrawtransaction RPC method", %{client: client} do
      result_fixture = fund_raw_transaction_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "fundrawtransaction",
                   "params" => [@valid_hex],
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

      assert {:ok, %FundRawTransactionResult{} = result} =
               RawTransactions.fund_raw_transaction(client, hexstring: @valid_hex)

      assert result.hex == result_fixture["hex"]
      assert result.fee == result_fixture["fee"]
      assert result.changepos == result_fixture["changepos"]
    end

    test "funds transaction with custom options", %{client: client} do
      result_fixture = fund_raw_transaction_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)

          assert %{
                   "method" => "fundrawtransaction",
                   "params" => [_hex, options_map],
                   "jsonrpc" => "1.0"
                 } = decoded_body

          # Verify options are encoded correctly
          assert options_map["fee_rate"] == 50.0
          assert options_map["change_type"] == "bech32"
          assert options_map["lockUnspents"] == true

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %FundRawTransactionResult{}} =
               RawTransactions.fund_raw_transaction(client,
                 hexstring: @valid_hex,
                 options: %{
                   fee_rate: 50.0,
                   change_type: "bech32",
                   lock_unspents: true
                 }
               )
    end

    test "funds transaction with legacy fee rate", %{client: client} do
      result_fixture = fund_raw_transaction_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)
          [_hex, options_map] = decoded_body["params"]

          # Verify legacy fee rate mapping
          assert options_map["feeRate"] == 0.00010000
          refute Map.has_key?(options_map, "fee_rate_btc")

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %FundRawTransactionResult{}} =
               RawTransactions.fund_raw_transaction(client,
                 hexstring: @valid_hex,
                 options: %{fee_rate_btc: 0.00010000}
               )
    end

    test "funds transaction with witness flag", %{client: client} do
      result_fixture = fund_raw_transaction_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)

          # Verify iswitness parameter
          assert [_hex, _options, true] = decoded_body["params"]

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %FundRawTransactionResult{}} =
               RawTransactions.fund_raw_transaction(client,
                 hexstring: @valid_hex,
                 options: %{fee_rate: 25.0},
                 iswitness: true
               )
    end

    test "returns error for invalid request", %{client: client} do
      assert {:error, %Ecto.Changeset{}} =
               RawTransactions.fund_raw_transaction(client, hexstring: "invalid_hex!")
    end

    test "returns error for RPC error - insufficient funds", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
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

      assert {:error, %BTx.RPC.MethodError{code: -6, reason: :wallet_insufficient_funds}} =
               RawTransactions.fund_raw_transaction(client, hexstring: @valid_hex)
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        RawTransactions.fund_raw_transaction!(client, hexstring: @valid_hex)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client(retry_opts: [max_retries: 10])

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

        # Fund the transaction
        assert {:ok, %FundRawTransactionResult{} = result} =
                 RawTransactions.fund_raw_transaction(
                   real_client,
                   hexstring: raw_tx,
                   options: %{
                     fee_rate: 1.0,
                     change_type: "bech32"
                   },
                   wallet_name: wallet_name
                 )

        # Verify the result has expected fields
        assert is_binary(result.hex)
        assert is_number(result.fee)
        assert result.fee > 0
        assert is_integer(result.changepos)
        assert result.changepos >= -1

        # The funded transaction should be longer than the original
        assert String.length(result.hex) > String.length(raw_tx)
      end
    end
  end

  describe "(RPC) RawTransactions.fund_raw_transaction!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns result on success", %{client: client} do
      result_fixture = fund_raw_transaction_result_fixture()

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

      assert %FundRawTransactionResult{} =
               RawTransactions.fund_raw_transaction!(client, hexstring: @valid_hex)
    end

    test "raises error for invalid request", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        RawTransactions.fund_raw_transaction!(client, hexstring: "invalid_hex!")
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
                "code" => -6,
                "message" => "Insufficient funds"
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, fn ->
        RawTransactions.fund_raw_transaction!(client, hexstring: @valid_hex)
      end
    end
  end
end
