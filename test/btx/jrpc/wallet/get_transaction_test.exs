defmodule BTx.JRPC.Wallet.GetTransactionTest do
  use ExUnit.Case, async: true

  alias BTx.JRPC.Encodable
  alias BTx.JRPC.Wallet.GetTransaction
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
                verbose: true
              }} =
               GetTransaction.new(
                 txid: @valid_txid,
                 include_watchonly: false,
                 verbose: true
               )
    end

    test "uses default values for optional fields" do
      assert {:ok,
              %GetTransaction{
                include_watchonly: true,
                verbose: false
              }} = GetTransaction.new(txid: @valid_txid)
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
               verbose: true
             } =
               GetTransaction.new!(
                 txid: @valid_txid,
                 include_watchonly: false,
                 verbose: true
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
  end

  describe "encodable" do
    test "encodes the request with default options" do
      assert GetTransaction.new!(txid: @valid_txid)
             |> Encodable.encode()
             |> Map.drop([:id]) == %{
               params: [@valid_txid, true, false],
               method: "gettransaction",
               jsonrpc: "1.0"
             }
    end

    test "encodes the request with custom options" do
      assert GetTransaction.new!(
               txid: @valid_txid,
               include_watchonly: false,
               verbose: true
             )
             |> Encodable.encode()
             |> Map.drop([:id]) == %{
               params: [@valid_txid, false, true],
               method: "gettransaction",
               jsonrpc: "1.0"
             }
    end

    test "encodes the request with mixed options" do
      assert GetTransaction.new!(
               txid: @valid_txid,
               include_watchonly: true,
               verbose: true
             )
             |> Encodable.encode()
             |> Map.drop([:id]) == %{
               params: [@valid_txid, true, true],
               method: "gettransaction",
               jsonrpc: "1.0"
             }
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
