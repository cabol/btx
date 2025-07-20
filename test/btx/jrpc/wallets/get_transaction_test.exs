defmodule BTx.JRPC.Wallets.GetTransactionTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils

  alias BTx.JRPC.{Encodable, Request}
  alias BTx.JRPC.Wallets.GetTransaction
  alias Ecto.Changeset

  # Valid Bitcoin transaction ID for testing
  @valid_txid "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  @invalid_txid_short "1234567890abcdef"
  @invalid_txid_long "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123"

  describe "new/1" do
    test "creates a new GetTransaction with valid txid" do
      assert {:ok, %GetTransaction{txid: @valid_txid, include_watchonly: true, verbose: false}} =
               GetTransaction.new(txid: @valid_txid)
    end

    test "creates a new GetTransaction with all options" do
      assert {:ok,
              %GetTransaction{
                txid: @valid_txid,
                include_watchonly: false,
                verbose: true,
                wallet_name: "test_wallet"
              }} =
               GetTransaction.new(
                 txid: @valid_txid,
                 include_watchonly: false,
                 verbose: true,
                 wallet_name: "test_wallet"
               )
    end

    test "uses default values for optional fields" do
      assert {:ok,
              %GetTransaction{
                include_watchonly: true,
                verbose: false,
                wallet_name: nil
              }} = GetTransaction.new(txid: @valid_txid)
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
        assert {:ok, %GetTransaction{wallet_name: ^name}} =
                 GetTransaction.new(txid: @valid_txid, wallet_name: name)
      end
    end

    test "returns an error if txid is missing" do
      assert {:error, %Changeset{errors: errors}} =
               GetTransaction.new(%{})

      assert Keyword.fetch!(errors, :txid) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns an error if txid is too short" do
      assert {:error, %Changeset{} = changeset} =
               GetTransaction.new(txid: @invalid_txid_short)

      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "returns an error if txid is too long" do
      assert {:error, %Changeset{} = changeset} =
               GetTransaction.new(txid: @invalid_txid_long)

      assert "should be 64 character(s)" in errors_on(changeset).txid
    end

    test "returns an error if txid is nil" do
      assert {:error, %Changeset{errors: errors}} =
               GetTransaction.new(txid: nil)

      assert Keyword.fetch!(errors, :txid) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns an error if txid is empty string" do
      assert {:error, %Changeset{errors: errors}} =
               GetTransaction.new(txid: "")

      assert Keyword.fetch!(errors, :txid) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               GetTransaction.new(txid: @valid_txid, wallet_name: long_name)

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end
  end

  describe "new!/1" do
    test "creates a new GetTransaction with valid txid" do
      assert %GetTransaction{txid: @valid_txid, include_watchonly: true, verbose: false} =
               GetTransaction.new!(txid: @valid_txid)
    end

    test "creates a new GetTransaction with all options" do
      assert %GetTransaction{
               txid: @valid_txid,
               include_watchonly: false,
               verbose: true,
               wallet_name: "test_wallet"
             } =
               GetTransaction.new!(
                 txid: @valid_txid,
                 include_watchonly: false,
                 verbose: true,
                 wallet_name: "test_wallet"
               )
    end

    test "raises an error if txid is invalid" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetTransaction.new!(txid: @invalid_txid_short)
      end
    end

    test "raises an error if txid is missing" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetTransaction.new!(%{})
      end
    end

    test "raises an error if wallet name is invalid" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetTransaction.new!(txid: @valid_txid, wallet_name: String.duplicate("a", 65))
      end
    end
  end

  describe "encodable" do
    test "encodes the request with default options" do
      assert %Request{
               params: [@valid_txid, true, false],
               method: "gettransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetTransaction.new!(txid: @valid_txid)
               |> Encodable.encode()
    end

    test "encodes the request with wallet name" do
      assert %Request{
               params: [@valid_txid, true, false],
               method: "gettransaction",
               jsonrpc: "1.0",
               path: "/wallet/test_wallet"
             } =
               GetTransaction.new!(txid: @valid_txid, wallet_name: "test_wallet")
               |> Encodable.encode()
    end

    test "encodes the request with custom options" do
      assert %Request{
               params: [@valid_txid, false, true],
               method: "gettransaction",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetTransaction.new!(
                 txid: @valid_txid,
                 include_watchonly: false,
                 verbose: true
               )
               |> Encodable.encode()
    end

    test "encodes the request with all options" do
      assert %Request{
               params: [@valid_txid, false, true],
               method: "gettransaction",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               GetTransaction.new!(
                 txid: @valid_txid,
                 include_watchonly: false,
                 verbose: true,
                 wallet_name: "my_wallet"
               )
               |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = GetTransaction.changeset(%GetTransaction{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).txid
    end

    test "validates txid length" do
      # Too short
      changeset = GetTransaction.changeset(%GetTransaction{}, %{txid: @invalid_txid_short})
      refute changeset.valid?
      assert "should be 64 character(s)" in errors_on(changeset).txid

      # Too long
      changeset = GetTransaction.changeset(%GetTransaction{}, %{txid: @invalid_txid_long})
      refute changeset.valid?
      assert "should be 64 character(s)" in errors_on(changeset).txid

      # Just right
      changeset = GetTransaction.changeset(%GetTransaction{}, %{txid: @valid_txid})
      assert changeset.valid?
    end

    test "validates wallet name length" do
      # Too long
      long_name = String.duplicate("a", 65)

      changeset =
        GetTransaction.changeset(%GetTransaction{}, %{txid: @valid_txid, wallet_name: long_name})

      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "accepts valid boolean values for optional fields" do
      changeset =
        GetTransaction.changeset(%GetTransaction{}, %{
          txid: @valid_txid,
          include_watchonly: false,
          verbose: true
        })

      assert changeset.valid?
      assert Changeset.get_change(changeset, :include_watchonly) == false
      assert Changeset.get_change(changeset, :verbose) == true
    end

    test "accepts nil wallet_name" do
      changeset =
        GetTransaction.changeset(%GetTransaction{}, %{
          txid: @valid_txid,
          wallet_name: nil
        })

      assert changeset.valid?
    end
  end
end
