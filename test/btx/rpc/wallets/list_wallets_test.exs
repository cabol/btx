defmodule BTx.RPC.Wallets.ListWalletsTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.ListWallets
  alias Ecto.Changeset

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/0" do
    test "creates a new ListWallets with default values" do
      assert {:ok, %ListWallets{method: "listwallets"}} = ListWallets.new()
    end
  end

  describe "new!/0" do
    test "creates a new ListWallets with default values" do
      assert %ListWallets{method: "listwallets"} = ListWallets.new!()
    end
  end

  describe "encodable" do
    test "encodes method with empty parameters" do
      assert %Request{
               params: [],
               method: "listwallets",
               jsonrpc: "1.0",
               path: "/"
             } = ListWallets.new!() |> Encodable.encode()
    end

    test "always encodes with empty parameters" do
      assert %Request{
               params: [],
               method: "listwallets",
               jsonrpc: "1.0",
               path: "/"
             } = ListWallets.new!() |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "accepts empty parameters" do
      changeset = ListWallets.changeset(%ListWallets{}, %{})
      assert changeset.valid?
    end

    test "always returns valid changeset" do
      # Since there are no fields to cast or validate, the changeset should always be valid
      changeset = ListWallets.changeset(%ListWallets{}, %{})
      assert changeset.valid?
      assert changeset.errors == []
    end

    test "applies changes correctly" do
      changeset = ListWallets.changeset(%ListWallets{}, %{})
      assert changeset.valid?

      # Even though no fields are cast, the changeset should work with apply_action
      assert {:ok, %ListWallets{}} = Changeset.apply_action(changeset, :listwallets)
    end

    test "maintains method field value" do
      changeset = ListWallets.changeset(%ListWallets{}, %{})
      {:ok, result} = Changeset.apply_action(changeset, :listwallets)
      assert result.method == "listwallets"
    end
  end

  ## ListWallets RPC

  ## ListWallets

  describe "list_wallets/2" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns array of wallet names", %{client: client} do
      wallet_names = ["wallet1", "wallet2", "test_wallet"]

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the method body structure
          assert %{
                   "method" => "listwallets",
                   "params" => [],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          # Should have auto-generated ID
          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => wallet_names,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.list_wallets(client)
      assert result == wallet_names
      assert length(result) == 3
    end

    test "returns empty array when no wallets are loaded", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request structure
          assert %{
                   "method" => "listwallets",
                   "params" => [],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => [],
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.list_wallets(client)
      assert result == []
    end

    test "call with custom ID", %{client: client} do
      custom_id = "list-wallets-#{System.system_time()}"
      wallet_names = ["main_wallet"]

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify custom ID is used
          assert %{
                   "method" => "listwallets",
                   "params" => [],
                   "jsonrpc" => "1.0",
                   "id" => ^custom_id
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => custom_id,
              "result" => wallet_names,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.list_wallets(client, id: custom_id)
      assert result == wallet_names
    end

    test "returns single wallet in array", %{client: client} do
      single_wallet = ["default"]

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => single_wallet,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.list_wallets(client)
      assert result == single_wallet
      assert length(result) == 1
    end

    test "handles Bitcoin Core RPC errors", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -32_601,
                "message" => "Method not found"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -32_601, message: message}} =
               Wallets.list_wallets(client)

      assert message == "Method not found"
    end

    test "handles network/connection errors", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert {:error, %BTx.RPC.Error{reason: {:rpc, :unauthorized}}} =
               Wallets.list_wallets(client)
    end

    test "handles service unavailable", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 503, body: "Service Unavailable"}
      end)

      assert {:error, %BTx.RPC.Error{reason: {:rpc, :service_unavailable}}} =
               Wallets.list_wallets(client)
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.list_wallets!(client)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client()

      assert {:ok, wallets} = Wallets.list_wallets(real_client)
      assert is_list(wallets)
    end
  end

  describe "list_wallets!/2" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns array of wallet names", %{client: client} do
      wallet_names = ["wallet1", "wallet2"]

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => wallet_names,
              "error" => nil
            }
          }
      end)

      assert result = Wallets.list_wallets!(client)
      assert result == wallet_names
    end

    test "returns empty array", %{client: client} do
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

      assert result = Wallets.list_wallets!(client)
      assert result == []
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.list_wallets!(client)
      end
    end
  end
end
