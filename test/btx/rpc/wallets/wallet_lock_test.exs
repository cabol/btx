defmodule BTx.RPC.Wallets.WalletLockTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.WalletLock
  alias Ecto.{Changeset, UUID}

  @url "http://localhost:18443/"

  ## Schema tests

  describe "WalletLock.new/1" do
    test "creates a new WalletLock with no parameters" do
      assert {:ok, %WalletLock{wallet_name: nil}} = WalletLock.new(%{})
    end

    test "creates a new WalletLock with wallet name" do
      assert {:ok, %WalletLock{wallet_name: "my_wallet"}} =
               WalletLock.new(wallet_name: "my_wallet")
    end

    test "accepts various wallet names" do
      valid_names = [
        "simple",
        "wallet123",
        "my-wallet",
        "my_wallet",
        "wallet_with_underscores",
        "wallet-with-dashes",
        # minimum length
        "a",
        # maximum length
        String.duplicate("a", 64)
      ]

      for name <- valid_names do
        assert {:ok, %WalletLock{wallet_name: ^name}} =
                 WalletLock.new(wallet_name: name)
      end
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               WalletLock.new(wallet_name: long_name)

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "accepts empty string wallet name as nil" do
      assert {:ok, %WalletLock{wallet_name: nil}} =
               WalletLock.new(wallet_name: "")
    end

    test "accepts keyword list parameters" do
      assert {:ok, %WalletLock{wallet_name: "test_wallet"}} =
               WalletLock.new(wallet_name: "test_wallet")
    end

    test "accepts map parameters" do
      assert {:ok, %WalletLock{wallet_name: "test_wallet"}} =
               WalletLock.new(%{wallet_name: "test_wallet"})
    end
  end

  describe "WalletLock.new!/1" do
    test "creates a new WalletLock with no parameters" do
      assert %WalletLock{wallet_name: nil} = WalletLock.new!(%{})
    end

    test "creates a new WalletLock with wallet name" do
      assert %WalletLock{wallet_name: "my_wallet"} =
               WalletLock.new!(wallet_name: "my_wallet")
    end

    test "raises error for invalid wallet name" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        WalletLock.new!(wallet_name: String.duplicate("a", 65))
      end
    end

    test "accepts empty parameters" do
      assert %WalletLock{} = WalletLock.new!([])
    end
  end

  describe "WalletLock encodable" do
    test "encodes method with no parameters" do
      assert %Request{
               params: [],
               method: "walletlock",
               jsonrpc: "1.0",
               path: "/"
             } = WalletLock.new!(%{}) |> Encodable.encode()
    end

    test "encodes method with wallet name" do
      assert %Request{
               params: [],
               method: "walletlock",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               WalletLock.new!(wallet_name: "my_wallet")
               |> Encodable.encode()
    end

    test "encodes method with complex wallet name" do
      wallet_name = "production_wallet_2024"

      assert %Request{
               params: [],
               method: "walletlock",
               jsonrpc: "1.0",
               path: "/wallet/production_wallet_2024"
             } =
               WalletLock.new!(wallet_name: wallet_name)
               |> Encodable.encode()
    end
  end

  describe "WalletLock changeset/2" do
    test "validates wallet name length" do
      # Too long
      long_name = String.duplicate("a", 65)

      changeset = WalletLock.changeset(%WalletLock{}, %{wallet_name: long_name})

      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name

      # Valid length
      valid_name = String.duplicate("a", 64)

      changeset = WalletLock.changeset(%WalletLock{}, %{wallet_name: valid_name})

      assert changeset.valid?
    end

    test "accepts no parameters" do
      changeset = WalletLock.changeset(%WalletLock{}, %{})
      assert changeset.valid?
    end

    test "accepts valid wallet name" do
      changeset = WalletLock.changeset(%WalletLock{}, %{wallet_name: "test_wallet"})

      assert changeset.valid?
      assert Changeset.get_change(changeset, :wallet_name) == "test_wallet"
    end
  end

  ## WalletLock RPC tests

  describe "(RPC) Wallets.wallet_lock/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns nil", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "walletlock",
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
              "result" => nil,
              "error" => nil
            }
          }
      end)

      assert {:ok, nil} = Wallets.wallet_lock(client)
    end

    test "call with default parameters", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "walletlock",
                   "params" => [],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => nil
            }
          }
      end)

      assert {:ok, nil} = Wallets.wallet_lock(client, [])
    end

    test "call with wallet name", %{client: client} do
      url = Path.join(@url, "/wallet/my_wallet")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "walletlock",
                   "params" => [],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => nil
            }
          }
      end)

      assert {:ok, nil} = Wallets.wallet_lock(client, wallet_name: "my_wallet")
    end

    test "handles wallet not encrypted error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -15,
                "message" => "Error: running with an unencrypted wallet, but walletlock was called."
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -15, message: message}} =
               Wallets.wallet_lock(client)

      assert message =~ "unencrypted wallet"
    end

    test "handles wallet already locked error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -13,
                "message" => "Error: Wallet is already locked"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -13, message: message}} =
               Wallets.wallet_lock(client)

      assert message =~ "already locked"
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
               Wallets.wallet_lock(client, wallet_name: "nonexistent")

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.wallet_lock!(client)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node with an encrypted wallet
      real_client = new_client()

      # Create an encrypted wallet
      wallet_name = "wallet-lock-test-#{UUID.generate()}"

      # Create wallet with passphrase (encrypted)
      %BTx.RPC.Wallets.CreateWalletResult{name: ^wallet_name} =
        Wallets.create_wallet!(
          real_client,
          wallet_name: wallet_name,
          passphrase: "test_passphrase_123"
        )

      # The wallet should be encrypted and locked by default
      # First unlock it
      assert {:ok, nil} =
               Wallets.wallet_passphrase(real_client,
                 passphrase: "test_passphrase_123",
                 timeout: 60,
                 wallet_name: wallet_name
               )

      # Now lock it again
      assert {:ok, nil} =
               Wallets.wallet_lock(real_client, wallet_name: wallet_name)

      # Try to lock an unencrypted wallet (should fail)
      unencrypted_wallet_name = "unencrypted-wallet-#{UUID.generate()}"

      %BTx.RPC.Wallets.CreateWalletResult{name: ^unencrypted_wallet_name} =
        Wallets.create_wallet!(
          real_client,
          wallet_name: unencrypted_wallet_name
          # No passphrase = unencrypted
        )

      # This should fail since the wallet is not encrypted
      assert {:error, %BTx.RPC.MethodError{code: -15}} =
               Wallets.wallet_lock(real_client, wallet_name: unencrypted_wallet_name)
    end
  end

  describe "(RPC) Wallets.wallet_lock!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns nil on success", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => nil
            }
          }
      end)

      assert nil == Wallets.wallet_lock!(client)
    end

    test "returns nil on success with wallet name", %{client: client} do
      url = Path.join(@url, "/wallet/my_wallet")

      mock(fn
        %{method: :post, url: ^url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => nil
            }
          }
      end)

      assert nil == Wallets.wallet_lock!(client, wallet_name: "my_wallet")
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.wallet_lock!(client, wallet_name: String.duplicate("a", 65))
      end
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.wallet_lock!(client)
      end
    end

    test "raises on unencrypted wallet", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -15,
                "message" => "Error: running with an unencrypted wallet, but walletlock was called."
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, ~r/unencrypted wallet/, fn ->
        Wallets.wallet_lock!(client)
      end
    end

    test "raises on wallet already locked", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -13,
                "message" => "Error: Wallet is already locked"
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, ~r/already locked/, fn ->
        Wallets.wallet_lock!(client)
      end
    end
  end
end
