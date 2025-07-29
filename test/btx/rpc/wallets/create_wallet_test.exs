defmodule BTx.RPC.Wallets.CreateWalletTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.{CreateWallet, CreateWalletResult}
  alias Ecto.{Changeset, UUID}

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a new wallet with required fields" do
      assert {:ok,
              %CreateWallet{
                wallet_name: "test_wallet",
                passphrase: "test_pass",
                disable_private_keys: false,
                blank: false,
                avoid_reuse: false,
                descriptors: false,
                load_on_startup: nil
              }} = CreateWallet.new(wallet_name: "test_wallet", passphrase: "test_pass")
    end

    test "creates a new wallet with all options" do
      assert {:ok,
              %CreateWallet{
                wallet_name: "advanced_wallet",
                passphrase: "secure_pass123",
                disable_private_keys: true,
                blank: true,
                avoid_reuse: true,
                descriptors: true,
                load_on_startup: false
              }} =
               CreateWallet.new(
                 wallet_name: "advanced_wallet",
                 passphrase: "secure_pass123",
                 disable_private_keys: true,
                 blank: true,
                 avoid_reuse: true,
                 descriptors: true,
                 load_on_startup: false
               )
    end

    test "uses default values for optional fields" do
      assert {:ok,
              %CreateWallet{
                disable_private_keys: false,
                blank: false,
                avoid_reuse: false,
                descriptors: false,
                load_on_startup: nil
              }} = CreateWallet.new(wallet_name: "test_wallet", passphrase: "test_pass")
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
        assert {:ok, %CreateWallet{wallet_name: ^name}} =
                 CreateWallet.new(wallet_name: name, passphrase: "test_pass")
      end
    end

    test "accepts valid passphrases" do
      valid_passphrases = [
        # minimum length
        "a",
        "simple_pass",
        "complex!@#$%^&*()pass123",
        # maximum length
        String.duplicate("a", 1024)
      ]

      for passphrase <- valid_passphrases do
        assert {:ok, %CreateWallet{passphrase: ^passphrase}} =
                 CreateWallet.new(wallet_name: "test_wallet", passphrase: passphrase)
      end
    end

    test "accepts all valid load_on_startup values" do
      for value <- [true, false, nil] do
        assert {:ok, %CreateWallet{load_on_startup: ^value}} =
                 CreateWallet.new(
                   wallet_name: "test_wallet",
                   passphrase: "test_pass",
                   load_on_startup: value
                 )
      end
    end

    test "returns error for missing wallet_name" do
      assert {:error, %Changeset{errors: errors}} =
               CreateWallet.new(passphrase: "test_pass")

      assert Keyword.fetch!(errors, :wallet_name) ==
               {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for both missing required fields" do
      assert {:error, %Changeset{errors: errors}} = CreateWallet.new(%{})

      assert Keyword.fetch!(errors, :wallet_name) ==
               {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for invalid wallet name format" do
      invalid_names = [
        "invalid%#",
        "wallet with spaces",
        "wallet@example.com",
        "wallet.name",
        "wallet/path",
        "wallet\\path"
      ]

      for name <- invalid_names do
        assert {:error, %Changeset{errors: errors}} =
                 CreateWallet.new(wallet_name: name, passphrase: "test_pass")

        assert Keyword.fetch!(errors, :wallet_name) ==
                 {"has invalid format", [{:validation, :format}]}
      end
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               CreateWallet.new(wallet_name: long_name, passphrase: "test_pass")

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "returns error for empty wallet name" do
      assert {:error, %Changeset{errors: errors}} =
               CreateWallet.new(wallet_name: "", passphrase: "test_pass")

      assert Keyword.fetch!(errors, :wallet_name) ==
               {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for passphrase too long" do
      long_passphrase = String.duplicate("a", 1025)

      assert {:error, %Changeset{} = changeset} =
               CreateWallet.new(wallet_name: "test_wallet", passphrase: long_passphrase)

      assert "should be at most 1024 character(s)" in errors_on(changeset).passphrase
    end

    test "returns multiple errors for multiple invalid fields" do
      assert {:error, %Changeset{errors: errors}} =
               CreateWallet.new(wallet_name: "invalid%#", passphrase: "")

      assert Keyword.fetch!(errors, :wallet_name) ==
               {"has invalid format", [{:validation, :format}]}
    end
  end

  describe "new!/1" do
    test "creates a new wallet with required fields" do
      assert %CreateWallet{wallet_name: "test_wallet", passphrase: "test_pass"} =
               CreateWallet.new!(wallet_name: "test_wallet", passphrase: "test_pass")
    end

    test "creates a new wallet with all options" do
      assert %CreateWallet{
               wallet_name: "advanced_wallet",
               disable_private_keys: true,
               descriptors: true
             } =
               CreateWallet.new!(
                 wallet_name: "advanced_wallet",
                 passphrase: "secure_pass",
                 disable_private_keys: true,
                 descriptors: true
               )
    end

    test "raises error for invalid wallet name" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        CreateWallet.new!(wallet_name: "invalid%#", passphrase: "test_pass")
      end
    end

    test "raises error for missing required fields" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        CreateWallet.new!([])
      end
    end

    test "raises error for multiple validation failures" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        CreateWallet.new!(wallet_name: "invalid%#", passphrase: "")
      end
    end
  end

  describe "encodable" do
    test "encodes method with default options" do
      assert %Request{
               params: ["test_wallet", false, false, "test_pass", false, false, nil],
               method: "createwallet",
               jsonrpc: "1.0"
             } =
               CreateWallet.new!(wallet_name: "test_wallet", passphrase: "test_pass")
               |> Encodable.encode()
    end

    test "encodes method with all options enabled" do
      assert %Request{
               params: ["advanced_wallet", true, true, "secure_pass", true, true, true],
               method: "createwallet",
               jsonrpc: "1.0"
             } =
               CreateWallet.new!(
                 wallet_name: "advanced_wallet",
                 passphrase: "secure_pass",
                 disable_private_keys: true,
                 blank: true,
                 avoid_reuse: true,
                 descriptors: true,
                 load_on_startup: true
               )
               |> Encodable.encode()
    end

    test "encodes method with mixed options" do
      assert %Request{
               params: ["mixed_wallet", false, true, "mixed_pass", false, true, false],
               method: "createwallet",
               jsonrpc: "1.0"
             } =
               CreateWallet.new!(
                 wallet_name: "mixed_wallet",
                 passphrase: "mixed_pass",
                 disable_private_keys: false,
                 blank: true,
                 avoid_reuse: false,
                 descriptors: true,
                 load_on_startup: false
               )
               |> Encodable.encode()
    end

    test "encodes method with load_on_startup as nil" do
      assert %Request{
               params: ["nil_startup_wallet", false, false, "nil_pass", false, false, nil],
               method: "createwallet",
               jsonrpc: "1.0"
             } =
               CreateWallet.new!(
                 wallet_name: "nil_startup_wallet",
                 passphrase: "nil_pass",
                 load_on_startup: nil
               )
               |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = CreateWallet.changeset(%CreateWallet{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).wallet_name
    end

    test "validates wallet name format" do
      changeset =
        CreateWallet.changeset(%CreateWallet{}, %{
          wallet_name: "invalid%#",
          passphrase: "test_pass"
        })

      refute changeset.valid?
      assert "has invalid format" in errors_on(changeset).wallet_name
    end

    test "validates wallet name length" do
      # Too long
      long_name = String.duplicate("a", 65)

      changeset =
        CreateWallet.changeset(%CreateWallet{}, %{
          wallet_name: long_name,
          passphrase: "test_pass"
        })

      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name

      # Valid length
      valid_name = String.duplicate("a", 64)

      changeset =
        CreateWallet.changeset(%CreateWallet{}, %{
          wallet_name: valid_name,
          passphrase: "test_pass"
        })

      assert changeset.valid?
    end

    test "validates passphrase length" do
      # Too long
      long_passphrase = String.duplicate("a", 1025)

      changeset =
        CreateWallet.changeset(%CreateWallet{}, %{
          wallet_name: "test_wallet",
          passphrase: long_passphrase
        })

      refute changeset.valid?
      assert "should be at most 1024 character(s)" in errors_on(changeset).passphrase

      # Valid length
      valid_passphrase = String.duplicate("a", 1024)

      changeset =
        CreateWallet.changeset(%CreateWallet{}, %{
          wallet_name: "test_wallet",
          passphrase: valid_passphrase
        })

      assert changeset.valid?
    end

    test "accepts valid boolean values for optional fields" do
      changeset =
        CreateWallet.changeset(%CreateWallet{}, %{
          wallet_name: "test_wallet",
          passphrase: "test_pass",
          disable_private_keys: true,
          blank: true,
          avoid_reuse: true,
          descriptors: true
        })

      assert changeset.valid?
      assert Changeset.get_change(changeset, :disable_private_keys) == true
      assert Changeset.get_change(changeset, :blank) == true
      assert Changeset.get_change(changeset, :avoid_reuse) == true
      assert Changeset.get_change(changeset, :descriptors) == true
    end

    test "accepts valid load_on_startup enum values" do
      for value <- [true, false, nil] do
        changeset =
          CreateWallet.changeset(%CreateWallet{}, %{
            wallet_name: "test_wallet",
            passphrase: "test_pass",
            load_on_startup: value
          })

        assert changeset.valid?
        assert Changeset.get_change(changeset, :load_on_startup) == value
      end
    end
  end

  ## CreateWallet RPC

  describe "(RPC) Wallets.create_wallet/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful wallet creation returns wallet info", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the method body structure
          assert %{
                   "method" => "createwallet",
                   "params" => ["test_wallet", false, false, "secure_pass", false, true, nil],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          # Should have auto-generated ID
          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => %{
                "name" => "test_wallet",
                "warning" => ""
              },
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.create_wallet(client,
                 wallet_name: "test_wallet",
                 passphrase: "secure_pass",
                 descriptors: true
               )

      assert result.name == "test_wallet"
      refute result.warning
    end

    test "creates a wallet with custom ID", %{client: client} do
      custom_id = "create-wallet-#{System.system_time()}"

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify custom ID is used
          assert %{
                   "method" => "createwallet",
                   "params" => ["custom_id_wallet", false, false, "test_pass", false, false, nil],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => custom_id,
              "result" => %{
                "name" => "custom_id_wallet",
                "warning" => ""
              },
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.create_wallet(client,
                 id: custom_id,
                 wallet_name: "custom_id_wallet",
                 passphrase: "test_pass"
               )

      assert result.name == "custom_id_wallet"
    end

    test "call with all options enabled", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          body = BTx.json_module().decode!(body)

          # Verify all options are encoded correctly
          assert %{
                   "method" => "createwallet",
                   "params" => ["feature_wallet", true, true, "complex_pass", true, true, false],
                   "jsonrpc" => "1.0"
                 } = body

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => body["id"],
              "result" => %{
                "name" => "feature_wallet",
                "warning" => "Empty wallet"
              },
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.create_wallet(client,
                 wallet_name: "feature_wallet",
                 passphrase: "complex_pass",
                 disable_private_keys: true,
                 blank: true,
                 avoid_reuse: true,
                 descriptors: true,
                 load_on_startup: false
               )

      assert result.name == "feature_wallet"
    end

    test "handles wallet already exists error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -4,
                "message" => "Wallet existing_wallet already exists."
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{id: "test-id", code: -4, message: message}} =
               Wallets.create_wallet(client,
                 wallet_name: "existing_wallet",
                 passphrase: "test_pass"
               )

      assert message =~ "already exists"
    end

    test "handles invalid wallet name error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -8,
                "message" => "Invalid parameter, wallet name contains invalid characters"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -8, message: message}} =
               Wallets.create_wallet(client, wallet_name: "test_wallet", passphrase: "test_pass")

      assert message =~ "invalid characters"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.create_wallet!(client, wallet_name: "error_wallet", passphrase: "test_pass")
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      client = new_client()
      wallet_name = "integration-test-#{UUID.generate()}"

      params = [wallet_name: wallet_name, passphrase: "test_pass", descriptors: true]

      assert Wallets.create_wallet!(client, params, id: wallet_name, retries: 10) ==
               CreateWalletResult.new!(%{name: wallet_name})

      assert_raise BTx.RPC.MethodError, ~r/already exists/, fn ->
        Wallets.create_wallet!(client, params)
      end
    end
  end

  describe "(RPC) Wallets.create_wallet!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "creates a wallet", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{
                "name" => "test_wallet",
                "warning" => ""
              },
              "error" => nil
            }
          }
      end)

      assert r = Wallets.create_wallet!(client, wallet_name: "test_wallet", passphrase: "pass")
      assert r.name == "test_wallet"
      refute r.warning
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.create_wallet!(client, wallet_name: "error_wallet", passphrase: "test_pass")
      end
    end
  end
end
