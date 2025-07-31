defmodule BTx.RPC.RawTransactions.CreateRawTransactionTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Blockchain, Encodable, RawTransactions, Request, Wallets}
  alias BTx.RPC.RawTransactions.CreateRawTransaction
  alias BTx.RPC.RawTransactions.RawTransaction.{Input, Output, Output.Address}
  alias Ecto.Changeset

  @url "http://localhost:18443/"
  @valid_txid "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  @valid_address "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"

  ## Input schema tests

  describe "Input changeset/2" do
    test "validates valid input data" do
      attrs = %{
        "txid" => @valid_txid,
        "vout" => 0,
        "sequence" => 4_294_967_295
      }

      changeset = Input.changeset(%Input{}, attrs)
      assert changeset.valid?

      input = Changeset.apply_changes(changeset)
      assert input.txid == @valid_txid
      assert input.vout == 0
      assert input.sequence == 4_294_967_295
    end

    test "validates required fields" do
      changeset = Input.changeset(%Input{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).txid
      assert "can't be blank" in errors_on(changeset).vout
    end

    test "validates txid format" do
      attrs = %{"txid" => "invalid", "vout" => 0}
      changeset = Input.changeset(%Input{}, attrs)
      refute changeset.valid?
      assert "has invalid format" in errors_on(changeset).txid
      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "validates vout is non-negative" do
      attrs = %{"txid" => @valid_txid, "vout" => -1}
      changeset = Input.changeset(%Input{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).vout
    end

    test "validates sequence is non-negative when provided" do
      attrs = %{"txid" => @valid_txid, "vout" => 0, "sequence" => -1}
      changeset = Input.changeset(%Input{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).sequence
    end

    test "accepts optional sequence field" do
      attrs = %{"txid" => @valid_txid, "vout" => 0}
      changeset = Input.changeset(%Input{}, attrs)
      assert changeset.valid?
    end
  end

  ## Output.Address schema tests

  describe "Output.Address changeset/2" do
    test "validates valid address output" do
      attrs = %{
        "address" => @valid_address,
        "amount" => 1.5
      }

      changeset = Address.changeset(%Address{}, attrs)
      assert changeset.valid?

      address_output = Changeset.apply_changes(changeset)
      assert address_output.address == @valid_address
      assert address_output.amount == 1.5
    end

    test "validates required fields" do
      changeset = Address.changeset(%Address{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).address
      assert "can't be blank" in errors_on(changeset).amount
    end

    test "validates address format" do
      attrs = %{"address" => "invalid", "amount" => 1.0}
      changeset = Address.changeset(%Address{}, attrs)
      refute changeset.valid?
      assert changeset.errors[:address] != nil
    end

    test "validates amount is positive" do
      attrs = %{"address" => @valid_address, "amount" => 0}
      changeset = Address.changeset(%Address{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).amount

      attrs = %{"address" => @valid_address, "amount" => -1.0}
      changeset = Address.changeset(%Address{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).amount
    end
  end

  ## Output schema tests

  describe "Output changeset/2" do
    test "validates valid output with addresses" do
      attrs = %{
        "addresses" => [
          %{"address" => @valid_address, "amount" => 1.0}
        ]
      }

      changeset = Output.changeset(%Output{}, attrs)
      assert changeset.valid?

      output = Changeset.apply_changes(changeset)
      assert length(output.addresses) == 1
      assert hd(output.addresses).address == @valid_address
      assert hd(output.addresses).amount == 1.0
    end

    test "validates valid output with data" do
      attrs = %{
        "data" => "deadbeef"
      }

      changeset = Output.changeset(%Output{}, attrs)
      assert changeset.valid?

      output = Changeset.apply_changes(changeset)
      assert output.data == "deadbeef"
    end

    test "validates data is valid hex string" do
      attrs = %{"data" => "invalid hex"}
      changeset = Output.changeset(%Output{}, attrs)
      refute changeset.valid?
      assert "must be a valid hex string" in errors_on(changeset).data
    end

    test "accepts valid hex strings for data" do
      valid_hex_strings = ["deadbeef", "00112233", "ABCDEF", "0123456789abcdef"]

      for hex <- valid_hex_strings do
        attrs = %{"data" => hex}
        changeset = Output.changeset(%Output{}, attrs)
        assert changeset.valid?, "#{hex} should be valid"
      end
    end

    test "validates addresses and data can coexist" do
      attrs = %{
        "addresses" => [
          %{"address" => @valid_address, "amount" => 1.0}
        ],
        "data" => "deadbeef"
      }

      changeset = Output.changeset(%Output{}, attrs)
      assert changeset.valid?
    end
  end

  ## CreateRawTransaction schema tests

  describe "CreateRawTransaction.new/1" do
    test "creates a new CreateRawTransaction with address output" do
      attrs = %{
        inputs: [%{txid: @valid_txid, vout: 0}],
        outputs: %{
          addresses: [%{address: @valid_address, amount: 1.0}]
        }
      }

      assert {:ok, %CreateRawTransaction{} = request} = CreateRawTransaction.new(attrs)

      assert length(request.inputs) == 1
      assert request.outputs.addresses != nil
      assert length(request.outputs.addresses) == 1
      assert request.locktime == 0
      assert request.replaceable == false
    end

    test "creates a new CreateRawTransaction with data output" do
      attrs = %{
        inputs: [%{txid: @valid_txid, vout: 0}],
        outputs: %{
          data: "deadbeef"
        }
      }

      assert {:ok, %CreateRawTransaction{} = request} = CreateRawTransaction.new(attrs)

      assert length(request.inputs) == 1
      assert request.outputs.data == "deadbeef"
      assert request.locktime == 0
      assert request.replaceable == false
    end

    test "creates a new CreateRawTransaction with all fields" do
      attrs = %{
        inputs: [%{txid: @valid_txid, vout: 0, sequence: 1000}],
        outputs: %{
          addresses: [%{address: @valid_address, amount: 1.0}]
        },
        locktime: 500_000,
        replaceable: true
      }

      assert {:ok, %CreateRawTransaction{} = request} = CreateRawTransaction.new(attrs)

      assert length(request.inputs) == 1
      assert request.outputs.addresses != nil
      assert request.locktime == 500_000
      assert request.replaceable == true
    end

    test "validates required inputs field" do
      attrs = %{
        outputs: %{
          addresses: [%{address: @valid_address, amount: 1.0}]
        }
      }

      assert {:error, %Changeset{} = changeset} = CreateRawTransaction.new(attrs)
      assert "can't be blank" in errors_on(changeset).inputs
    end

    test "validates required outputs field" do
      attrs = %{
        inputs: [%{txid: @valid_txid, vout: 0}]
      }

      assert {:error, %Changeset{} = changeset} = CreateRawTransaction.new(attrs)
      assert "can't be blank" in errors_on(changeset).outputs
    end

    test "validates locktime is non-negative" do
      attrs = %{
        inputs: [%{txid: @valid_txid, vout: 0}],
        outputs: %{
          addresses: [%{address: @valid_address, amount: 1.0}]
        },
        locktime: -1
      }

      assert {:error, %Changeset{} = changeset} = CreateRawTransaction.new(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).locktime
    end
  end

  describe "CreateRawTransaction.new!/1" do
    test "creates a new CreateRawTransaction with valid params" do
      attrs = %{
        inputs: [%{txid: @valid_txid, vout: 0}],
        outputs: %{
          addresses: [%{address: @valid_address, amount: 1.0}]
        }
      }

      assert %CreateRawTransaction{} = CreateRawTransaction.new!(attrs)
    end

    test "raises error for invalid params" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        CreateRawTransaction.new!(%{inputs: [], outputs: %{}})
      end
    end
  end

  describe "CreateRawTransaction encodable" do
    test "encodes method with address output" do
      attrs = %{
        inputs: [%{txid: @valid_txid, vout: 0}],
        outputs: %{
          addresses: [%{address: @valid_address, amount: 1.0}]
        }
      }

      request = CreateRawTransaction.new!(attrs)
      encoded = Encodable.encode(request)

      assert %Request{
               params: [
                 [%{"txid" => @valid_txid, "vout" => 0}],
                 [%{@valid_address => 1.0}],
                 0,
                 false
               ],
               method: "createrawtransaction",
               jsonrpc: "1.0",
               path: "/"
             } = encoded
    end

    test "encodes method with data output" do
      attrs = %{
        inputs: [%{txid: @valid_txid, vout: 0}],
        outputs: %{
          data: "deadbeef"
        },
        locktime: 500_000,
        replaceable: true
      }

      request = CreateRawTransaction.new!(attrs)
      encoded = Encodable.encode(request)

      assert %Request{
               params: [
                 [%{"txid" => @valid_txid, "vout" => 0}],
                 [%{"data" => "deadbeef"}],
                 500_000,
                 true
               ],
               method: "createrawtransaction",
               jsonrpc: "1.0",
               path: "/"
             } = encoded
    end

    test "encodes method with sequence in input" do
      attrs = %{
        inputs: [%{txid: @valid_txid, vout: 0, sequence: 1000}],
        outputs: %{
          addresses: [%{address: @valid_address, amount: 1.0}]
        }
      }

      request = CreateRawTransaction.new!(attrs)
      encoded = Encodable.encode(request)

      assert %Request{
               params: [
                 [%{"txid" => @valid_txid, "vout" => 0, "sequence" => 1000}],
                 [%{@valid_address => 1.0}],
                 0,
                 false
               ]
             } = encoded
    end
  end

  ## RawTransactions RPC tests

  describe "(RPC) RawTransactions.create_raw_transaction/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns hex string", %{client: client} do
      # Mock hex transaction
      hex_result = "0200000001" <> String.duplicate("00", 100)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)

          assert %{
                   "method" => "createrawtransaction",
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = decoded_body

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
               RawTransactions.create_raw_transaction(client,
                 inputs: [%{txid: @valid_txid, vout: 0}],
                 outputs: %{
                   addresses: [%{address: @valid_address, amount: 1.0}]
                 }
               )
    end

    test "successful call with data output", %{client: client} do
      # Mock hex transaction
      hex_result = "0200000001" <> String.duplicate("ff", 50)

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

      assert {:ok, ^hex_result} =
               RawTransactions.create_raw_transaction(client,
                 inputs: [%{txid: @valid_txid, vout: 0}],
                 outputs: %{
                   data: "deadbeef"
                 }
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
                "code" => -8,
                "message" => "Invalid parameter"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -8, message: "Invalid parameter"}} =
               RawTransactions.create_raw_transaction(client,
                 inputs: [%{txid: @valid_txid, vout: 0}],
                 outputs: %{
                   addresses: [%{address: @valid_address, amount: 1.0}]
                 }
               )
    end

    test "handles validation error for invalid inputs", %{client: client} do
      assert {:error, %Changeset{}} =
               RawTransactions.create_raw_transaction(client,
                 inputs: [],
                 outputs: %{
                   addresses: [%{address: @valid_address, amount: 1.0}]
                 }
               )
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node with transactions
      real_client = new_client()

      # Get the best block hash first
      assert {:ok, blockchain_info} = Blockchain.get_blockchain_info(real_client, retries: 10)
      blockhash = blockchain_info.bestblockhash

      # Get the first transaction from the block to use as input
      {:ok, %{tx: [txid | _]}} =
        Blockchain.get_block(real_client, [blockhash: blockhash], retries: 10)

      # Get a new address to use as output
      wallet_name = "btx-shared-test-wallet"
      {:ok, address} = Wallets.get_new_address(real_client, [wallet_name: wallet_name], retries: 10)

      # Use the first output as input for our new transaction
      vout = 0

      # Create a simple transaction with one input and one address output
      assert {:ok, hex_result} =
               RawTransactions.create_raw_transaction(
                 real_client,
                 [
                   inputs: [%{txid: txid, vout: vout}],
                   outputs: %{
                     addresses: [%{address: address, amount: 0.001}]
                   }
                 ],
                 retries: 10
               )

      # Verify we got a hex string back
      assert is_binary(hex_result)
      assert String.match?(hex_result, ~r/^[a-fA-F0-9]+$/)
      assert String.length(hex_result) > 0

      # Test creating transaction with data output
      assert {:ok, data_hex_result} =
               RawTransactions.create_raw_transaction(
                 real_client,
                 [
                   inputs: [%{txid: txid, vout: vout}],
                   outputs: %{
                     data: "deadbeef"
                   }
                 ],
                 retries: 10
               )

      assert is_binary(data_hex_result)
      assert String.match?(data_hex_result, ~r/^[a-fA-F0-9]+$/)

      # Test with locktime and replaceable
      assert {:ok, locktime_hex_result} =
               RawTransactions.create_raw_transaction(
                 real_client,
                 [
                   inputs: [%{txid: txid, vout: vout, sequence: 1000}],
                   outputs: %{
                     addresses: [%{address: address, amount: 0.001}]
                   },
                   locktime: 500_000,
                   replaceable: true
                 ],
                 retries: 10
               )

      assert is_binary(locktime_hex_result)
      assert String.match?(locktime_hex_result, ~r/^[a-fA-F0-9]+$/)

      # Test with mixed outputs (both address and data)
      assert {:ok, mixed_hex_result} =
               RawTransactions.create_raw_transaction(
                 real_client,
                 [
                   inputs: [%{txid: txid, vout: vout}],
                   outputs: %{
                     addresses: [%{address: address, amount: 0.001}],
                     data: "cafebabe"
                   }
                 ],
                 retries: 10
               )

      assert is_binary(mixed_hex_result)
      assert String.match?(mixed_hex_result, ~r/^[a-fA-F0-9]+$/)
    end
  end

  describe "(RPC) RawTransactions.create_raw_transaction!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns hex string", %{client: client} do
      # Mock hex transaction
      hex_result = "0200000001" <> String.duplicate("cc", 60)

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
               RawTransactions.create_raw_transaction!(client,
                 inputs: [%{txid: @valid_txid, vout: 0}],
                 outputs: %{
                   addresses: [%{address: @valid_address, amount: 1.0}]
                 }
               )
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        RawTransactions.create_raw_transaction!(client,
          inputs: [%{txid: @valid_txid, vout: 0}],
          outputs: %{
            addresses: [%{address: @valid_address, amount: 1.0}]
          }
        )
      end
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        RawTransactions.create_raw_transaction!(client,
          inputs: [],
          outputs: %{
            addresses: [%{address: @valid_address, amount: 1.0}]
          }
        )
      end
    end
  end
end
