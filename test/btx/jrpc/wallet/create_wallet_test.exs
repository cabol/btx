defmodule BTx.JRPC.Wallet.CreateWalletTest do
  use ExUnit.Case, async: true

  alias BTx.JRPC.Encodable
  alias BTx.JRPC.Wallet.CreateWallet
  alias Ecto.Changeset

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

    test "returns error for missing passphrase" do
      assert {:error, %Changeset{errors: errors}} =
               CreateWallet.new(wallet_name: "test_wallet")

      assert Keyword.fetch!(errors, :passphrase) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for both missing required fields" do
      assert {:error, %Changeset{errors: errors}} = CreateWallet.new(%{})

      assert Keyword.fetch!(errors, :wallet_name) ==
               {"can't be blank", [{:validation, :required}]}

      assert Keyword.fetch!(errors, :passphrase) == {"can't be blank", [{:validation, :required}]}
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

    test "returns error for empty passphrase" do
      assert {:error, %Changeset{errors: errors}} =
               CreateWallet.new(wallet_name: "test_wallet", passphrase: "")

      assert Keyword.fetch!(errors, :passphrase) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns multiple errors for multiple invalid fields" do
      assert {:error, %Changeset{errors: errors}} =
               CreateWallet.new(wallet_name: "invalid%#", passphrase: "")

      assert Keyword.fetch!(errors, :wallet_name) ==
               {"has invalid format", [{:validation, :format}]}

      assert Keyword.fetch!(errors, :passphrase) == {"can't be blank", [{:validation, :required}]}
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
        CreateWallet.new!(wallet_name: "test_wallet")
      end

      assert_raise Ecto.InvalidChangesetError, fn ->
        CreateWallet.new!(passphrase: "test_pass")
      end
    end

    test "raises error for multiple validation failures" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        CreateWallet.new!(wallet_name: "invalid%#", passphrase: "")
      end
    end
  end

  describe "encodable" do
    test "encodes request with default options" do
      assert CreateWallet.new!(wallet_name: "test_wallet", passphrase: "test_pass")
             |> Encodable.encode()
             |> Map.drop([:id]) == %{
               params: ["test_wallet", false, false, "test_pass", false, false, nil],
               method: "createwallet",
               jsonrpc: "1.0"
             }
    end

    test "encodes request with all options enabled" do
      assert CreateWallet.new!(
               wallet_name: "advanced_wallet",
               passphrase: "secure_pass",
               disable_private_keys: true,
               blank: true,
               avoid_reuse: true,
               descriptors: true,
               load_on_startup: true
             )
             |> Encodable.encode()
             |> Map.drop([:id]) == %{
               params: ["advanced_wallet", true, true, "secure_pass", true, true, true],
               method: "createwallet",
               jsonrpc: "1.0"
             }
    end

    test "encodes request with mixed options" do
      assert CreateWallet.new!(
               wallet_name: "mixed_wallet",
               passphrase: "mixed_pass",
               disable_private_keys: false,
               blank: true,
               avoid_reuse: false,
               descriptors: true,
               load_on_startup: false
             )
             |> Encodable.encode()
             |> Map.drop([:id]) == %{
               params: ["mixed_wallet", false, true, "mixed_pass", false, true, false],
               method: "createwallet",
               jsonrpc: "1.0"
             }
    end

    test "encodes request with load_on_startup as nil" do
      assert CreateWallet.new!(
               wallet_name: "nil_startup_wallet",
               passphrase: "nil_pass",
               load_on_startup: nil
             )
             |> Encodable.encode()
             |> Map.drop([:id]) == %{
               params: ["nil_startup_wallet", false, false, "nil_pass", false, false, nil],
               method: "createwallet",
               jsonrpc: "1.0"
             }
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = CreateWallet.changeset(%CreateWallet{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).wallet_name
      assert "can't be blank" in errors_on(changeset).passphrase
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

  # Helper function for testing changeset errors
  defp errors_on(changeset) do
    Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
