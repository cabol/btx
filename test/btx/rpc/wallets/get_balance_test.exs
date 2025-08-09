defmodule BTx.RPC.Wallets.GetBalanceTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.GetBalance
  alias Ecto.{Changeset, UUID}

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a new GetBalance with default values" do
      assert {:ok, %GetBalance{dummy: "*", minconf: 0, include_watchonly: true, avoid_reuse: true}} =
               GetBalance.new()
    end

    test "creates a new GetBalance with empty map" do
      assert {:ok, %GetBalance{dummy: "*", minconf: 0, include_watchonly: true, avoid_reuse: true}} =
               GetBalance.new(%{})
    end

    test "creates a new GetBalance with custom minconf" do
      assert {:ok, %GetBalance{minconf: 6}} = GetBalance.new(minconf: 6)
    end

    test "creates a new GetBalance with custom include_watchonly" do
      assert {:ok, %GetBalance{include_watchonly: false}} =
               GetBalance.new(include_watchonly: false)
    end

    test "creates a new GetBalance with custom avoid_reuse" do
      assert {:ok, %GetBalance{avoid_reuse: false}} = GetBalance.new(avoid_reuse: false)
    end

    test "creates a new GetBalance with wallet_name" do
      assert {:ok, %GetBalance{wallet_name: "test_wallet"}} =
               GetBalance.new(wallet_name: "test_wallet")
    end

    test "creates a new GetBalance with all parameters" do
      assert {:ok,
              %GetBalance{
                dummy: "*",
                minconf: 3,
                include_watchonly: true,
                avoid_reuse: false,
                wallet_name: "my_wallet"
              }} =
               GetBalance.new(
                 minconf: 3,
                 include_watchonly: true,
                 avoid_reuse: false,
                 wallet_name: "my_wallet"
               )
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
        assert {:ok, %GetBalance{wallet_name: ^name}} =
                 GetBalance.new(wallet_name: name)
      end
    end

    test "accepts valid minconf values" do
      valid_values = [0, 1, 6, 100, 999]

      for value <- valid_values do
        assert {:ok, %GetBalance{minconf: ^value}} = GetBalance.new(minconf: value)
      end
    end

    test "returns error for negative minconf" do
      assert {:error, %Changeset{errors: errors}} = GetBalance.new(minconf: -1)

      assert Keyword.fetch!(errors, :minconf) ==
               {"must be greater than or equal to %{number}",
                [{:validation, :number}, {:kind, :greater_than_or_equal_to}, {:number, 0}]}
    end

    test "returns error for invalid dummy value" do
      assert {:error, %Changeset{errors: errors}} = GetBalance.new(dummy: "invalid")

      assert Keyword.fetch!(errors, :dummy) ==
               {"is invalid", [{:validation, :inclusion}, {:enum, ["*"]}]}
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} = GetBalance.new(wallet_name: long_name)

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "accepts nil dummy value" do
      assert {:ok, %GetBalance{dummy: nil}} = GetBalance.new(dummy: nil)
    end

    test "accepts empty string wallet name should succeed because it is ignored by changeset" do
      assert {:ok, %GetBalance{wallet_name: nil}} = GetBalance.new(wallet_name: "")
    end
  end

  describe "new!/1" do
    test "creates a new GetBalance with default values" do
      assert %GetBalance{dummy: "*", minconf: 0, include_watchonly: true, avoid_reuse: true} =
               GetBalance.new!()
    end

    test "creates a new GetBalance with custom parameters" do
      assert %GetBalance{minconf: 6, include_watchonly: false} =
               GetBalance.new!(minconf: 6, include_watchonly: false)
    end

    test "raises error for invalid minconf" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetBalance.new!(minconf: -1)
      end
    end

    test "raises error for invalid dummy" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetBalance.new!(dummy: "invalid")
      end
    end

    test "raises error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert_raise Ecto.InvalidChangesetError, fn ->
        GetBalance.new!(wallet_name: long_name)
      end
    end
  end

  describe "encodable" do
    test "encodes method with default values" do
      assert %Request{
               params: ["*", 0, true, true],
               method: "getbalance",
               jsonrpc: "1.0",
               path: "/"
             } = GetBalance.new!() |> Encodable.encode()
    end

    test "encodes method with wallet name" do
      assert %Request{
               params: ["*", 0, true, true],
               method: "getbalance",
               jsonrpc: "1.0",
               path: "/wallet/test_wallet"
             } = GetBalance.new!(wallet_name: "test_wallet") |> Encodable.encode()
    end

    test "encodes method with custom minconf" do
      assert %Request{
               params: ["*", 6, true, true],
               method: "getbalance",
               jsonrpc: "1.0",
               path: "/"
             } = GetBalance.new!(minconf: 6) |> Encodable.encode()
    end

    test "encodes method with include_watchonly" do
      assert %Request{
               params: ["*", 0, false, true],
               method: "getbalance",
               jsonrpc: "1.0",
               path: "/"
             } = GetBalance.new!(include_watchonly: false) |> Encodable.encode()
    end

    test "encodes method with all parameters" do
      assert %Request{
               params: ["*", 3, true, false],
               method: "getbalance",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               GetBalance.new!(
                 minconf: 3,
                 include_watchonly: true,
                 avoid_reuse: false,
                 wallet_name: "my_wallet"
               )
               |> Encodable.encode()
    end

    test "encodes method with nil dummy" do
      assert %Request{
               params: [nil, 0, true, true],
               method: "getbalance",
               jsonrpc: "1.0",
               path: "/"
             } = GetBalance.new!(dummy: nil) |> Encodable.encode()
    end

    test "removes trailing nil parameters" do
      # This test is no longer relevant since we don't remove trailing nils
      # All parameters now have defaults, so this test can be removed or renamed
      assert %Request{
               params: ["*", 6, true, true],
               method: "getbalance",
               jsonrpc: "1.0",
               path: "/"
             } = GetBalance.new!(minconf: 6) |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "validates minconf is non-negative" do
      # Valid values
      for value <- [0, 1, 10, 100] do
        changeset = GetBalance.changeset(%GetBalance{}, %{minconf: value})
        assert changeset.valid?
      end

      # Invalid negative value
      changeset = GetBalance.changeset(%GetBalance{}, %{minconf: -1})
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).minconf
    end

    test "validates dummy value" do
      # Valid values
      changeset = GetBalance.changeset(%GetBalance{}, %{dummy: "*"})
      assert changeset.valid?

      changeset = GetBalance.changeset(%GetBalance{}, %{dummy: nil})
      assert changeset.valid?

      # Invalid value
      changeset = GetBalance.changeset(%GetBalance{}, %{dummy: "invalid"})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).dummy
    end

    test "validates wallet name length" do
      # Valid length
      valid_name = String.duplicate("a", 64)
      changeset = GetBalance.changeset(%GetBalance{}, %{wallet_name: valid_name})
      assert changeset.valid?

      # Too long
      long_name = String.duplicate("a", 65)
      changeset = GetBalance.changeset(%GetBalance{}, %{wallet_name: long_name})
      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "accepts all optional fields" do
      request =
        GetBalance.changeset(%GetBalance{}, %{
          dummy: "*",
          minconf: 6,
          include_watchonly: true,
          avoid_reuse: false,
          wallet_name: "test_wallet"
        })
        |> Changeset.apply_action!(:getbalance)

      assert request.dummy == "*"
      assert request.minconf == 6
      assert request.include_watchonly == true
      assert request.avoid_reuse == false
      assert request.wallet_name == "test_wallet"
    end

    test "accepts empty parameters" do
      changeset = GetBalance.changeset(%GetBalance{}, %{})
      assert changeset.valid?
    end
  end

  ## GetBalance RPC

  describe "(RPC) Wallets.get_balance/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns balance", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "getbalance",
                   "params" => ["*", 0, true, true],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => 1.50000000,
              "error" => nil
            }
          }
      end)

      assert Wallets.get_balance(client) == {:ok, 1.50000000}
    end

    test "call with wallet name", %{client: client} do
      url = Path.join(@url, "/wallet/test-wallet")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "getbalance",
                   "params" => ["*", 0, true, true],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 2.50000000,
              "error" => nil
            }
          }
      end)

      assert Wallets.get_balance(client, wallet_name: "test-wallet") == {:ok, 2.50000000}
    end

    test "call with minimum confirmations", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getbalance",
                   "params" => ["*", 6, true, true],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 1.25000000,
              "error" => nil
            }
          }
      end)

      assert Wallets.get_balance(client, minconf: 6) == {:ok, 1.25000000}
    end

    test "call with include_watchonly false", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getbalance",
                   "params" => ["*", 0, false, true],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 1.00000000,
              "error" => nil
            }
          }
      end)

      assert Wallets.get_balance(client, include_watchonly: false) == {:ok, 1.00000000}
    end

    test "call with all parameters", %{client: client} do
      url = Path.join(@url, "/wallet/my-wallet")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "getbalance",
                   "params" => ["*", 3, true, false],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 0.75000000,
              "error" => nil
            }
          }
      end)

      assert Wallets.get_balance(client,
               wallet_name: "my-wallet",
               minconf: 3,
               include_watchonly: true,
               avoid_reuse: false
             ) == {:ok, 0.75000000}
    end

    test "handles insufficient funds (zero balance)", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 0.00000000,
              "error" => nil
            }
          }
      end)

      assert Wallets.get_balance(client) == {:ok, 0.00000000}
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

      assert {:error,
              %BTx.RPC.MethodError{
                code: -18,
                message: message,
                reason: :wallet_not_found
              }} = Wallets.get_balance(client, wallet_name: "nonexistent")

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_balance!(client)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client(retry_opts: [max_retries: 10])

      # First ensure we have a wallet loaded, create one if needed
      wallet_name =
        Wallets.create_wallet!(
          real_client,
          wallet_name: "test-wallet-#{UUID.generate()}",
          passphrase: "test",
          avoid_reuse: true
        ).name

      assert {:ok, balance} =
               Wallets.get_balance(real_client, wallet_name: wallet_name)

      assert is_number(balance)
      assert balance >= 0.0
    end
  end

  describe "(RPC) Wallets.get_balance!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns balance", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => 1.50000000,
              "error" => nil
            }
          }
      end)

      assert Wallets.get_balance!(client) == 1.50000000
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_balance!(client)
      end
    end
  end
end
