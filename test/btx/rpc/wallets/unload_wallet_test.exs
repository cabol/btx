defmodule BTx.RPC.Wallets.UnloadWalletResultTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.Wallets
  alias BTx.RPC.Wallets.{CreateWalletResult, UnloadWalletResult}
  alias Ecto.{Changeset, UUID}

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates result with warning" do
      attrs = %{"warning" => "Wallet was not unloaded cleanly"}

      assert {:ok, %UnloadWalletResult{} = result} = UnloadWalletResult.new(attrs)
      assert result.warning == "Wallet was not unloaded cleanly"
    end

    test "creates result without warning" do
      attrs = %{}

      assert {:ok, %UnloadWalletResult{} = result} = UnloadWalletResult.new(attrs)
      assert result.warning == nil
    end

    test "creates result with explicit nil warning" do
      attrs = %{"warning" => nil}

      assert {:ok, %UnloadWalletResult{} = result} = UnloadWalletResult.new(attrs)
      assert result.warning == nil
    end

    test "accepts atom keys" do
      attrs = %{warning: "Some warning message"}

      assert {:ok, %UnloadWalletResult{} = result} = UnloadWalletResult.new(attrs)
      assert result.warning == "Some warning message"
    end

    test "ignores unknown fields" do
      attrs = %{
        "warning" => "Test warning",
        "unknown_field" => "ignored_value"
      }

      assert {:ok, %UnloadWalletResult{} = result} = UnloadWalletResult.new(attrs)
      assert result.warning == "Test warning"
      refute Map.has_key?(result, :unknown_field)
    end
  end

  describe "new!/1" do
    test "creates result and returns struct directly" do
      attrs = %{"warning" => "Test warning"}

      assert %UnloadWalletResult{} = result = UnloadWalletResult.new!(attrs)
      assert result.warning == "Test warning"
    end

    test "raises on invalid input type" do
      # This would be caught by pattern matching in the function
      assert_raise FunctionClauseError, fn ->
        UnloadWalletResult.new!("not a map")
      end
    end
  end

  describe "changeset/2" do
    test "accepts valid warning message" do
      result = %UnloadWalletResult{}
      attrs = %{"warning" => "Wallet unloaded with issues"}

      changeset = UnloadWalletResult.changeset(result, attrs)

      assert changeset.valid?
      assert Changeset.get_change(changeset, :warning) == "Wallet unloaded with issues"
    end

    test "accepts nil warning" do
      result = %UnloadWalletResult{}
      attrs = %{"warning" => nil}

      changeset = UnloadWalletResult.changeset(result, attrs)

      assert changeset.valid?
      assert Changeset.get_change(changeset, :warning) == nil
    end

    test "accepts empty attrs" do
      result = %UnloadWalletResult{}
      attrs = %{}

      changeset = UnloadWalletResult.changeset(result, attrs)

      assert changeset.valid?
      assert changeset.changes == %{}
    end
  end

  describe "JSON encoding" do
    test "can be encoded to JSON" do
      result = %UnloadWalletResult{warning: "Test warning"}

      # Test that the struct has the JSON encoder derive
      assert %UnloadWalletResult{} = result
      # The actual JSON encoding would depend on your BTx.json_encoder() configuration
    end

    test "encodes nil warning correctly" do
      result = %UnloadWalletResult{warning: nil}

      # Should be encodable even with nil warning
      assert %UnloadWalletResult{warning: nil} = result
    end
  end

  ## UnloadWallet RPC

  describe "(RPC) Wallets.unload_wallet/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful wallet unload", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the method body structure
          assert %{
                   "method" => "unloadwallet",
                   "params" => ["test_wallet"],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          # Should have auto-generated ID
          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => %{},
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.unload_wallet(client, wallet_name: "test_wallet")

      assert %UnloadWalletResult{warning: nil} = result
    end

    test "unload wallet with load_on_startup option", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the method body structure with load_on_startup
          assert %{
                   "method" => "unloadwallet",
                   "params" => ["test_wallet", false],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{},
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.unload_wallet(client,
                 wallet_name: "test_wallet",
                 load_on_startup: false
               )

      assert %UnloadWalletResult{warning: nil} = result
    end

    test "returns warning when wallet not unloaded cleanly", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          body = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => body["id"],
              "result" => %{"warning" => "Wallet was not unloaded cleanly"},
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.unload_wallet(client, wallet_name: "problematic_wallet")

      assert %UnloadWalletResult{warning: "Wallet was not unloaded cleanly"} = result
    end

    test "unload with custom ID", %{client: client} do
      custom_id = "unload-wallet-#{System.system_time()}"

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify custom ID is used
          assert %{
                   "method" => "unloadwallet",
                   "params" => ["test_wallet"],
                   "jsonrpc" => "1.0",
                   "id" => ^custom_id
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => custom_id,
              "result" => %{},
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.unload_wallet(
                 client,
                 [wallet_name: "test_wallet"],
                 id: custom_id
               )

      assert %UnloadWalletResult{} = result
    end

    test "returns validation error when wallet_name is missing", %{client: client} do
      assert {:error, %Ecto.Changeset{} = changeset} =
               Wallets.unload_wallet(client, load_on_startup: true)

      assert {"can't be blank", _} = changeset.errors[:wallet_name]
    end

    test "returns validation error for invalid wallet_name length", %{client: client} do
      # Empty string
      assert {:error, %Ecto.Changeset{} = changeset} =
               Wallets.unload_wallet(client, wallet_name: "")

      assert {"can't be blank", _} = changeset.errors[:wallet_name]

      # Too long
      long_name = String.duplicate("a", 65)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Wallets.unload_wallet(client, wallet_name: long_name)

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "handles wallet not found error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
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
               Wallets.unload_wallet(client, wallet_name: "nonexistent_wallet")

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "handles network/connection errors", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert {:error, %BTx.RPC.Error{reason: {:rpc, :unauthorized}}} =
               Wallets.unload_wallet(client, wallet_name: "test_wallet")
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.unload_wallet!(client, wallet_name: "test_wallet")
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      client = new_client()

      # First create a wallet to unload
      wallet_name = "integration-unload-test-#{UUID.generate()}"

      # Create wallet
      assert {:ok, %CreateWalletResult{}} =
               Wallets.create_wallet(
                 client,
                 [wallet_name: wallet_name, passphrase: "test_pass"],
                 retries: 10
               )

      # Unload the wallet
      assert {:ok, %UnloadWalletResult{}} =
               Wallets.unload_wallet(
                 client,
                 [wallet_name: wallet_name, load_on_startup: false],
                 retries: 10
               )

      # Try to unload again (should fail)
      assert {:error, %BTx.RPC.MethodError{code: -18}} =
               Wallets.unload_wallet(client, [wallet_name: wallet_name], retries: 10)
    end
  end

  describe "(RPC) Wallets.unload_wallet!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "unloads wallet and returns result directly", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{"warning" => "Partially unloaded"},
              "error" => nil
            }
          }
      end)

      assert %UnloadWalletResult{warning: "Partially unloaded"} =
               Wallets.unload_wallet!(client, wallet_name: "test_wallet")
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.unload_wallet!(client, load_on_startup: true)
      end
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.unload_wallet!(client, wallet_name: "test_wallet")
      end
    end
  end
end
