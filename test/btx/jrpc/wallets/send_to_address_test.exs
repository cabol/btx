defmodule BTx.JRPC.Wallets.SendToAddressTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils

  alias BTx.JRPC.{Encodable, Request}
  alias BTx.JRPC.Wallets.SendToAddress
  alias Ecto.Changeset

  # Valid Bitcoin addresses for testing
  @valid_legacy_address "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
  @valid_p2sh_address "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
  @valid_bech32_address "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
  @valid_testnet_address "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx"
  @valid_regtest_address "bcrt1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"

  describe "new/1" do
    test "creates a SendToAddress with required fields" do
      assert {:ok, %SendToAddress{address: @valid_bech32_address, amount: 0.1}} =
               SendToAddress.new(address: @valid_bech32_address, amount: 0.1)
    end

    test "creates a SendToAddress with all parameters" do
      assert {:ok,
              %SendToAddress{
                address: @valid_bech32_address,
                amount: 0.05,
                comment: "Payment for services",
                comment_to: "Alice",
                subtract_fee_from_amount: true,
                replaceable: false,
                conf_target: 6,
                estimate_mode: "economical",
                avoid_reuse: false,
                fee_rate: 25.0,
                verbose: true,
                wallet_name: "my_wallet"
              }} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.05,
                 comment: "Payment for services",
                 comment_to: "Alice",
                 subtract_fee_from_amount: true,
                 replaceable: false,
                 conf_target: 6,
                 estimate_mode: "economical",
                 avoid_reuse: false,
                 fee_rate: 25.0,
                 verbose: true,
                 wallet_name: "my_wallet"
               )
    end

    test "uses default values for optional fields" do
      assert {:ok,
              %SendToAddress{
                subtract_fee_from_amount: false,
                estimate_mode: "unset",
                avoid_reuse: true,
                verbose: false
              }} = SendToAddress.new(address: @valid_bech32_address, amount: 0.1)
    end

    test "accepts valid Bitcoin address types" do
      valid_addresses = [
        @valid_legacy_address,
        @valid_p2sh_address,
        @valid_bech32_address,
        @valid_testnet_address,
        @valid_regtest_address
      ]

      for address <- valid_addresses do
        assert {:ok, %SendToAddress{address: ^address}} =
                 SendToAddress.new(address: address, amount: 0.1)
      end
    end

    test "accepts valid amounts" do
      valid_amounts = [0.00000001, 0.1, 1.0, 21.0, 21_000_000.0]

      for amount <- valid_amounts do
        assert {:ok, %SendToAddress{amount: ^amount}} =
                 SendToAddress.new(address: @valid_bech32_address, amount: amount)
      end
    end

    test "accepts valid estimate modes" do
      for estimate_mode <- ["unset", "economical", "conservative"] do
        assert {:ok, %SendToAddress{estimate_mode: ^estimate_mode}} =
                 SendToAddress.new(
                   address: @valid_bech32_address,
                   amount: 0.1,
                   estimate_mode: estimate_mode
                 )
      end
    end

    test "returns error for missing address" do
      assert {:error, %Changeset{errors: errors}} = SendToAddress.new(amount: 0.1)

      assert Keyword.fetch!(errors, :address) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for missing amount" do
      assert {:error, %Changeset{errors: errors}} =
               SendToAddress.new(address: @valid_bech32_address)

      assert Keyword.fetch!(errors, :amount) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for invalid address" do
      invalid_addresses = [
        # Too short
        "1abc",
        # Too long
        String.duplicate("bc1q", 30),
        # Invalid characters for Base58
        "1InvalidChars0OIl",
        # Empty string
        ""
      ]

      for address <- invalid_addresses do
        assert {:error, %Changeset{} = changeset} =
                 SendToAddress.new(address: address, amount: 0.1)

        assert changeset.errors[:address] != nil
      end
    end

    test "returns error for invalid amount" do
      invalid_amounts = [0, -0.1, -1.0]

      for amount <- invalid_amounts do
        assert {:error, %Changeset{errors: errors}} =
                 SendToAddress.new(address: @valid_bech32_address, amount: amount)

        assert Keyword.fetch!(errors, :amount) ==
                 {"must be greater than %{number}",
                  [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}
      end
    end

    test "returns error for invalid estimate mode" do
      assert {:error, %Changeset{errors: errors}} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 estimate_mode: "invalid"
               )

      assert Keyword.fetch!(errors, :estimate_mode) ==
               {"is invalid",
                [{:validation, :inclusion}, {:enum, ["unset", "economical", "conservative"]}]}
    end

    test "returns error for invalid conf_target" do
      assert {:error, %Changeset{errors: errors}} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 conf_target: 0
               )

      assert Keyword.fetch!(errors, :conf_target) ==
               {"must be greater than %{number}",
                [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}
    end

    test "returns error for invalid fee_rate" do
      assert {:error, %Changeset{errors: errors}} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 fee_rate: -1.0
               )

      assert Keyword.fetch!(errors, :fee_rate) ==
               {"must be greater than %{number}",
                [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}
    end

    test "returns error for comment too long" do
      long_comment = String.duplicate("a", 1025)

      assert {:error, %Changeset{} = changeset} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 comment: long_comment
               )

      assert "should be at most 1024 character(s)" in errors_on(changeset).comment
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               SendToAddress.new(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 wallet_name: long_name
               )

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end
  end

  describe "new!/1" do
    test "creates a SendToAddress with required fields" do
      assert %SendToAddress{address: @valid_bech32_address, amount: 0.1} =
               SendToAddress.new!(address: @valid_bech32_address, amount: 0.1)
    end

    test "raises error for invalid data" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        SendToAddress.new!(address: "invalid", amount: 0.1)
      end
    end
  end

  describe "encodable" do
    test "encodes method with required fields only" do
      assert %Request{
               params: [
                 @valid_bech32_address,
                 0.1,
                 nil,
                 nil,
                 false,
                 nil,
                 nil,
                 "unset",
                 true,
                 nil,
                 false
               ],
               method: "sendtoaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               SendToAddress.new!(address: @valid_bech32_address, amount: 0.1)
               |> Encodable.encode()
    end

    test "encodes method with wallet name" do
      assert %Request{
               params: [
                 @valid_bech32_address,
                 0.1,
                 nil,
                 nil,
                 false,
                 nil,
                 nil,
                 "unset",
                 true,
                 nil,
                 false
               ],
               method: "sendtoaddress",
               jsonrpc: "1.0",
               path: "/wallet/test_wallet"
             } =
               SendToAddress.new!(
                 address: @valid_bech32_address,
                 amount: 0.1,
                 wallet_name: "test_wallet"
               )
               |> Encodable.encode()
    end

    test "encodes method with all parameters" do
      assert %Request{
               params: [
                 @valid_bech32_address,
                 0.05,
                 "Payment",
                 "Alice",
                 true,
                 false,
                 6,
                 "economical",
                 false,
                 25.0,
                 true
               ],
               method: "sendtoaddress",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               SendToAddress.new!(
                 address: @valid_bech32_address,
                 amount: 0.05,
                 comment: "Payment",
                 comment_to: "Alice",
                 subtract_fee_from_amount: true,
                 replaceable: false,
                 conf_target: 6,
                 estimate_mode: "economical",
                 avoid_reuse: false,
                 fee_rate: 25.0,
                 verbose: true,
                 wallet_name: "my_wallet"
               )
               |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = SendToAddress.changeset(%SendToAddress{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).address
      assert "can't be blank" in errors_on(changeset).amount
    end

    test "validates address format" do
      # Valid addresses should pass
      for address <- [@valid_legacy_address, @valid_p2sh_address, @valid_bech32_address] do
        changeset =
          SendToAddress.changeset(%SendToAddress{}, %{address: address, amount: 0.1})

        assert changeset.valid?
      end

      # Invalid address should fail
      changeset =
        SendToAddress.changeset(%SendToAddress{}, %{address: "invalid", amount: 0.1})

      refute changeset.valid?
      assert changeset.errors[:address] != nil
    end

    test "validates amount is positive" do
      changeset =
        SendToAddress.changeset(%SendToAddress{}, %{
          address: @valid_bech32_address,
          amount: -0.1
        })

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).amount
    end

    test "validates estimate_mode inclusion" do
      # Valid modes
      for mode <- ["unset", "economical", "conservative"] do
        changeset =
          SendToAddress.changeset(%SendToAddress{}, %{
            address: @valid_bech32_address,
            amount: 0.1,
            estimate_mode: mode
          })

        assert changeset.valid?
      end

      # Invalid mode
      changeset =
        SendToAddress.changeset(%SendToAddress{}, %{
          address: @valid_bech32_address,
          amount: 0.1,
          estimate_mode: "invalid"
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).estimate_mode
    end
  end
end
