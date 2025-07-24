defmodule BTx.JRPC.Blockchain.GetMempoolEntryTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.BlockchainFixtures
  import Tesla.Mock

  alias BTx.JRPC.{Blockchain, Encodable, Request, Wallets}
  alias BTx.JRPC.Blockchain.{GetMempoolEntry, GetMempoolEntryResult}
  alias Ecto.Changeset

  # Valid Bitcoin transaction ID for testing
  @valid_txid "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  @invalid_txid_short "1234567890abcdef"
  @invalid_txid_long "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123"

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a new GetMempoolEntry with valid txid" do
      assert {:ok, %GetMempoolEntry{txid: @valid_txid}} =
               GetMempoolEntry.new(txid: @valid_txid)
    end

    test "returns error for missing txid" do
      assert {:error, %Changeset{errors: errors}} = GetMempoolEntry.new(%{})

      assert Keyword.fetch!(errors, :txid) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for invalid txid length" do
      assert {:error, %Changeset{} = changeset} =
               GetMempoolEntry.new(txid: @invalid_txid_short)

      assert "should be 64 character(s)" in errors_on(changeset).txid

      assert {:error, %Changeset{} = changeset} =
               GetMempoolEntry.new(txid: @invalid_txid_long)

      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "returns error for invalid txid format" do
      invalid_txid = "invalid_characters_not_hex_" <> String.duplicate("z", 32)

      assert {:error, %Changeset{} = changeset} =
               GetMempoolEntry.new(txid: invalid_txid)

      assert "has invalid format" in errors_on(changeset).txid
    end

    test "returns error for empty txid" do
      assert {:error, %Changeset{errors: errors}} = GetMempoolEntry.new(txid: "")

      assert Keyword.fetch!(errors, :txid) == {"can't be blank", [{:validation, :required}]}
    end
  end

  describe "new!/1" do
    test "creates a new GetMempoolEntry with valid txid" do
      assert %GetMempoolEntry{txid: @valid_txid} = GetMempoolEntry.new!(txid: @valid_txid)
    end

    test "raises error for invalid txid" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetMempoolEntry.new!(txid: @invalid_txid_short)
      end
    end

    test "raises error for missing txid" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetMempoolEntry.new!(%{})
      end
    end
  end

  describe "encodable" do
    test "encodes the request with txid" do
      assert %Request{
               params: [@valid_txid],
               method: "getmempoolentry",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetMempoolEntry.new!(txid: @valid_txid)
               |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = GetMempoolEntry.changeset(%GetMempoolEntry{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).txid
    end

    test "validates txid length and format" do
      # Valid txid
      changeset = GetMempoolEntry.changeset(%GetMempoolEntry{}, %{txid: @valid_txid})
      assert changeset.valid?

      # Too short
      changeset = GetMempoolEntry.changeset(%GetMempoolEntry{}, %{txid: @invalid_txid_short})
      refute changeset.valid?
      assert "should be 64 character(s)" in errors_on(changeset).txid

      # Too long
      changeset = GetMempoolEntry.changeset(%GetMempoolEntry{}, %{txid: @invalid_txid_long})
      refute changeset.valid?
      assert "should be 64 character(s)" in errors_on(changeset).txid

      # Invalid format
      invalid_txid = String.duplicate("z", 64)
      changeset = GetMempoolEntry.changeset(%GetMempoolEntry{}, %{txid: invalid_txid})
      refute changeset.valid?
      assert "has invalid format" in errors_on(changeset).txid
    end
  end

  ## GetMempoolEntryResult tests

  describe "GetMempoolEntryResult.new/1" do
    test "creates result with required fields" do
      attrs = %{
        "vsize" => 141,
        "weight" => 561,
        "time" => 1_640_995_200,
        "height" => 750_123,
        "descendantcount" => 1,
        "descendantsize" => 141,
        "ancestorcount" => 1,
        "ancestorsize" => 141,
        "wtxid" => @valid_txid
      }

      assert {:ok, %GetMempoolEntryResult{} = result} = GetMempoolEntryResult.new(attrs)
      assert result.vsize == 141
      assert result.weight == 561
      assert result.time == 1_640_995_200
      assert result.wtxid == @valid_txid
    end

    test "creates result with all fields including nested fees" do
      attrs =
        get_mempool_entry_result_fixture(%{
          "wtxid" => @valid_txid,
          "bip125-replaceable" => true,
          "unbroadcast" => false
        })

      assert {:ok, %GetMempoolEntryResult{} = result} = GetMempoolEntryResult.new(attrs)
      assert result.fee == 0.00001000
      assert result.fees.base == 0.00001000
      assert result.fees.modified == 0.00001000
      assert result.bip125_replaceable == true
      assert result.depends == []
      assert result.spentby == []
    end

    test "creates result with transaction dependencies" do
      attrs = get_mempool_entry_preset(:with_dependencies)

      assert {:ok, %GetMempoolEntryResult{} = result} = GetMempoolEntryResult.new(attrs)
      assert result.depends == ["abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"]
      assert result.spentby == ["fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"]
      assert result.bip125_replaceable == false
      assert result.unbroadcast == true
    end

    test "validates required fields" do
      incomplete_attrs = %{
        "vsize" => 141
        # Missing other required fields
      }

      assert {:error, %Changeset{errors: errors}} = GetMempoolEntryResult.new(incomplete_attrs)
      assert Keyword.has_key?(errors, :weight)
      assert Keyword.has_key?(errors, :time)
      assert Keyword.has_key?(errors, :wtxid)
    end

    test "validates numeric fields are positive" do
      attrs = %{
        # Should be > 0
        "vsize" => 0,
        # Should be > 0
        "weight" => -1,
        # Should be > 0
        "time" => 0,
        "height" => 750_123,
        # Should be > 0
        "descendantcount" => 0,
        # Should be > 0
        "descendantsize" => 0,
        # Should be > 0
        "ancestorcount" => 0,
        # Should be > 0
        "ancestorsize" => 0,
        "wtxid" => @valid_txid
      }

      assert {:error, %Changeset{} = changeset} = GetMempoolEntryResult.new(attrs)
      assert "must be greater than 0" in errors_on(changeset).vsize
      assert "must be greater than 0" in errors_on(changeset).weight
      assert "must be greater than 0" in errors_on(changeset).time
    end

    test "validates wtxid format" do
      attrs = %{
        "vsize" => 141,
        "weight" => 561,
        "time" => 1_640_995_200,
        "height" => 750_123,
        "descendantcount" => 1,
        "descendantsize" => 141,
        "ancestorcount" => 1,
        "ancestorsize" => 141,
        "wtxid" => "invalid_wtxid"
      }

      assert {:error, %Changeset{} = changeset} = GetMempoolEntryResult.new(attrs)
      assert "should be 64 character(s)" in errors_on(changeset).wtxid
    end

    test "validates nested fees object" do
      attrs = %{
        "vsize" => 141,
        "weight" => 561,
        "time" => 1_640_995_200,
        "height" => 750_123,
        "descendantcount" => 1,
        "descendantsize" => 141,
        "ancestorcount" => 1,
        "ancestorsize" => 141,
        "wtxid" => @valid_txid,
        "fees" => %{
          # Should be >= 0
          "base" => -0.00001000,
          "modified" => 0.00001000,
          "ancestor" => 0.00001000,
          "descendant" => 0.00001000
        }
      }

      assert {:error, %Changeset{} = changeset} = GetMempoolEntryResult.new(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).fees.base
    end
  end

  ## GetMempoolEntry RPC

  describe "(RPC) Blockchain.get_mempool_entry/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns mempool entry", %{client: client} do
      mempool_entry = get_mempool_entry_preset(:standard)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "getmempoolentry",
                   "params" => [@valid_txid],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => mempool_entry,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetMempoolEntryResult{} = result} =
               Blockchain.get_mempool_entry(client, txid: @valid_txid)

      assert result.vsize == 141
      assert result.weight == 561
      assert result.fees.base == 0.00001000
      assert result.bip125_replaceable == true
      assert result.depends == []
      assert result.spentby == []
    end

    test "call with transaction having dependencies", %{client: client} do
      mempool_entry = get_mempool_entry_preset(:with_dependencies)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getmempoolentry",
                   "params" => [@valid_txid],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => mempool_entry,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetMempoolEntryResult{} = result} =
               Blockchain.get_mempool_entry(client, txid: @valid_txid)

      assert result.depends == ["abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"]
      assert result.spentby == ["fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"]
      assert result.descendantcount == 2
      assert result.ancestorcount == 2
      assert result.bip125_replaceable == false
      assert result.unbroadcast == true
    end

    test "handles transaction not in mempool error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -5,
                "message" => "Transaction not in mempool"
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{code: -5, message: message}} =
               Blockchain.get_mempool_entry(client, txid: @valid_txid)

      assert message == "Transaction not in mempool"
    end

    test "handles invalid transaction ID error", %{client: client} do
      invalid_txid = String.duplicate("1", 64)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -8,
                "message" => "txid must be of length 64 (not 16, for '#{invalid_txid}')"
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{code: -8, message: message}} =
               Blockchain.get_mempool_entry(client, txid: invalid_txid)

      assert message =~ "txid must be of length 64"
    end

    test "handles confirmed transaction error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -5,
                "message" => "Transaction not in mempool"
              }
            }
          }
      end)

      assert {:error, %BTx.JRPC.MethodError{code: -5, message: message}} =
               Blockchain.get_mempool_entry(client, txid: @valid_txid)

      assert message == "Transaction not in mempool"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Blockchain.get_mempool_entry!(client, txid: @valid_txid)
      end
    end

    test "handles malformed response data", %{client: client} do
      # Test when Bitcoin Core returns malformed data
      invalid_data = %{
        "vsize" => 141,
        "weight" => 561,
        "time" => 1_640_995_200,
        "height" => 750_123,
        "descendantcount" => 1,
        "descendantsize" => 141,
        "ancestorcount" => 1,
        "ancestorsize" => 141,
        # Invalid wtxid length - should fail validation
        "wtxid" => "invalid_short_wtxid"
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
               Blockchain.get_mempool_entry(client, txid: @valid_txid)

      # Should have wtxid validation error
      assert "should be 64 character(s)" in errors_on(changeset).wtxid
    end

    test "handles RBF replaceable transaction", %{client: client} do
      mempool_entry = get_mempool_entry_preset(:high_fee)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => mempool_entry,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetMempoolEntryResult{} = result} =
               Blockchain.get_mempool_entry(client, txid: @valid_txid)

      assert result.bip125_replaceable == true
      assert result.fees.base == 0.00050000
    end

    test "handles deprecated fields", %{client: client} do
      # Test with deprecated fee fields using custom overrides
      mempool_entry =
        get_mempool_entry_result_fixture(%{
          # deprecated
          "fee" => 0.00001000,
          # deprecated
          "modifiedfee" => 0.00001000,
          # deprecated
          "descendantfees" => 0.00001000,
          # deprecated
          "ancestorfees" => 0.00001000
        })

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => mempool_entry,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetMempoolEntryResult{} = result} =
               Blockchain.get_mempool_entry(client, txid: @valid_txid)

      # Both deprecated and new fee fields should be present
      assert result.fee == 0.00001000
      assert result.fees.base == 0.00001000
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node with transactions in mempool
      real_client = new_client()

      # Wallet for this test
      wallet_name = "btx-shared-test-wallet"

      # Step 1: Create a destination address (different wallet or address)
      destination_address =
        Wallets.get_new_address!(real_client, wallet_name: wallet_name, label: "destination")

      # Step 2: Get balance
      balance = Wallets.get_balance!(real_client, wallet_name: wallet_name)
      assert balance > 0.0

      # Step 3: Send a transaction (this will create a mempool entry)
      # Leave room for fees
      send_amount = min(balance - 0.001, 0.1)

      # Step 4: Send a transaction
      {:ok, send_result} =
        Wallets.send_to_address(real_client,
          address: destination_address,
          amount: send_amount,
          wallet_name: wallet_name,
          comment: "Integration test transaction"
        )

      txid = send_result.txid

      # Step 5: Verify the mempool entry
      assert_eventually do
        assert {:ok, %GetMempoolEntryResult{} = result} =
                 Blockchain.get_mempool_entry(real_client, txid: txid)

        # Verify the mempool entry has expected fields
        assert is_integer(result.vsize)
        assert result.vsize > 0
        assert is_integer(result.weight)
        assert result.weight > 0
        assert is_binary(result.wtxid)
        assert String.length(result.wtxid) == 64
        assert is_list(result.depends)
        assert is_list(result.spentby)
        assert is_boolean(result.bip125_replaceable)
        assert is_boolean(result.unbroadcast)

        # Check that fees object is present and valid
        assert %BTx.JRPC.Blockchain.GetMempoolEntryFees{} = result.fees
        assert is_float(result.fees.base)
        assert result.fees.base >= 0.0

        # Verify counts make sense
        assert result.descendantcount >= 1
        assert result.ancestorcount >= 1
        assert result.descendantsize >= result.vsize
        assert result.ancestorsize >= result.vsize
      end
    end
  end

  describe "(RPC) Blockchain.get_mempool_entry!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns mempool entry result", %{client: client} do
      mempool_entry = get_mempool_entry_preset(:standard)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => mempool_entry,
              "error" => nil
            }
          }
      end)

      assert %GetMempoolEntryResult{} =
               result = Blockchain.get_mempool_entry!(client, txid: @valid_txid)

      assert result.vsize == 141
      assert result.wtxid == "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        Blockchain.get_mempool_entry!(client, txid: @valid_txid)
      end
    end

    test "raises on invalid result data", %{client: client} do
      # Invalid result missing required fields
      invalid_entry = %{
        "vsize" => 141
        # Missing other required fields
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => invalid_entry,
              "error" => nil
            }
          }
      end)

      assert_raise Ecto.InvalidChangesetError, fn ->
        Blockchain.get_mempool_entry!(client, txid: @valid_txid)
      end
    end
  end
end
