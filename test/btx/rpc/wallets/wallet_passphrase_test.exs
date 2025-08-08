defmodule BTx.RPC.Wallets.WalletPassphraseTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.WalletPassphrase
  alias Ecto.{Changeset, UUID}

  @url "http://localhost:18443/"

  # Maximum timeout value (~3 years)
  @max_timeout 100_000_000

  ## Schema tests

  describe "new/1" do
    test "creates a new WalletPassphrase with required fields" do
      assert {:ok, %WalletPassphrase{passphrase: "secure_pass", timeout: 60}} =
               WalletPassphrase.new(passphrase: "secure_pass", timeout: 60)
    end

    test "creates a new WalletPassphrase with all parameters" do
      assert {:ok,
              %WalletPassphrase{
                passphrase: "my_secure_passphrase",
                timeout: 300,
                wallet_name: "my_wallet"
              }} =
               WalletPassphrase.new(
                 passphrase: "my_secure_passphrase",
                 timeout: 300,
                 wallet_name: "my_wallet"
               )
    end

    test "accepts valid passphrases" do
      valid_passphrases = [
        # minimum length
        "a",
        "simple_pass",
        "complex!@#$%^&*()pass123",
        "spaces in passphrase",
        "with-dashes_and_underscores",
        # maximum length
        String.duplicate("a", 1024)
      ]

      for passphrase <- valid_passphrases do
        assert {:ok, %WalletPassphrase{passphrase: ^passphrase}} =
                 WalletPassphrase.new(passphrase: passphrase, timeout: 60)
      end
    end

    test "accepts valid timeout values" do
      valid_timeouts = [1, 60, 300, 3600, 86_400, @max_timeout]

      for timeout <- valid_timeouts do
        assert {:ok, %WalletPassphrase{timeout: ^timeout}} =
                 WalletPassphrase.new(passphrase: "test_pass", timeout: timeout)
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
        assert {:ok, %WalletPassphrase{wallet_name: ^name}} =
                 WalletPassphrase.new(
                   passphrase: "test_pass",
                   timeout: 60,
                   wallet_name: name
                 )
      end
    end

    test "returns error for missing passphrase" do
      assert {:error, %Changeset{errors: errors}} =
               WalletPassphrase.new(timeout: 60)

      assert Keyword.fetch!(errors, :passphrase) ==
               {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for missing timeout" do
      assert {:error, %Changeset{errors: errors}} =
               WalletPassphrase.new(passphrase: "test_pass")

      assert Keyword.fetch!(errors, :timeout) ==
               {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for both missing required fields" do
      assert {:error, %Changeset{errors: errors}} = WalletPassphrase.new(%{})

      assert Keyword.fetch!(errors, :passphrase) ==
               {"can't be blank", [{:validation, :required}]}

      assert Keyword.fetch!(errors, :timeout) ==
               {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for empty passphrase" do
      assert {:error, %Changeset{errors: errors}} =
               WalletPassphrase.new(passphrase: "", timeout: 60)

      assert Keyword.fetch!(errors, :passphrase) ==
               {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for passphrase too long" do
      long_passphrase = String.duplicate("a", 1025)

      assert {:error, %Changeset{} = changeset} =
               WalletPassphrase.new(passphrase: long_passphrase, timeout: 60)

      assert "should be at most 1024 character(s)" in errors_on(changeset).passphrase
    end

    test "returns error for invalid timeout values" do
      invalid_timeouts = [0, -1, -60, @max_timeout + 1]

      for timeout <- invalid_timeouts do
        assert {:error, %Changeset{} = changeset} =
                 WalletPassphrase.new(passphrase: "test_pass", timeout: timeout)

        case timeout do
          val when val <= 0 ->
            assert "must be greater than 0" in errors_on(changeset).timeout

          val when val > @max_timeout ->
            assert "must be less than or equal to #{@max_timeout}" in errors_on(changeset).timeout
        end
      end
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               WalletPassphrase.new(
                 passphrase: "test_pass",
                 timeout: 60,
                 wallet_name: long_name
               )

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "accepts empty string wallet name as nil" do
      assert {:ok, %WalletPassphrase{wallet_name: nil}} =
               WalletPassphrase.new(passphrase: "test_pass", timeout: 60, wallet_name: "")
    end

    test "returns multiple errors for multiple invalid fields" do
      assert {:error, %Changeset{errors: errors}} =
               WalletPassphrase.new(
                 passphrase: "",
                 timeout: -1,
                 wallet_name: String.duplicate("a", 65)
               )

      assert Keyword.fetch!(errors, :passphrase) ==
               {"can't be blank", [{:validation, :required}]}

      assert "must be greater than 0" in errors_on(%Changeset{errors: errors}).timeout

      assert "should be at most 64 character(s)" in errors_on(%Changeset{errors: errors}).wallet_name
    end
  end

  describe "new!/1" do
    test "creates a new WalletPassphrase with required fields" do
      assert %WalletPassphrase{passphrase: "secure_pass", timeout: 60} =
               WalletPassphrase.new!(passphrase: "secure_pass", timeout: 60)
    end

    test "creates a new WalletPassphrase with all options" do
      assert %WalletPassphrase{
               passphrase: "my_secure_passphrase",
               timeout: 300,
               wallet_name: "my_wallet"
             } =
               WalletPassphrase.new!(
                 passphrase: "my_secure_passphrase",
                 timeout: 300,
                 wallet_name: "my_wallet"
               )
    end

    test "raises error for invalid passphrase" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        WalletPassphrase.new!(passphrase: "", timeout: 60)
      end
    end

    test "raises error for invalid timeout" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        WalletPassphrase.new!(passphrase: "test_pass", timeout: 0)
      end
    end

    test "raises error for missing required fields" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        WalletPassphrase.new!([])
      end
    end

    test "raises error for multiple validation failures" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        WalletPassphrase.new!(
          passphrase: "",
          timeout: -1,
          wallet_name: String.duplicate("a", 65)
        )
      end
    end
  end

  describe "encodable" do
    test "encodes method with required fields only" do
      assert %Request{
               params: ["secure_pass", 60],
               method: "walletpassphrase",
               jsonrpc: "1.0",
               path: "/"
             } =
               WalletPassphrase.new!(passphrase: "secure_pass", timeout: 60)
               |> Encodable.encode()
    end

    test "encodes method with wallet name" do
      assert %Request{
               params: ["secure_pass", 60],
               method: "walletpassphrase",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               WalletPassphrase.new!(
                 passphrase: "secure_pass",
                 timeout: 60,
                 wallet_name: "my_wallet"
               )
               |> Encodable.encode()
    end

    test "encodes method with complex passphrase" do
      complex_passphrase = "Complex!@#$%^&*()Passphrase123 with spaces"

      assert %Request{
               params: [^complex_passphrase, 300],
               method: "walletpassphrase",
               jsonrpc: "1.0",
               path: "/"
             } =
               WalletPassphrase.new!(
                 passphrase: complex_passphrase,
                 timeout: 300
               )
               |> Encodable.encode()
    end

    test "encodes method with maximum timeout" do
      assert %Request{
               params: ["test_pass", @max_timeout],
               method: "walletpassphrase",
               jsonrpc: "1.0",
               path: "/"
             } =
               WalletPassphrase.new!(
                 passphrase: "test_pass",
                 timeout: @max_timeout
               )
               |> Encodable.encode()
    end

    test "encodes method with all parameters" do
      assert %Request{
               params: ["my_secure_passphrase", 1800],
               method: "walletpassphrase",
               jsonrpc: "1.0",
               path: "/wallet/production_wallet"
             } =
               WalletPassphrase.new!(
                 passphrase: "my_secure_passphrase",
                 timeout: 1800,
                 wallet_name: "production_wallet"
               )
               |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = WalletPassphrase.changeset(%WalletPassphrase{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).passphrase
      assert "can't be blank" in errors_on(changeset).timeout
    end

    test "validates passphrase length" do
      # Too long
      long_passphrase = String.duplicate("a", 1025)

      changeset =
        WalletPassphrase.changeset(%WalletPassphrase{}, %{
          passphrase: long_passphrase,
          timeout: 60
        })

      refute changeset.valid?
      assert "should be at most 1024 character(s)" in errors_on(changeset).passphrase

      # Valid length
      valid_passphrase = String.duplicate("a", 1024)

      changeset =
        WalletPassphrase.changeset(%WalletPassphrase{}, %{
          passphrase: valid_passphrase,
          timeout: 60
        })

      assert changeset.valid?
    end

    test "validates timeout range" do
      # Too small
      changeset =
        WalletPassphrase.changeset(%WalletPassphrase{}, %{
          passphrase: "test_pass",
          timeout: 0
        })

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).timeout

      # Too large
      changeset =
        WalletPassphrase.changeset(%WalletPassphrase{}, %{
          passphrase: "test_pass",
          timeout: @max_timeout + 1
        })

      refute changeset.valid?
      assert "must be less than or equal to #{@max_timeout}" in errors_on(changeset).timeout

      # Valid range
      for timeout <- [1, 60, @max_timeout] do
        changeset =
          WalletPassphrase.changeset(%WalletPassphrase{}, %{
            passphrase: "test_pass",
            timeout: timeout
          })

        assert changeset.valid?
      end
    end

    test "validates wallet name length" do
      # Too long
      long_name = String.duplicate("a", 65)

      changeset =
        WalletPassphrase.changeset(%WalletPassphrase{}, %{
          passphrase: "test_pass",
          timeout: 60,
          wallet_name: long_name
        })

      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name

      # Valid length
      valid_name = String.duplicate("a", 64)

      changeset =
        WalletPassphrase.changeset(%WalletPassphrase{}, %{
          passphrase: "test_pass",
          timeout: 60,
          wallet_name: valid_name
        })

      assert changeset.valid?
    end

    test "accepts all optional fields" do
      changeset =
        WalletPassphrase.changeset(%WalletPassphrase{}, %{
          passphrase: "secure_passphrase",
          timeout: 300,
          wallet_name: "my_wallet"
        })

      assert changeset.valid?
      assert Changeset.get_change(changeset, :passphrase) == "secure_passphrase"
      assert Changeset.get_change(changeset, :timeout) == 300
      assert Changeset.get_change(changeset, :wallet_name) == "my_wallet"
    end
  end

  ## WalletPassphrase RPC

  describe "(RPC) Wallets.wallet_passphrase/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns nil", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "walletpassphrase",
                   "params" => ["my_secure_passphrase", 60],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          # Should have auto-generated ID
          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => nil,
              "error" => nil
            }
          }
      end)

      assert {:ok, nil} =
               Wallets.wallet_passphrase(client,
                 passphrase: "my_secure_passphrase",
                 timeout: 60
               )
    end

    test "call with wallet name", %{client: client} do
      url = Path.join(@url, "/wallet/my_wallet")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "walletpassphrase",
                   "params" => ["secure_pass", 300],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => nil
            }
          }
      end)

      assert {:ok, nil} =
               Wallets.wallet_passphrase(client,
                 passphrase: "secure_pass",
                 timeout: 300,
                 wallet_name: "my_wallet"
               )
    end

    test "call with maximum timeout", %{client: client} do
      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "walletpassphrase",
                   "params" => ["long_term_pass", @max_timeout],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => nil
            }
          }
      end)

      assert {:ok, nil} =
               Wallets.wallet_passphrase(client,
                 passphrase: "long_term_pass",
                 timeout: @max_timeout
               )
    end

    test "call with complex passphrase containing special characters", %{client: client} do
      complex_passphrase = "Complex!@#$%^&*()Passphrase123 with spaces"

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "walletpassphrase",
                   "params" => [^complex_passphrase, 120],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => nil
            }
          }
      end)

      assert {:ok, nil} =
               Wallets.wallet_passphrase(client,
                 passphrase: complex_passphrase,
                 timeout: 120
               )
    end

    test "handles incorrect passphrase error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -14,
                "message" => "Error: The wallet passphrase entered was incorrect."
              }
            }
          }
      end)

      assert {:error,
              %BTx.RPC.MethodError{
                code: -14,
                message: message,
                reason: :wallet_passphrase_incorrect
              }} =
               Wallets.wallet_passphrase(client,
                 passphrase: "wrong_passphrase",
                 timeout: 60
               )

      assert message =~ "incorrect"
    end

    test "handles wallet not encrypted error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -15,
                "message" =>
                  "Error: running with an unencrypted wallet, but walletpassphrase was called."
              }
            }
          }
      end)

      assert {:error,
              %BTx.RPC.MethodError{code: -15, message: message, reason: :wallet_wrong_enc_state}} =
               Wallets.wallet_passphrase(client,
                 passphrase: "any_passphrase",
                 timeout: 60
               )

      assert message =~ "unencrypted wallet"
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

      assert {:error,
              %BTx.RPC.MethodError{
                code: -18,
                message: message,
                reason: :wallet_not_found
              }} =
               Wallets.wallet_passphrase(client,
                 passphrase: "any_passphrase",
                 timeout: 60,
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
        Wallets.wallet_passphrase!(client,
          passphrase: "test_pass",
          timeout: 60
        )
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node with an encrypted wallet
      real_client = new_client()

      # Create an encrypted wallet
      wallet_name = "wallet-passphrase-test-#{UUID.generate()}"

      # Create wallet with passphrase
      %BTx.RPC.Wallets.CreateWalletResult{name: ^wallet_name} =
        Wallets.create_wallet!(
          real_client,
          [wallet_name: wallet_name, passphrase: "test_passphrase_123"],
          retries: 10
        )

      # The wallet should now be encrypted and locked
      # Try to unlock it
      assert Wallets.wallet_passphrase(
               real_client,
               [passphrase: "test_passphrase_123", timeout: 60, wallet_name: wallet_name],
               retries: 10
             ) == {:ok, nil}

      # Try with wrong passphrase (should fail)
      assert {:error, %BTx.RPC.MethodError{code: -14, reason: :wallet_passphrase_incorrect}} =
               Wallets.wallet_passphrase(
                 real_client,
                 [passphrase: "wrong_passphrase", timeout: 60, wallet_name: wallet_name],
                 retries: 10
               )
    end
  end

  describe "(RPC) Wallets.wallet_passphrase!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns nil on success", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => nil
            }
          }
      end)

      assert nil ==
               Wallets.wallet_passphrase!(client,
                 passphrase: "secure_pass",
                 timeout: 60
               )
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.wallet_passphrase!(client, passphrase: "", timeout: 60)
      end
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.wallet_passphrase!(client,
          passphrase: "test_pass",
          timeout: 60
        )
      end
    end

    test "raises on incorrect passphrase", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -14,
                "message" => "Error: The wallet passphrase entered was incorrect."
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, ~r/incorrect/, fn ->
        Wallets.wallet_passphrase!(client,
          passphrase: "wrong_passphrase",
          timeout: 60
        )
      end
    end

    test "raises on unencrypted wallet", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -15,
                "message" =>
                  "Error: running with an unencrypted wallet, but walletpassphrase was called."
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, ~r/unencrypted wallet/, fn ->
        Wallets.wallet_passphrase!(client,
          passphrase: "any_passphrase",
          timeout: 60
        )
      end
    end
  end
end
