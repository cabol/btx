defmodule BTx.JRPC.Wallets.GetBalanceTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils

  alias BTx.JRPC.{Encodable, Request}
  alias BTx.JRPC.Wallets.GetBalance
  alias Ecto.Changeset

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
end
