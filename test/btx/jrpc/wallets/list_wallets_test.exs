defmodule BTx.JRPC.Wallets.ListWalletsTest do
  use ExUnit.Case, async: true

  alias BTx.JRPC.{Encodable, Request}
  alias BTx.JRPC.Wallets.ListWallets
  alias Ecto.Changeset

  describe "new/0" do
    test "creates a new ListWallets with default values" do
      assert {:ok, %ListWallets{method: "listwallets"}} = ListWallets.new()
    end
  end

  describe "new!/0" do
    test "creates a new ListWallets with default values" do
      assert %ListWallets{method: "listwallets"} = ListWallets.new!()
    end
  end

  describe "encodable" do
    test "encodes method with empty parameters" do
      assert %Request{
               params: [],
               method: "listwallets",
               jsonrpc: "1.0",
               path: "/"
             } = ListWallets.new!() |> Encodable.encode()
    end

    test "always encodes with empty parameters" do
      assert %Request{
               params: [],
               method: "listwallets",
               jsonrpc: "1.0",
               path: "/"
             } = ListWallets.new!() |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "accepts empty parameters" do
      changeset = ListWallets.changeset(%ListWallets{}, %{})
      assert changeset.valid?
    end

    test "always returns valid changeset" do
      # Since there are no fields to cast or validate, the changeset should always be valid
      changeset = ListWallets.changeset(%ListWallets{}, %{})
      assert changeset.valid?
      assert changeset.errors == []
    end

    test "applies changes correctly" do
      changeset = ListWallets.changeset(%ListWallets{}, %{})
      assert changeset.valid?

      # Even though no fields are cast, the changeset should work with apply_action
      assert {:ok, %ListWallets{}} = Changeset.apply_action(changeset, :listwallets)
    end

    test "maintains method field value" do
      changeset = ListWallets.changeset(%ListWallets{}, %{})
      {:ok, result} = Changeset.apply_action(changeset, :listwallets)
      assert result.method == "listwallets"
    end
  end
end
