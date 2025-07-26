defmodule BTx.RPC.Wallets.ListUnspentTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.WalletsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.{ListUnspent, ListUnspentItem, ListUnspentQueryOptions}
  alias Ecto.Changeset

  # Valid Bitcoin addresses for testing
  @valid_bech32_address "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl"
  @valid_legacy_address "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
  @valid_p2sh_address "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"

  @url "http://localhost:18443/"

  ## ListUnspentQueryOptions tests

  describe "ListUnspentQueryOptions.changeset/2" do
    test "accepts valid query options" do
      attrs = %{
        "minimumAmount" => 0.001,
        "maximumAmount" => 1.0,
        "maximumCount" => 50,
        "minimumSumAmount" => 0.01
      }

      changeset = ListUnspentQueryOptions.changeset(%ListUnspentQueryOptions{}, attrs)

      assert changeset.valid?
      assert Changeset.get_change(changeset, :minimum_amount) == 0.001
      assert Changeset.get_change(changeset, :maximum_amount) == 1.0
      assert Changeset.get_change(changeset, :maximum_count) == 50
      assert Changeset.get_change(changeset, :minimum_sum_amount) == 0.01
    end

    test "handles empty options" do
      changeset = ListUnspentQueryOptions.changeset(%ListUnspentQueryOptions{}, %{})
      assert changeset.valid?
    end

    test "validates minimum_amount >= 0" do
      changeset =
        ListUnspentQueryOptions.changeset(%ListUnspentQueryOptions{}, %{
          "minimumAmount" => -0.001
        })

      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).minimum_amount
    end

    test "validates maximum_count >= 1" do
      changeset =
        ListUnspentQueryOptions.changeset(%ListUnspentQueryOptions{}, %{
          "maximumCount" => 0
        })

      refute changeset.valid?
      assert "must be greater than or equal to 1" in errors_on(changeset).maximum_count
    end
  end

  ## ListUnspentItem tests

  describe "ListUnspentItem.new/1" do
    test "creates item with required fields" do
      attrs = %{
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "vout" => 0,
        "amount" => 0.05000000,
        "confirmations" => 6,
        "spendable" => true,
        "solvable" => true,
        "safe" => true
      }

      assert {:ok, %ListUnspentItem{} = item} = ListUnspentItem.new(attrs)
      assert item.txid == "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      assert item.vout == 0
      assert item.amount == 0.05000000
      assert item.spendable == true
    end

    test "creates item with all fields" do
      attrs = list_unspent_preset(:confirmed)

      assert {:ok, %ListUnspentItem{} = item} = ListUnspentItem.new(attrs)
      assert item.address == @valid_bech32_address
      assert item.script_pub_key == "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
      assert item.label == ""
      assert item.desc != nil
    end

    test "creates item for P2SH with redeem script" do
      attrs = list_unspent_preset(:p2sh)

      assert {:ok, %ListUnspentItem{} = item} = ListUnspentItem.new(attrs)
      assert item.address == @valid_p2sh_address
      assert item.redeem_script != nil
      assert item.spendable == true
    end

    test "creates item for watch-only output" do
      attrs = list_unspent_preset(:watch_only)

      assert {:ok, %ListUnspentItem{} = item} = ListUnspentItem.new(attrs)
      assert item.spendable == false
      assert item.solvable == true
      assert item.label == "watch_only"
    end

    test "validates required fields" do
      incomplete_attrs = %{
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        # Missing other required fields
      }

      assert {:error, %Changeset{errors: errors}} = ListUnspentItem.new(incomplete_attrs)
      assert Keyword.has_key?(errors, :vout)
      assert Keyword.has_key?(errors, :amount)
      assert Keyword.has_key?(errors, :confirmations)
      assert Keyword.has_key?(errors, :spendable)
      assert Keyword.has_key?(errors, :solvable)
      assert Keyword.has_key?(errors, :safe)
    end

    test "validates scriptPubKey field mapping" do
      attrs = %{
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "vout" => 0,
        "amount" => 0.05,
        "confirmations" => 6,
        "spendable" => true,
        "solvable" => true,
        "safe" => true,
        "scriptPubKey" => "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
      }

      assert {:ok, %ListUnspentItem{} = item} = ListUnspentItem.new(attrs)
      assert item.script_pub_key == "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
    end

    test "validates redeemScript field mapping" do
      attrs = %{
        "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "vout" => 0,
        "amount" => 0.05,
        "confirmations" => 6,
        "spendable" => true,
        "solvable" => true,
        "safe" => true,
        "redeemScript" => "522103abc123def456"
      }

      assert {:ok, %ListUnspentItem{} = item} = ListUnspentItem.new(attrs)
      assert item.redeem_script == "522103abc123def456"
    end
  end

  ## ListUnspent schema tests

  describe "ListUnspent.new/1" do
    test "creates request with default values" do
      assert {:ok, %ListUnspent{} = request} = ListUnspent.new(%{})
      assert request.minconf == 1
      assert request.maxconf == 9_999_999
      assert request.addresses == []
      assert request.include_unsafe == true
      assert request.query_options == nil
    end

    test "creates request with custom parameters" do
      assert {:ok, %ListUnspent{} = request} =
               ListUnspent.new(%{
                 minconf: 6,
                 maxconf: 100,
                 addresses: [@valid_bech32_address, @valid_legacy_address],
                 include_unsafe: false,
                 wallet_name: "my_wallet"
               })

      assert request.minconf == 6
      assert request.maxconf == 100
      assert request.addresses == [@valid_bech32_address, @valid_legacy_address]
      assert request.include_unsafe == false
      assert request.wallet_name == "my_wallet"
    end

    test "creates request with query options" do
      query_options = %{
        minimum_amount: 0.001,
        maximum_amount: 1.0,
        maximum_count: 50
      }

      assert {:ok, %ListUnspent{} = request} =
               ListUnspent.new(%{
                 query_options: query_options
               })

      assert request.query_options.minimum_amount == 0.001
      assert request.query_options.maximum_amount == 1.0
      assert request.query_options.maximum_count == 50
    end

    test "validates minconf >= 0" do
      assert {:error, %Changeset{} = changeset} = ListUnspent.new(%{minconf: -1})
      assert "must be greater than or equal to 0" in errors_on(changeset).minconf
    end

    test "validates maxconf >= 0" do
      assert {:error, %Changeset{} = changeset} = ListUnspent.new(%{maxconf: -1})
      assert "must be greater than or equal to 0" in errors_on(changeset).maxconf
    end

    test "validates addresses format" do
      assert {:error, %Changeset{} = changeset} =
               ListUnspent.new(%{
                 addresses: ["invalid_address", @valid_bech32_address]
               })

      assert "contains invalid Bitcoin addresses" in errors_on(changeset).addresses
    end

    test "accepts valid addresses" do
      valid_addresses = [@valid_bech32_address, @valid_legacy_address, @valid_p2sh_address]

      assert {:ok, %ListUnspent{} = request} =
               ListUnspent.new(%{
                 addresses: valid_addresses
               })

      assert request.addresses == valid_addresses
    end

    test "validates wallet_name length" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               ListUnspent.new(%{
                 wallet_name: long_name
               })

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end
  end

  describe "ListUnspent encodable" do
    test "encodes minimal request" do
      assert %Request{
               params: [1, 9_999_999, [], true, nil],
               method: "listunspent",
               jsonrpc: "1.0",
               path: "/"
             } = ListUnspent.new!(%{}) |> Encodable.encode()
    end

    test "encodes request with custom minconf/maxconf" do
      assert %Request{
               params: [6, 100, [], true, nil],
               method: "listunspent",
               jsonrpc: "1.0",
               path: "/"
             } = ListUnspent.new!(%{minconf: 6, maxconf: 100}) |> Encodable.encode()
    end

    test "encodes request with addresses" do
      addresses = [@valid_bech32_address, @valid_legacy_address]

      assert %Request{
               params: [1, 9_999_999, ^addresses, true, nil],
               method: "listunspent",
               jsonrpc: "1.0",
               path: "/"
             } = ListUnspent.new!(%{addresses: addresses}) |> Encodable.encode()
    end

    test "encodes request with include_unsafe false" do
      assert %Request{
               params: [1, 9_999_999, [], false, nil],
               method: "listunspent",
               jsonrpc: "1.0",
               path: "/"
             } = ListUnspent.new!(%{include_unsafe: false}) |> Encodable.encode()
    end

    test "encodes request with query options" do
      query_options = %{
        minimum_amount: 0.001,
        maximum_amount: 1.0,
        maximum_count: 50
      }

      encoded = ListUnspent.new!(%{query_options: query_options}) |> Encodable.encode()

      assert %Request{
               params: [1, 9_999_999, [], true, query_options_map],
               method: "listunspent"
             } = encoded

      assert query_options_map["minimumAmount"] == 0.001
      assert query_options_map["maximumAmount"] == 1.0
      assert query_options_map["maximumCount"] == 50
    end

    test "encodes request with wallet name" do
      assert %Request{
               params: [1, 9_999_999, [], true, nil],
               method: "listunspent",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } = ListUnspent.new!(%{wallet_name: "my_wallet"}) |> Encodable.encode()
    end

    test "encodes complete request" do
      addresses = [@valid_bech32_address]
      query_options = %{minimum_amount: 0.01}

      encoded =
        ListUnspent.new!(%{
          minconf: 6,
          maxconf: 100,
          addresses: addresses,
          include_unsafe: false,
          query_options: query_options,
          wallet_name: "test_wallet"
        })
        |> Encodable.encode()

      assert %Request{
               params: [6, 100, ^addresses, false, %{"minimumAmount" => 0.01}],
               method: "listunspent",
               path: "/wallet/test_wallet"
             } = encoded
    end
  end

  ## ListUnspent RPC tests

  describe "(RPC) Wallets.list_unspent/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns list of unspent outputs", %{client: client} do
      unspent_list = list_unspent_list_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "listunspent",
                   "params" => [1, 9_999_999, [], true, nil],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => unspent_list,
              "error" => nil
            }
          }
      end)

      assert {:ok, items} = Wallets.list_unspent(client)
      assert length(items) == 3
      assert Enum.all?(items, &is_struct(&1, ListUnspentItem))

      first_item = List.first(items)
      assert first_item.txid != nil
      assert first_item.amount > 0
      assert is_boolean(first_item.spendable)
    end

    test "call with custom parameters", %{client: client} do
      unspent_list = [list_unspent_preset(:confirmed)]
      addresses = [@valid_bech32_address]

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "listunspent",
                   "params" => [6, 100, ^addresses, false, nil],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => unspent_list,
              "error" => nil
            }
          }
      end)

      assert {:ok, items} =
               Wallets.list_unspent(client,
                 minconf: 6,
                 maxconf: 100,
                 addresses: addresses,
                 include_unsafe: false
               )

      assert length(items) == 1
      assert List.first(items).address == @valid_bech32_address
    end

    test "call with query options", %{client: client} do
      unspent_list = [list_unspent_preset(:large_amount)]

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded = BTx.json_module().decode!(body)

          assert %{
                   "method" => "listunspent",
                   "params" => [1, 9_999_999, [], true, query_options]
                 } = decoded

          assert query_options["minimumAmount"] == 0.01
          assert query_options["maximumCount"] == 10

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => unspent_list,
              "error" => nil
            }
          }
      end)

      assert {:ok, items} =
               Wallets.list_unspent(client,
                 query_options: %{
                   minimum_amount: 0.01,
                   maximum_count: 10
                 }
               )

      assert length(items) == 1
      assert List.first(items).amount == 1.5
    end

    test "call with wallet name", %{client: client} do
      url = Path.join(@url, "/wallet/my_wallet")
      unspent_list = [list_unspent_preset(:confirmed)]

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "listunspent",
                   "params" => [1, 9_999_999, [], true, nil],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => unspent_list,
              "error" => nil
            }
          }
      end)

      assert {:ok, items} = Wallets.list_unspent(client, wallet_name: "my_wallet")
      assert length(items) == 1
    end

    test "handles empty result", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => [],
              "error" => nil
            }
          }
      end)

      assert {:ok, []} = Wallets.list_unspent(client)
    end

    test "handles invalid item", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => [%{}],
              "error" => nil
            }
          }
      end)

      assert {:error, %Ecto.Changeset{errors: errors}} = Wallets.list_unspent(client)
      assert errors[:txid] == {"can't be blank", [validation: :required]}
    end

    test "handles invalid response data", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{},
              "error" => nil
            }
          }
      end)

      assert_raise RuntimeError, ~r/Expected a list of unspent outputs/, fn ->
        Wallets.list_unspent(client)
      end
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
               Wallets.list_unspent(client, wallet_name: "nonexistent")

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.list_unspent!(client)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client()

      # Wallet for this test
      wallet_name = "btx-shared-test-wallet"

      # Now we should have unspent outputs
      assert {:ok, outputs} =
               Wallets.list_unspent(real_client, wallet_name: wallet_name)

      if first_output = List.first(outputs) do
        assert %ListUnspentItem{} = first_output
        assert is_binary(first_output.txid)
        assert is_integer(first_output.vout)
        assert first_output.amount > 0
        assert is_boolean(first_output.spendable)
      end
    end
  end

  describe "(RPC) Wallets.list_unspent!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns list of unspent outputs", %{client: client} do
      unspent_list = list_unspent_list_fixture()

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => unspent_list,
              "error" => nil
            }
          }
      end)

      items = Wallets.list_unspent!(client)
      assert length(items) == 3
      assert Enum.all?(items, &is_struct(&1, ListUnspentItem))
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.list_unspent!(client, minconf: -1)
      end
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.list_unspent!(client)
      end
    end

    test "raises on invalid result data", %{client: client} do
      # Invalid result with missing required fields
      invalid_unspent = [
        %{
          "txid" => "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
          # Missing other required fields
        }
      ]

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => invalid_unspent,
              "error" => nil
            }
          }
      end)

      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.list_unspent!(client)
      end
    end
  end
end
