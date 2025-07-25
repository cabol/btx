defmodule BTx.RPC.Wallets.GetWalletInfoTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.{GetWalletInfo, GetWalletInfoResult}
  alias Ecto.{Changeset, UUID}

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a new GetWalletInfo with default values" do
      assert {:ok, %GetWalletInfo{method: "getwalletinfo", wallet_name: nil}} =
               GetWalletInfo.new()
    end

    test "creates a new GetWalletInfo with wallet_name" do
      assert {:ok, %GetWalletInfo{method: "getwalletinfo", wallet_name: "test_wallet"}} =
               GetWalletInfo.new(wallet_name: "test_wallet")
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
        assert {:ok, %GetWalletInfo{wallet_name: ^name}} =
                 GetWalletInfo.new(wallet_name: name)
      end
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               GetWalletInfo.new(wallet_name: long_name)

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "accepts empty string wallet name as nil" do
      assert {:ok, %GetWalletInfo{wallet_name: nil}} = GetWalletInfo.new(wallet_name: "")
    end
  end

  describe "new!/1" do
    test "creates a new GetWalletInfo with default values" do
      assert %GetWalletInfo{method: "getwalletinfo", wallet_name: nil} = GetWalletInfo.new!()
    end

    test "creates a new GetWalletInfo with wallet_name" do
      assert %GetWalletInfo{wallet_name: "test_wallet"} =
               GetWalletInfo.new!(wallet_name: "test_wallet")
    end

    test "raises error for invalid wallet name" do
      long_name = String.duplicate("a", 65)

      assert_raise Ecto.InvalidChangesetError, fn ->
        GetWalletInfo.new!(wallet_name: long_name)
      end
    end
  end

  describe "encodable" do
    test "encodes method with default values" do
      assert %Request{
               params: [],
               method: "getwalletinfo",
               jsonrpc: "1.0",
               path: "/"
             } = GetWalletInfo.new!() |> Encodable.encode()
    end

    test "encodes method with wallet name" do
      assert %Request{
               params: [],
               method: "getwalletinfo",
               jsonrpc: "1.0",
               path: "/wallet/test_wallet"
             } =
               GetWalletInfo.new!(wallet_name: "test_wallet") |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "accepts empty parameters" do
      changeset = GetWalletInfo.changeset(%GetWalletInfo{}, %{})
      assert changeset.valid?
    end

    test "validates wallet name length" do
      # Too long
      long_name = String.duplicate("a", 65)
      changeset = GetWalletInfo.changeset(%GetWalletInfo{}, %{wallet_name: long_name})
      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name

      # Valid length
      valid_name = String.duplicate("a", 64)
      changeset = GetWalletInfo.changeset(%GetWalletInfo{}, %{wallet_name: valid_name})
      assert changeset.valid?
    end
  end

  ## GetWalletInfoResult tests

  describe "GetWalletInfoResult.new/1" do
    test "creates result with required fields" do
      attrs = %{
        "walletname" => "test_wallet",
        "walletversion" => 169_900,
        "format" => "sqlite",
        "txcount" => 42,
        "keypoolsize" => 1000,
        "private_keys_enabled" => true,
        "avoid_reuse" => false,
        "descriptors" => true
      }

      assert {:ok, %GetWalletInfoResult{} = result} = GetWalletInfoResult.new(attrs)
      assert result.walletname == "test_wallet"
      assert result.walletversion == 169_900
      assert result.format == "sqlite"
      assert result.txcount == 42
      assert result.private_keys_enabled == true
      assert result.descriptors == true
    end

    test "creates result with all fields" do
      attrs = %{
        "walletname" => "full_wallet",
        "walletversion" => 169_900,
        "format" => "bdb",
        "balance" => 1.5,
        "unconfirmed_balance" => 0.1,
        "immature_balance" => 0.05,
        "txcount" => 100,
        "keypoololdest" => 1_640_995_200,
        "keypoolsize" => 1000,
        "keypoolsize_hd_internal" => 1000,
        "unlocked_until" => 1_640_995_800,
        "paytxfee" => 0.0001,
        "hdseedid" => "abc123def456",
        "private_keys_enabled" => true,
        "avoid_reuse" => true,
        "scanning" => %{"duration" => 120, "progress" => 0.75},
        "descriptors" => false
      }

      assert {:ok, %GetWalletInfoResult{} = result} = GetWalletInfoResult.new(attrs)
      assert result.balance == 1.5
      assert result.scanning == %{"duration" => 120, "progress" => 0.75}
      assert result.unlocked_until == 1_640_995_800
    end

    test "handles scanning as false" do
      attrs = %{
        "walletname" => "test_wallet",
        "walletversion" => 169_900,
        "format" => "sqlite",
        "txcount" => 0,
        "keypoolsize" => 1000,
        "private_keys_enabled" => true,
        "avoid_reuse" => false,
        "descriptors" => true,
        "scanning" => false
      }

      assert {:ok, %GetWalletInfoResult{} = result} = GetWalletInfoResult.new(attrs)
      assert result.scanning == false
    end

    test "validates required fields" do
      incomplete_attrs = %{
        "walletname" => "test_wallet"
        # Missing other required fields
      }

      assert {:error, %Changeset{errors: errors}} = GetWalletInfoResult.new(incomplete_attrs)
      assert Keyword.has_key?(errors, :walletversion)
      assert Keyword.has_key?(errors, :format)
    end

    test "validates format field" do
      attrs = %{
        "walletname" => "test_wallet",
        "walletversion" => 169_900,
        "format" => "invalid_format",
        "txcount" => 0,
        "keypoolsize" => 1000,
        "private_keys_enabled" => true,
        "avoid_reuse" => false,
        "descriptors" => true
      }

      assert {:error, %Changeset{} = changeset} = GetWalletInfoResult.new(attrs)
      assert "is invalid" in errors_on(changeset).format
    end

    test "validates scanning field structure" do
      # Invalid scanning value (not false or proper map)
      attrs = %{
        "walletname" => "test_wallet",
        "walletversion" => 169_900,
        "format" => "sqlite",
        "txcount" => 0,
        "keypoolsize" => 1000,
        "private_keys_enabled" => true,
        "avoid_reuse" => false,
        "descriptors" => true,
        # Invalid type
        "scanning" => "invalid_value"
      }

      assert {:error, %Changeset{} = changeset} = GetWalletInfoResult.new(attrs)
      assert "must be a map with scanning details or false" in errors_on(changeset).scanning

      # Invalid scanning map (missing required keys)
      # Missing progress
      attrs = %{attrs | "scanning" => %{"duration" => 120}}

      assert {:error, %Changeset{} = changeset} = GetWalletInfoResult.new(attrs)
      assert "must be a map with scanning details or false" in errors_on(changeset).scanning

      # Valid scanning values should pass
      valid_scanning_values = [
        false,
        %{"duration" => 120, "progress" => 0.75},
        %{"duration" => 0, "progress" => 1.0}
      ]

      for scanning_value <- valid_scanning_values do
        attrs = %{attrs | "scanning" => scanning_value}
        assert {:ok, _} = GetWalletInfoResult.new(attrs)
      end
    end
  end

  ## GetWalletInfo RPC

  describe "(RPC) Wallets.get_wallet_info/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns wallet info", %{client: client} do
      wallet_info = %{
        "walletname" => "test_wallet",
        "walletversion" => 169_900,
        "format" => "sqlite",
        "balance" => 1.5,
        "unconfirmed_balance" => 0.1,
        "immature_balance" => 0.0,
        "txcount" => 42,
        "keypoololdest" => 1_640_995_200,
        "keypoolsize" => 1000,
        "keypoolsize_hd_internal" => 1000,
        "paytxfee" => 0.0001,
        "private_keys_enabled" => true,
        "avoid_reuse" => false,
        "scanning" => false,
        "descriptors" => true
      }

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the method body structure
          assert %{
                   "method" => "getwalletinfo",
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
              "result" => wallet_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.get_wallet_info(client)
      assert %GetWalletInfoResult{} = result
      assert result.walletname == "test_wallet"
      assert result.balance == 1.5
      assert result.txcount == 42
      assert result.descriptors == true
    end

    test "call with specific wallet name", %{client: client} do
      url = Path.join(@url, "/wallet/my_wallet")

      wallet_info = %{
        "walletname" => "my_wallet",
        "walletversion" => 169_900,
        "format" => "bdb",
        "txcount" => 0,
        "keypoolsize" => 1000,
        "private_keys_enabled" => true,
        "avoid_reuse" => false,
        "scanning" => false,
        "descriptors" => false
      }

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "getwalletinfo",
                   "params" => [],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => wallet_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.get_wallet_info(client, wallet_name: "my_wallet")
      assert result.walletname == "my_wallet"
      assert result.format == "bdb"
      assert result.descriptors == false
    end

    test "handles encrypted wallet with unlock time", %{client: client} do
      wallet_info = %{
        "walletname" => "encrypted_wallet",
        "walletversion" => 169_900,
        "format" => "sqlite",
        "txcount" => 5,
        "keypoolsize" => 1000,
        "unlocked_until" => 1_640_995_800,
        "private_keys_enabled" => true,
        "avoid_reuse" => false,
        "scanning" => false,
        "descriptors" => true
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => wallet_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.get_wallet_info(client)
      assert result.unlocked_until == 1_640_995_800
    end

    test "handles wallet with active scanning", %{client: client} do
      wallet_info = %{
        "walletname" => "scanning_wallet",
        "walletversion" => 169_900,
        "format" => "sqlite",
        "txcount" => 10,
        "keypoolsize" => 1000,
        "private_keys_enabled" => true,
        "avoid_reuse" => false,
        "scanning" => %{
          "duration" => 300,
          "progress" => 0.65
        },
        "descriptors" => true
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => wallet_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.get_wallet_info(client)
      assert result.scanning == %{"duration" => 300, "progress" => 0.65}
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
               Wallets.get_wallet_info(client, wallet_name: "nonexistent")

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_wallet_info!(client)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client()

      # Create a unique wallet name
      wallet_name = "get-wallet-info-#{UUID.generate()}"

      # Create wallet
      %BTx.RPC.Wallets.CreateWalletResult{name: ^wallet_name} =
        Wallets.create_wallet!(
          real_client,
          wallet_name: wallet_name,
          passphrase: "test",
          avoid_reuse: true
        )

      assert {:ok, %GetWalletInfoResult{walletname: ^wallet_name}} =
               Wallets.get_wallet_info(real_client, wallet_name: wallet_name)
    end
  end

  describe "(RPC) Wallets.get_wallet_info!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns wallet info directly", %{client: client} do
      wallet_info = %{
        "walletname" => "test_wallet",
        "walletversion" => 169_900,
        "format" => "sqlite",
        "txcount" => 0,
        "keypoolsize" => 1000,
        "private_keys_enabled" => true,
        "avoid_reuse" => false,
        "scanning" => false,
        "descriptors" => true
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => wallet_info,
              "error" => nil
            }
          }
      end)

      assert %GetWalletInfoResult{walletname: "test_wallet"} =
               Wallets.get_wallet_info!(client)
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_wallet_info!(client)
      end
    end

    test "raises on invalid result data", %{client: client} do
      # Invalid result missing required fields
      invalid_info = %{
        "walletname" => "test_wallet"
        # Missing other required fields
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => invalid_info,
              "error" => nil
            }
          }
      end)

      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.get_wallet_info!(client)
      end
    end
  end
end
