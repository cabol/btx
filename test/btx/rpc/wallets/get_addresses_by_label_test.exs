defmodule BTx.RPC.Wallets.GetAddressesByLabelTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.WalletsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.GetAddressesByLabel
  alias Ecto.{Changeset, UUID}

  @url "http://localhost:18443/"

  ## Schema tests

  describe "GetAddressesByLabel.new/1" do
    test "creates a new GetAddressesByLabel with required label" do
      assert {:ok, %GetAddressesByLabel{label: "tabby"}} =
               GetAddressesByLabel.new(label: "tabby")
    end

    test "creates a new GetAddressesByLabel with all parameters" do
      assert {:ok,
              %GetAddressesByLabel{
                label: "savings",
                wallet_name: "my_wallet"
              }} =
               GetAddressesByLabel.new(
                 label: "savings",
                 wallet_name: "my_wallet"
               )
    end

    test "accepts various label formats" do
      valid_labels = [
        "simple",
        "multi word label",
        "label-with-dashes",
        "label_with_underscores",
        "label123",
        "UPPERCASE",
        "MixedCase",
        "special!@#$%^&*()",
        # Empty label is valid
        "",
        # Maximum length
        String.duplicate("a", 64)
      ]

      for label <- valid_labels do
        assert {:ok, %GetAddressesByLabel{label: ^label}} =
                 GetAddressesByLabel.new(label: label)
      end
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
        assert {:ok, %GetAddressesByLabel{wallet_name: ^name}} =
                 GetAddressesByLabel.new(label: "test", wallet_name: name)
      end
    end

    test "returns error for missing label" do
      assert {:error, %Changeset{errors: errors}} = GetAddressesByLabel.new(%{})

      assert Keyword.fetch!(errors, :label) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for label too long" do
      long_label = String.duplicate("a", 257)

      assert {:error, %Changeset{} = changeset} =
               GetAddressesByLabel.new(label: long_label)

      assert "should be at most 64 character(s)" in errors_on(changeset).label
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               GetAddressesByLabel.new(label: "test", wallet_name: long_name)

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "accepts wallet name as nil" do
      assert {:ok, %GetAddressesByLabel{wallet_name: nil}} =
               GetAddressesByLabel.new(label: "test", wallet_name: nil)
    end
  end

  describe "GetAddressesByLabel.new!/1" do
    test "creates a new GetAddressesByLabel with required label" do
      assert %GetAddressesByLabel{label: "tabby"} =
               GetAddressesByLabel.new!(label: "tabby")
    end

    test "creates a new GetAddressesByLabel with all options" do
      assert %GetAddressesByLabel{
               label: "savings",
               wallet_name: "my_wallet"
             } =
               GetAddressesByLabel.new!(
                 label: "savings",
                 wallet_name: "my_wallet"
               )
    end

    test "raises error for invalid label" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetAddressesByLabel.new!(label: String.duplicate("a", 257))
      end
    end

    test "raises error for missing required fields" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetAddressesByLabel.new!([])
      end
    end

    test "raises error for validation failures" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetAddressesByLabel.new!(
          label: String.duplicate("a", 257),
          wallet_name: String.duplicate("b", 65)
        )
      end
    end
  end

  describe "GetAddressesByLabel encodable" do
    test "encodes method with required label only" do
      assert %Request{
               params: ["tabby"],
               method: "getaddressesbylabel",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetAddressesByLabel.new!(label: "tabby")
               |> Encodable.encode()
    end

    test "encodes method with wallet name" do
      assert %Request{
               params: ["savings"],
               method: "getaddressesbylabel",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               GetAddressesByLabel.new!(
                 label: "savings",
                 wallet_name: "my_wallet"
               )
               |> Encodable.encode()
    end

    test "encodes method with special characters in label" do
      special_label = "test label with spaces & symbols!@#"

      assert %Request{
               params: [^special_label],
               method: "getaddressesbylabel",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetAddressesByLabel.new!(label: special_label)
               |> Encodable.encode()
    end

    test "encodes method with empty label" do
      assert %Request{
               params: [""],
               method: "getaddressesbylabel",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetAddressesByLabel.new!(label: "")
               |> Encodable.encode()
    end

    test "encodes method with all parameters" do
      assert %Request{
               params: ["production_addresses"],
               method: "getaddressesbylabel",
               jsonrpc: "1.0",
               path: "/wallet/production_wallet"
             } =
               GetAddressesByLabel.new!(
                 label: "production_addresses",
                 wallet_name: "production_wallet"
               )
               |> Encodable.encode()
    end
  end

  describe "GetAddressesByLabel changeset/2" do
    test "validates required fields" do
      changeset = GetAddressesByLabel.changeset(%GetAddressesByLabel{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).label
    end

    test "validates label length" do
      # Too long
      long_label = String.duplicate("a", 257)

      changeset =
        GetAddressesByLabel.changeset(%GetAddressesByLabel{}, %{label: long_label})

      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).label

      # Valid length
      valid_label = String.duplicate("a", 64)

      changeset =
        GetAddressesByLabel.changeset(%GetAddressesByLabel{}, %{label: valid_label})

      assert changeset.valid?
    end

    test "validates wallet name length" do
      # Too long
      long_name = String.duplicate("a", 65)

      changeset =
        GetAddressesByLabel.changeset(%GetAddressesByLabel{}, %{
          label: "test",
          wallet_name: long_name
        })

      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name

      # Valid length
      valid_name = String.duplicate("a", 64)

      changeset =
        GetAddressesByLabel.changeset(%GetAddressesByLabel{}, %{
          label: "test",
          wallet_name: valid_name
        })

      assert changeset.valid?
    end

    test "accepts optional wallet_name" do
      changeset =
        GetAddressesByLabel.changeset(%GetAddressesByLabel{}, %{
          label: "test_label",
          wallet_name: "test_wallet"
        })

      assert changeset.valid?
      assert Changeset.get_change(changeset, :wallet_name) == "test_wallet"
    end
  end

  ## GetAddressesByLabel RPC tests

  describe "(RPC) Wallets.get_addresses_by_label/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns addresses map", %{client: client} do
      addresses_result = get_addresses_by_label_preset(:mixed_purposes)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "getaddressesbylabel",
                   "params" => ["tabby"],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          # Should have auto-generated ID
          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => addresses_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.get_addresses_by_label(client, label: "tabby")

      assert is_map(result)
      assert map_size(result) == 4

      # Verify structure of returned addresses
      for {address, info} <- result do
        assert is_binary(address)
        assert is_map(info)
        assert Map.has_key?(info, "purpose")
        assert info["purpose"] in ["send", "receive"]
      end
    end

    test "call with wallet name", %{client: client} do
      url = Path.join(@url, "/wallet/my_wallet")
      addresses_result = get_addresses_by_label_preset(:receive_only)

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "getaddressesbylabel",
                   "params" => ["savings"],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => addresses_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_addresses_by_label(client,
                 label: "savings",
                 wallet_name: "my_wallet"
               )

      assert is_map(result)
      assert map_size(result) == 3

      # All should be receive addresses
      for {_address, info} <- result do
        assert info["purpose"] == "receive"
      end
    end

    test "call for label with only send addresses", %{client: client} do
      addresses_result = get_addresses_by_label_preset(:send_only)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => addresses_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.get_addresses_by_label(client, label: "external")

      assert is_map(result)
      assert map_size(result) == 2

      # All should be send addresses
      for {_address, info} <- result do
        assert info["purpose"] == "send"
      end
    end

    test "call for label with no addresses returns empty map", %{client: client} do
      addresses_result = get_addresses_by_label_preset(:empty)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => addresses_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.get_addresses_by_label(client, label: "nonexistent")

      assert result == %{}
    end

    test "call with special characters in label", %{client: client} do
      special_label = "test label with spaces & symbols!@#"
      addresses_result = get_addresses_by_label_preset(:mixed_purposes)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getaddressesbylabel",
                   "params" => [^special_label],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => addresses_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.get_addresses_by_label(client, label: special_label)
      assert is_map(result)
    end

    test "call with empty label", %{client: client} do
      addresses_result = get_addresses_by_label_preset(:receive_only)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getaddressesbylabel",
                   "params" => [""],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => addresses_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Wallets.get_addresses_by_label(client, label: "")
      assert is_map(result)
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
               Wallets.get_addresses_by_label(client,
                 label: "test",
                 wallet_name: "nonexistent"
               )

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_addresses_by_label!(client, label: "test")
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client()

      # Create a new wallet for testing
      wallet_name = "getaddressesbylabel-test-#{UUID.generate()}"

      wallet =
        Wallets.create_wallet!(
          real_client,
          [wallet_name: wallet_name, passphrase: "test"],
          retries: 10
        )

      # Create some addresses with labels
      test_label = "test_label_#{System.unique_integer([:positive])}"

      # Get a new address with our test label
      address1 =
        Wallets.get_new_address!(
          real_client,
          [label: test_label, wallet_name: wallet.name],
          retries: 10
        )

      # Get another address with the same label
      address2 =
        Wallets.get_new_address!(
          real_client,
          [label: test_label, wallet_name: wallet.name],
          retries: 10
        )

      # Now get addresses by label
      assert {:ok, addresses} =
               Wallets.get_addresses_by_label(
                 real_client,
                 [label: test_label, wallet_name: wallet.name],
                 retries: 10
               )

      assert is_map(addresses)
      assert map_size(addresses) == 2
      assert Map.has_key?(addresses, address1)
      assert Map.has_key?(addresses, address2)

      # Verify the structure
      for {address, info} <- addresses do
        assert is_binary(address)
        assert is_map(info)
        assert Map.has_key?(info, "purpose")
        assert info["purpose"] in ["send", "receive"]
      end

      # Test with non-existent label
      assert_raise BTx.RPC.MethodError, "No addresses with label nonexistent_label", fn ->
        Wallets.get_addresses_by_label!(
          real_client,
          [label: "nonexistent_label", wallet_name: wallet.name],
          retries: 10
        )
      end
    end
  end

  describe "(RPC) Wallets.get_addresses_by_label!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns addresses map", %{client: client} do
      addresses_result = get_addresses_by_label_preset(:mixed_purposes)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => addresses_result,
              "error" => nil
            }
          }
      end)

      result = Wallets.get_addresses_by_label!(client, label: "tabby")
      assert is_map(result)
      assert map_size(result) == 4

      # Verify structure
      for {address, info} <- result do
        assert is_binary(address)
        assert is_map(info)
        assert info["purpose"] in ["send", "receive"]
      end
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.get_addresses_by_label!(client, label: String.duplicate("a", 257))
      end
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_addresses_by_label!(client, label: "test")
      end
    end

    test "raises on missing required fields", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.get_addresses_by_label!(client, %{})
      end
    end
  end
end
