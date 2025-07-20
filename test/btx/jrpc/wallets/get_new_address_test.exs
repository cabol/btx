defmodule BTx.JRPC.Wallets.GetNewAddressTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils

  alias BTx.JRPC.{Encodable, Request}
  alias BTx.JRPC.Wallets.GetNewAddress
  alias Ecto.Changeset

  describe "new/1" do
    test "creates a new method with default values" do
      assert {:ok, %GetNewAddress{label: "", address_type: "bech32"}} = GetNewAddress.new()
    end

    test "creates a new method with empty map" do
      assert {:ok, %GetNewAddress{label: "", address_type: "bech32"}} = GetNewAddress.new(%{})
    end

    test "creates a new method with custom label" do
      assert {:ok, %GetNewAddress{label: "test_label", address_type: "bech32"}} =
               GetNewAddress.new(label: "test_label")
    end

    test "creates a new method with custom address_type" do
      assert {:ok, %GetNewAddress{label: "", address_type: "legacy"}} =
               GetNewAddress.new(address_type: "legacy")
    end

    test "creates a new method with both parameters" do
      assert {:ok, %GetNewAddress{label: "savings", address_type: "bech32m"}} =
               GetNewAddress.new(label: "savings", address_type: "bech32m")
    end

    test "uses defaults when parameters are not provided" do
      assert {:ok, %GetNewAddress{label: "", address_type: "bech32"}} = GetNewAddress.new(%{})
    end

    test "accepts all valid address types" do
      valid_types = ["legacy", "p2sh-segwit", "bech32", "bech32m"]

      for address_type <- valid_types do
        assert {:ok, %GetNewAddress{address_type: ^address_type}} =
                 GetNewAddress.new(address_type: address_type)
      end
    end

    test "accepts valid labels" do
      valid_labels = [
        "simple",
        "label with spaces",
        "label-with-dashes",
        "label_with_underscores",
        "label123",
        "Exchange Deposit #123",
        # maximum length
        String.duplicate("a", 255)
      ]

      for label <- valid_labels do
        assert {:ok, %GetNewAddress{label: ^label}} =
                 GetNewAddress.new(label: label)
      end
    end

    test "returns error for invalid address type" do
      assert {:error, %Changeset{errors: errors}} =
               GetNewAddress.new(address_type: "invalid_type")

      assert Keyword.fetch!(errors, :address_type) ==
               {"is invalid",
                [
                  {:validation, :inclusion},
                  {:enum, ["legacy", "p2sh-segwit", "bech32", "bech32m"]}
                ]}
    end

    test "returns error for label too long" do
      long_label = String.duplicate("a", 256)

      assert {:error, %Changeset{errors: errors}} =
               GetNewAddress.new(label: long_label)

      assert Keyword.fetch!(errors, :label) ==
               {"should be at most %{count} character(s)",
                [{:count, 255}, {:validation, :length}, {:kind, :max}, {:type, :string}]}
    end

    test "accepts empty string as label" do
      assert {:ok, %GetNewAddress{label: ""}} = GetNewAddress.new(label: "")
    end

    test "works with keyword list input" do
      assert {:ok, %GetNewAddress{label: "test", address_type: "legacy"}} =
               GetNewAddress.new(label: "test", address_type: "legacy")
    end

    test "works with map input" do
      assert {:ok, %GetNewAddress{label: "test", address_type: "legacy"}} =
               GetNewAddress.new(%{label: "test", address_type: "legacy"})
    end
  end

  describe "new!/1" do
    test "creates a new method with default values" do
      assert %GetNewAddress{label: "", address_type: "bech32"} = GetNewAddress.new!()
    end

    test "creates a new method with custom parameters" do
      assert %GetNewAddress{label: "test", address_type: "legacy"} =
               GetNewAddress.new!(label: "test", address_type: "legacy")
    end

    test "raises error for invalid address type" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetNewAddress.new!(address_type: "invalid_type")
      end
    end

    test "raises error for label too long" do
      long_label = String.duplicate("a", 256)

      assert_raise Ecto.InvalidChangesetError, fn ->
        GetNewAddress.new!(label: long_label)
      end
    end
  end

  describe "encodable" do
    test "encodes method with default values" do
      assert %Request{
               params: ["", "bech32"],
               method: "getnewaddress",
               jsonrpc: "1.0",
               path: "/"
             } = GetNewAddress.new!() |> Encodable.encode()
    end

    test "encodes method with custom label only" do
      assert %Request{
               params: ["test_label", "bech32"],
               method: "getnewaddress",
               jsonrpc: "1.0",
               path: "/"
             } = GetNewAddress.new!(label: "test_label") |> Encodable.encode()
    end

    test "encodes method with custom address_type only" do
      assert %Request{
               params: ["", "legacy"],
               method: "getnewaddress",
               jsonrpc: "1.0",
               path: "/"
             } = GetNewAddress.new!(address_type: "legacy") |> Encodable.encode()
    end

    test "encodes method with both custom parameters" do
      assert %Request{
        params: ["savings", "bech32m"],
        method: "getnewaddress",
        jsonrpc: "1.0",
        path: "/"
      }
    end

    test "encodes method with empty label and custom address_type" do
      assert %Request{
        params: ["", "legacy"],
        method: "getnewaddress",
        jsonrpc: "1.0",
        path: "/"
      }
    end

    test "encodes all valid address types correctly" do
      address_types = ["legacy", "p2sh-segwit", "bech32", "bech32m"]

      for address_type <- address_types do
        encoded =
          GetNewAddress.new!(label: "test", address_type: address_type)
          |> Encodable.encode()

        assert encoded.params == ["test", address_type]
        assert encoded.method == "getnewaddress"
      end
    end
  end

  describe "changeset/2" do
    test "validates label length" do
      # Valid length
      valid_label = String.duplicate("a", 255)
      changeset = GetNewAddress.changeset(%GetNewAddress{}, %{label: valid_label})
      assert changeset.valid?

      # Too long
      long_label = String.duplicate("a", 256)
      changeset = GetNewAddress.changeset(%GetNewAddress{}, %{label: long_label})
      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).label
    end

    test "validates address_type inclusion" do
      # Valid types
      for address_type <- ["legacy", "p2sh-segwit", "bech32", "bech32m"] do
        changeset = GetNewAddress.changeset(%GetNewAddress{}, %{address_type: address_type})
        assert changeset.valid?
      end

      # Invalid type
      changeset = GetNewAddress.changeset(%GetNewAddress{}, %{address_type: "invalid"})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).address_type
    end

    test "accepts empty parameters" do
      changeset = GetNewAddress.changeset(%GetNewAddress{}, %{})
      assert changeset.valid?
    end

    test "uses schema defaults when fields are omitted" do
      changeset = GetNewAddress.changeset(%GetNewAddress{}, %{})
      assert changeset.valid?

      # Test that defaults work when fields are omitted entirely
      {:ok, result} = GetNewAddress.new(%{})
      assert result.label == ""
      assert result.address_type == "bech32"
    end

    test "accepts nil values without validation errors" do
      # Nil values should be accepted (they just don't trigger defaults)
      changeset =
        GetNewAddress.changeset(%GetNewAddress{}, %{
          label: nil,
          address_type: nil
        })

      assert changeset.valid?
    end

    test "accepts empty string label" do
      changeset = GetNewAddress.changeset(%GetNewAddress{}, %{label: ""})
      assert changeset.valid?
    end

    test "applies changes correctly" do
      changeset =
        GetNewAddress.changeset(%GetNewAddress{}, %{
          label: "test_label",
          # Use non-default value
          address_type: "legacy"
        })

      assert changeset.valid?
      assert Changeset.get_change(changeset, :label) == "test_label"
      assert Changeset.get_change(changeset, :address_type) == "legacy"
    end
  end
end
