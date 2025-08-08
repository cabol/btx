defmodule BTx.RPCTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC
  alias BTx.RPC.Response
  alias BTx.RPC.Wallets.CreateWallet
  alias Ecto.UUID

  @url "http://localhost:18443/"

  describe "client/1" do
    test "creates a Tesla client with valid options" do
      client = new_client(adapter: Tesla.Mock)

      assert %Tesla.Client{} = client
      # BaseUrl, Headers, BasicAuth, JSON middlewares
      assert length(client.pre) == 4
    end

    test "creates client with custom headers" do
      client =
        new_client(
          adapter: Tesla.Mock,
          headers: [{"custom-header", "value"}]
        )

      assert %Tesla.Client{} = client
    end

    test "validates options" do
      assert_raise NimbleOptions.ValidationError, fn ->
        RPC.client(adapter: "invalid")
      end
    end
  end

  describe "call/2" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      method =
        CreateWallet.new!(
          wallet_name: "test_wallet",
          passphrase: "test_pass",
          descriptors: true
        )

      %{client: client, method: method}
    end

    test "successful method returns ok tuple", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{"name" => "test_wallet", "warning" => ""},
              "error" => nil
            }
          }
      end)

      assert {:ok, %Response{id: "test-id", result: result}} = RPC.call(client, method)
      assert result["name"] == "test_wallet"
    end

    test "HTTP 400 returns bad method error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 400, body: "Bad method"}
      end)

      assert {:error, %BTx.RPC.Error{reason: :http_bad_request}} = RPC.call(client, method)
    end

    test "HTTP 401 returns unauthorized error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert {:error, %BTx.RPC.Error{reason: :http_unauthorized}} = RPC.call(client, method)
    end

    test "HTTP 403 returns forbidden error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 403, body: "Forbidden"}
      end)

      assert {:error, %BTx.RPC.Error{reason: :http_forbidden}} = RPC.call(client, method)
    end

    test "HTTP 404 returns not found error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 404, body: "Not Found"}
      end)

      assert {:error, %BTx.RPC.Error{reason: :http_not_found}} = RPC.call(client, method)
    end

    test "HTTP 405 returns method not allowed error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 405, body: "Method Not Allowed"}
      end)

      assert {:error, %BTx.RPC.Error{reason: :http_method_not_allowed}} =
               RPC.call(client, method)
    end

    test "HTTP 503 returns service unavailable error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 503, body: "Service Unavailable"}
      end)

      assert {:error, %BTx.RPC.Error{reason: :http_service_unavailable}} =
               RPC.call(client, method)
    end

    test "JSON-RPC error with HTTP 500 returns method error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -18,
                "message" => "methoded wallet does not exist or is not loaded"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{id: "test-id", code: -18, message: message}} =
               RPC.call(client, method)

      assert message == "methoded wallet does not exist or is not loaded"
    end

    test "JSON-RPC error with HTTP 200 returns method error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -6,
                "message" => "Insufficient funds"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{id: "test-id", code: -6, message: "Insufficient funds"}} =
               RPC.call(client, method)
    end

    test "unknown HTTP status returns unknown error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 599,
            body: "Unknown Error"
          }
      end)

      assert {:error, %BTx.RPC.Error{reason: :unknown_error, metadata: metadata}} =
               RPC.call(client, method)

      assert Keyword.get(metadata, :status) == 599
      assert Keyword.get(metadata, :body) == "Unknown Error"
    end

    test "Tesla adapter error returns error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          {:error, :timeout}
      end)

      assert {:error, %BTx.RPC.Error{reason: :timeout, metadata: metadata}} =
               RPC.call(client, method)

      assert Keyword.has_key?(metadata, :method)
    end

    test "connection refused error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          {:error, :econnrefused}
      end)

      assert {:error, %BTx.RPC.Error{reason: :econnrefused}} = RPC.call(client, method)
    end

    test "retryable error", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 503, body: "Service Unavailable"}
      end)

      assert {:error, %BTx.RPC.Error{reason: :http_service_unavailable}} =
               RPC.call(client, method, retries: 2, retry_delay: 1)
    end

    test "retryable error with function retry delay", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 503, body: "Service Unavailable"}
      end)

      assert {:error, %BTx.RPC.Error{reason: :http_service_unavailable}} =
               RPC.call(client, method, retries: 3, retry_delay: fn n -> n end)
    end

    test "retryable error with function retry delay and retryable errors", %{
      client: client,
      method: method
    } do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 503, body: "Service Unavailable"}
      end)

      assert {:error, %BTx.RPC.Error{reason: :http_service_unavailable}} =
               RPC.call(client, method,
                 retries: 3,
                 retry_delay: fn n -> n end,
                 retryable_errors: [:http_service_unavailable]
               )
    end
  end

  describe "call!/2" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      method =
        CreateWallet.new!(
          wallet_name: "test_wallet",
          passphrase: "test_pass",
          descriptors: true
        )

      %{client: client, method: method}
    end

    test "successful method returns response struct", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{"name" => "test_wallet"},
              "error" => nil
            }
          }
      end)

      assert %Response{id: "test-id", result: result} = RPC.call!(client, method)
      assert result["name"] == "test_wallet"
    end

    test "error raises exception", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        RPC.call!(client, method)
      end
    end

    test "method error raises MethodError exception", %{client: client, method: method} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 500,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -18,
                "message" => "Wallet does not exist"
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, "Wallet does not exist", fn ->
        RPC.call!(client, method)
      end
    end
  end

  describe "integration with real Bitcoin regtest" do
    @tag :integration
    test "can connect to regtest node" do
      client = new_client()
      wallet_name = "integration-test-#{UUID.generate()}"

      method = CreateWallet.new!(wallet_name: wallet_name, passphrase: "test")

      # This should work if regtest is running
      # You can skip this test if regtest is not available
      assert %Response{id: ^wallet_name, result: %{"name" => ^wallet_name}} =
               RPC.call!(client, method, id: wallet_name, retries: 10)

      assert_raise BTx.RPC.MethodError, ~r/already exists/, fn ->
        RPC.call!(client, method, id: wallet_name, retries: 10)
      end
    end
  end
end
