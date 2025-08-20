defmodule BTx.RPC.Wallets.GetBalancesTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.WalletsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Wallets}

  alias BTx.RPC.Wallets.{
    GetBalances,
    GetBalancesDetail,
    GetBalancesResult
  }

  alias Ecto.{Changeset, UUID}

  @valid_wallet_name "test_wallet"
  @url "http://localhost:18443/"

  ## GetBalances schema tests

  describe "GetBalances.new/1" do
    test "creates a new GetBalances with default values" do
      assert {:ok, %GetBalances{method: "getbalances", wallet_name: nil}} =
               GetBalances.new()
    end

    test "creates a new GetBalances with wallet_name" do
      assert {:ok, %GetBalances{method: "getbalances", wallet_name: @valid_wallet_name}} =
               GetBalances.new(wallet_name: @valid_wallet_name)
    end

    test "accepts keyword list params" do
      assert {:ok, %GetBalances{wallet_name: @valid_wallet_name}} =
               GetBalances.new(wallet_name: @valid_wallet_name)
    end

    test "accepts map params" do
      assert {:ok, %GetBalances{wallet_name: @valid_wallet_name}} =
               GetBalances.new(%{wallet_name: @valid_wallet_name})
    end

    test "accepts valid wallet_names" do
      valid_names = [
        "test_wallet",
        "wallet123",
        "my-wallet",
        "wallet.dat",
        "a",
        String.duplicate("a", 64)
      ]

      for valid_name <- valid_names do
        assert {:ok, %GetBalances{wallet_name: ^valid_name}} =
                 GetBalances.new(wallet_name: valid_name)
      end
    end
  end

  describe "GetBalances.new!/1" do
    test "creates a new GetBalances with default values" do
      assert %GetBalances{method: "getbalances", wallet_name: nil} =
               GetBalances.new!()
    end

    test "creates a new GetBalances with wallet_name" do
      assert %GetBalances{method: "getbalances", wallet_name: @valid_wallet_name} =
               GetBalances.new!(wallet_name: @valid_wallet_name)
    end

    test "raises on validation error" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetBalances.new!(wallet_name: "(*)")
      end
    end
  end

  ## GetBalancesDetail schema tests

  describe "GetBalancesDetail.new/1" do
    test "creates a new GetBalancesDetail with required fields" do
      attrs = %{
        "trusted" => 1.5,
        "untrusted_pending" => 0.0,
        "immature" => 0.25
      }

      assert {:ok, %GetBalancesDetail{} = detail} = GetBalancesDetail.new(attrs)
      assert detail.trusted == 1.5
      assert detail.untrusted_pending == 0.0
      assert detail.immature == 0.25
      assert detail.used == nil
    end

    test "creates a new GetBalancesDetail with all fields" do
      attrs = get_balances_detail_fixture()

      assert {:ok, %GetBalancesDetail{} = detail} = GetBalancesDetail.new(attrs)
      assert detail.trusted == 1.5
      assert detail.untrusted_pending == 0.0
      assert detail.immature == 0.25
      assert detail.used == 0.1
    end

    test "validates required fields" do
      assert {:error, %Changeset{} = changeset} = GetBalancesDetail.new(%{})

      errors = errors_on(changeset)
      assert "can't be blank" in errors.trusted
      assert "can't be blank" in errors.untrusted_pending
      assert "can't be blank" in errors.immature
    end

    test "validates numeric fields are non-negative" do
      invalid_attrs = %{
        "trusted" => -1.0,
        "untrusted_pending" => -0.5,
        "immature" => -0.25,
        "used" => -0.1
      }

      assert {:error, %Changeset{} = changeset} = GetBalancesDetail.new(invalid_attrs)

      errors = errors_on(changeset)
      assert "must be greater than or equal to 0" in errors.trusted
      assert "must be greater than or equal to 0" in errors.untrusted_pending
      assert "must be greater than or equal to 0" in errors.immature
      assert "must be greater than or equal to 0" in errors.used
    end

    test "accepts zero values" do
      attrs = %{
        "trusted" => 0.0,
        "untrusted_pending" => 0.0,
        "immature" => 0.0,
        "used" => 0.0
      }

      assert {:ok, %GetBalancesDetail{}} = GetBalancesDetail.new(attrs)
    end
  end

  describe "GetBalancesDetail.new!/1" do
    test "creates a new GetBalancesDetail" do
      attrs = get_balances_detail_fixture()

      assert %GetBalancesDetail{} = GetBalancesDetail.new!(attrs)
    end

    test "raises on validation error" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetBalancesDetail.new!(%{})
      end
    end
  end

  ## GetBalancesResult schema tests

  describe "GetBalancesResult.new/1" do
    test "creates a new GetBalancesResult with mine and watchonly" do
      attrs = get_balances_result_fixture()

      assert {:ok, %GetBalancesResult{} = result} = GetBalancesResult.new(attrs)
      assert %GetBalancesDetail{} = result.mine
      assert result.mine.trusted == 1.5
      assert %GetBalancesDetail{} = result.watchonly
      assert result.watchonly.trusted == 0.5
    end

    test "creates a new GetBalancesResult with mine only" do
      attrs = get_balances_preset(:mine_only)

      assert {:ok, %GetBalancesResult{} = result} = GetBalancesResult.new(attrs)
      assert %GetBalancesDetail{} = result.mine
      assert result.watchonly == nil
    end

    test "accepts empty attrs" do
      assert {:ok, %GetBalancesResult{mine: nil, watchonly: nil}} =
               GetBalancesResult.new(%{})
    end

    test "validates embedded schemas" do
      attrs = %{
        "mine" => %{"trusted" => "data"}
      }

      assert {:error, %Changeset{changes: %{mine: changeset}}} = GetBalancesResult.new(attrs)

      assert changeset.errors[:untrusted_pending] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:immature] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:trusted] == {"is invalid", [type: :float, validation: :cast]}
    end
  end

  describe "GetBalancesResult.new!/1" do
    test "creates a new GetBalancesResult" do
      attrs = get_balances_result_fixture()

      assert %GetBalancesResult{} = GetBalancesResult.new!(attrs)
    end

    test "raises on validation error" do
      attrs = %{
        "mine" => %{"invalid" => "data"}
      }

      assert_raise Ecto.InvalidChangesetError, fn ->
        GetBalancesResult.new!(attrs)
      end
    end
  end

  ## Encodable protocol tests

  describe "Encodable protocol for GetBalances" do
    test "encodes without wallet_name" do
      request = GetBalances.new!()
      encoded = Encodable.encode(request)

      assert encoded.method == "getbalances"
      assert encoded.params == []
      assert encoded.path == "/"
    end

    test "encodes with wallet_name" do
      request = GetBalances.new!(wallet_name: @valid_wallet_name)
      encoded = Encodable.encode(request)

      assert encoded.method == "getbalances"
      assert encoded.params == []
      assert encoded.path == "/wallet/#{@valid_wallet_name}"
    end
  end

  ## GetBalances RPC

  describe "(RPC) Wallets.get_balances/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "calls getbalances RPC method", %{client: client} do
      result_fixture = get_balances_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          decoded_body = BTx.json_module().decode!(body)

          assert %{
                   "method" => "getbalances",
                   "params" => [],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = decoded_body

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

      assert {:ok, result} = Wallets.get_balances(client)

      assert %GetBalancesResult{} = result
      assert %GetBalancesDetail{} = result.mine
      assert result.mine.trusted == 1.5
      assert %GetBalancesDetail{} = result.watchonly
      assert result.watchonly.trusted == 0.5
    end

    test "calls with wallet name", %{client: client} do
      result_fixture = get_balances_preset(:mine_only)
      url = Path.join(@url, "/wallet/#{@valid_wallet_name}")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)

          assert %{
                   "method" => "getbalances",
                   "params" => [],
                   "jsonrpc" => "1.0"
                 } = decoded_body

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_balances(client,
                 wallet_name: @valid_wallet_name
               )

      assert %GetBalancesResult{} = result
      assert %GetBalancesDetail{} = result.mine
      assert result.watchonly == nil
    end

    test "handles different balance scenarios", %{client: client} do
      test_cases = [
        {:with_pending, "pending balances"},
        {:with_immature, "immature balances"},
        {:empty_wallet, "empty wallet"}
      ]

      for {preset, _description} <- test_cases do
        result_fixture = get_balances_preset(preset)

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

        assert {:ok, result} = Wallets.get_balances(client)
        assert %GetBalancesResult{} = result
        assert %GetBalancesDetail{} = result.mine
      end
    end

    test "handles validation error", %{client: client} do
      assert {:error, %Changeset{}} =
               Wallets.get_balances(client,
                 wallet_name: "{}*"
               )
    end

    test "handles RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url <> "wallet/nonexistent"} ->
          %Tesla.Env{
            status: 200,
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

      assert {:error, error} =
               Wallets.get_balances(client,
                 wallet_name: "nonexistent"
               )

      assert %BTx.RPC.MethodError{code: -18} = error
    end

    test "handles network error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 500, body: "Internal Server Error"}
      end)

      assert {:error, error} = Wallets.get_balances(client)
      assert %BTx.RPC.Error{} = error
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client(retry_opts: [max_retries: 10, delay: :timer.seconds(1)])

      # First ensure we have a wallet loaded, create one if needed
      wallet_name =
        Wallets.create_wallet!(
          real_client,
          wallet_name: "test-wallet-#{UUID.generate()}",
          passphrase: "test",
          avoid_reuse: true
        ).name

      # Get balances for the specific wallet
      assert {:ok, %GetBalancesResult{} = result} =
               Wallets.get_balances(
                 real_client,
                 wallet_name: wallet_name
               )

      # Verify basic structure
      assert %GetBalancesDetail{} = result.mine
      assert is_float(result.mine.trusted)
      assert is_float(result.mine.untrusted_pending)
      assert is_float(result.mine.immature)
      assert result.mine.trusted >= 0
      assert result.mine.untrusted_pending >= 0
      assert result.mine.immature >= 0

      # "used" field is only present if avoid_reuse is set
      if result.mine.used do
        assert is_float(result.mine.used)
        assert result.mine.used >= 0
      end

      # watchonly is optional
      if result.watchonly do
        assert %GetBalancesDetail{} = result.watchonly
        assert is_float(result.watchonly.trusted)
        assert is_float(result.watchonly.untrusted_pending)
        assert is_float(result.watchonly.immature)
        assert result.watchonly.trusted >= 0
        assert result.watchonly.untrusted_pending >= 0
        assert result.watchonly.immature >= 0
      end

      # Clean up - unload the test wallet
      Wallets.unload_wallet(real_client, wallet_name: wallet_name)
    end
  end

  describe "(RPC) Wallets.get_balances!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns GetBalancesResult", %{client: client} do
      result_fixture = get_balances_result_fixture()

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

      assert %GetBalancesResult{} = result = Wallets.get_balances!(client)
      assert %GetBalancesDetail{} = result.mine
      assert result.mine.trusted == 1.5
      assert %GetBalancesDetail{} = result.watchonly
      assert result.watchonly.trusted == 0.5
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url <> "wallet/nonexistent"} ->
          %Tesla.Env{
            status: 200,
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

      assert_raise BTx.RPC.MethodError, ~r/Requested wallet does not exist/, fn ->
        Wallets.get_balances!(client, wallet_name: "nonexistent")
      end
    end

    test "raises on network error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_balances!(client)
      end
    end

    test "raises on missing required fields", %{client: client} do
      invalid_result = %{
        "mine" => %{
          "trusted" => 1.0
          # Missing required fields
        }
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => invalid_result,
              "error" => nil
            }
          }
      end)

      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.get_balances!(client)
      end
    end
  end
end
