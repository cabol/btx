defmodule BTx.RPC.Wallets.LoadWalletTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.{LoadWallet, LoadWalletResult}
  alias Ecto.{Changeset, UUID}

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a new LoadWallet with required filename" do
      assert {:ok, %LoadWallet{filename: "test.dat", load_on_startup: nil}} =
               LoadWallet.new(filename: "test.dat")
    end

    test "creates a new LoadWallet with all parameters" do
      assert {:ok,
              %LoadWallet{
                filename: "production.dat",
                load_on_startup: true
              }} =
               LoadWallet.new(
                 filename: "production.dat",
                 load_on_startup: true
               )
    end

    test "uses default values for optional fields" do
      assert {:ok, %LoadWallet{load_on_startup: nil}} =
               LoadWallet.new(filename: "test.dat")
    end

    test "accepts valid filenames" do
      valid_filenames = [
        "test.dat",
        "wallet_directory",
        "my-wallet.dat",
        "my_wallet_123",
        "production",
        # minimum length
        "a",
        # maximum length
        String.duplicate("a", 255)
      ]

      for filename <- valid_filenames do
        assert {:ok, %LoadWallet{filename: ^filename}} =
                 LoadWallet.new(filename: filename)
      end
    end

    test "accepts valid load_on_startup values" do
      for value <- [true, false, nil] do
        assert {:ok, %LoadWallet{load_on_startup: ^value}} =
                 LoadWallet.new(filename: "test.dat", load_on_startup: value)
      end
    end

    test "returns error for missing filename" do
      assert {:error, %Changeset{errors: errors}} = LoadWallet.new(%{})

      assert Keyword.fetch!(errors, :filename) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for empty filename" do
      assert {:error, %Changeset{errors: errors}} = LoadWallet.new(filename: "")

      assert Keyword.fetch!(errors, :filename) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for filename too long" do
      long_filename = String.duplicate("a", 256)

      assert {:error, %Changeset{} = changeset} =
               LoadWallet.new(filename: long_filename)

      assert "should be at most 255 character(s)" in errors_on(changeset).filename
    end

    test "accepts keyword list params" do
      assert {:ok, %LoadWallet{filename: "test.dat", load_on_startup: false}} =
               LoadWallet.new(filename: "test.dat", load_on_startup: false)
    end
  end

  describe "new!/1" do
    test "creates a new LoadWallet with required filename" do
      assert %LoadWallet{filename: "test.dat", load_on_startup: nil} =
               LoadWallet.new!(filename: "test.dat")
    end

    test "creates a new LoadWallet with all options" do
      assert %LoadWallet{
               filename: "production.dat",
               load_on_startup: true
             } =
               LoadWallet.new!(
                 filename: "production.dat",
                 load_on_startup: true
               )
    end

    test "raises error for invalid filename length" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        LoadWallet.new!(filename: String.duplicate("a", 256))
      end
    end

    test "raises error for missing filename" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        LoadWallet.new!(%{})
      end
    end
  end

  describe "encodable" do
    test "encodes method with required filename only" do
      assert %Request{
               params: ["test.dat"],
               method: "loadwallet",
               jsonrpc: "1.0",
               path: "/"
             } =
               LoadWallet.new!(filename: "test.dat")
               |> Encodable.encode()
    end

    test "encodes method with load_on_startup option" do
      assert %Request{
               params: ["production.dat", true],
               method: "loadwallet",
               jsonrpc: "1.0",
               path: "/"
             } =
               LoadWallet.new!(
                 filename: "production.dat",
                 load_on_startup: true
               )
               |> Encodable.encode()
    end

    test "encodes method with all parameter combinations" do
      test_cases = [
        {%{filename: "test.dat"}, ["test.dat"]},
        {%{filename: "test.dat", load_on_startup: true}, ["test.dat", true]},
        {%{filename: "test.dat", load_on_startup: false}, ["test.dat", false]},
        {%{filename: "wallet_dir", load_on_startup: nil}, ["wallet_dir"]}
      ]

      for {params, expected_params} <- test_cases do
        encoded = LoadWallet.new!(params) |> Encodable.encode()
        assert encoded.params == expected_params
        assert encoded.method == "loadwallet"
        assert encoded.path == "/"
      end
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = LoadWallet.changeset(%LoadWallet{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).filename
    end

    test "validates filename length" do
      # Too long
      long_filename = String.duplicate("a", 256)
      changeset = LoadWallet.changeset(%LoadWallet{}, %{filename: long_filename})
      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).filename

      # Valid length
      valid_filename = String.duplicate("a", 255)
      changeset = LoadWallet.changeset(%LoadWallet{}, %{filename: valid_filename})
      assert changeset.valid?
    end

    test "accepts valid boolean values for load_on_startup" do
      for value <- [true, false, nil] do
        changeset =
          LoadWallet.changeset(%LoadWallet{}, %{
            filename: "test.dat",
            load_on_startup: value
          })

        assert changeset.valid?
        assert Changeset.get_change(changeset, :load_on_startup) == value
      end
    end
  end

  ## LoadWallet RPC

  describe "(RPC) Wallets.load_wallet/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful wallet load returns wallet info", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the method body structure
          assert %{
                   "method" => "loadwallet",
                   "params" => ["test.dat"],
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
                "name" => "test",
                "warning" => ""
              },
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.load_wallet(client, filename: "test.dat")

      assert result.name == "test"
      assert result.warning == nil
    end

    test "loads wallet with load_on_startup option", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "loadwallet",
                   "params" => ["production.dat", true],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{
                "name" => "production",
                "warning" => ""
              },
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.load_wallet(client,
                 filename: "production.dat",
                 load_on_startup: true
               )

      assert result.name == "production"
    end

    test "returns warning when wallet not loaded cleanly", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          body = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => body["id"],
              "result" => %{
                "name" => "old_wallet",
                "warning" => "Wallet was not loaded cleanly"
              },
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.load_wallet(client, filename: "old_wallet.dat")

      assert %LoadWalletResult{warning: "Wallet was not loaded cleanly"} = result
    end

    test "handles wallet already loaded error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -4,
                "message" => "Wallet test.dat is already loaded."
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -4, message: message, reason: :wallet_error}} =
               Wallets.load_wallet(client, filename: "test.dat")

      assert message =~ "already loaded"
    end

    test "handles wallet file not found error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -18,
                "message" => "Wallet file not found"
              }
            }
          }
      end)

      assert {:error,
              %BTx.RPC.MethodError{
                code: -18,
                message: message,
                reason: :wallet_not_found
              }} = Wallets.load_wallet(client, filename: "nonexistent.dat")

      assert message == "Wallet file not found"
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.load_wallet!(client, filename: "test.dat")
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      client = new_client(retry_opts: [max_retries: 10, delay: :timer.seconds(1)])

      # Create a unique wallet name
      wallet_name = "load-wallet-#{UUID.generate()}"

      # Create wallet
      %BTx.RPC.Wallets.CreateWalletResult{name: ^wallet_name} =
        Wallets.create_wallet!(
          client,
          wallet_name: wallet_name,
          passphrase: "test",
          avoid_reuse: true
        )

      # Unload the wallet
      {:ok, %BTx.RPC.Wallets.UnloadWalletResult{}} =
        Wallets.unload_wallet(
          client,
          wallet_name: wallet_name,
          load_on_startup: false
        )

      assert {:ok, %LoadWalletResult{name: ^wallet_name}} =
               Wallets.load_wallet(client, filename: wallet_name)
    end
  end

  describe "(RPC) Wallets.load_wallet!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "loads wallet and returns result directly", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{
                "name" => "test",
                "warning" => "Partial load"
              },
              "error" => nil
            }
          }
      end)

      assert %LoadWalletResult{name: "test", warning: "Partial load"} =
               Wallets.load_wallet!(client, filename: "test.dat")
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.load_wallet!(client, %{})
      end
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.load_wallet!(client, filename: "test.dat")
      end
    end
  end
end
