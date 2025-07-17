defmodule BTx.JRPCTest do
  use ExUnit.Case, async: true

  import Tesla.Mock

  alias BTx.JRPC
  alias BTx.JRPC.Response
  alias BTx.JRPC.Wallet.CreateWallet
  alias Ecto.UUID

  @base_url "http://localhost:18443"
  @username "btx-user"
  @password "btx-pass"

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
        JRPC.client(adapter: "invalid")
      end
    end
  end

  describe "call/2" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      request =
        CreateWallet.new!(
          wallet_name: "test_wallet",
          passphrase: "test_pass",
          descriptors: true
        )

      %{client: client, request: request}
    end

    test "successful request returns ok tuple", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{"name" => "test_wallet", "warning" => ""},
              "error" => nil
            }
          }
      end)

      assert {:ok, %Response{id: "test-id", result: result}} = JRPC.call(client, request)
      assert result["name"] == "test_wallet"
    end

    test "HTTP 400 returns bad request error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          %Tesla.Env{status: 400, body: "Bad Request"}
      end)

      assert {:error, %BTx.JRPC.Error{reason: {:rpc, :bad_request}}} = JRPC.call(client, request)
    end

    test "HTTP 401 returns unauthorized error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert {:error, %BTx.JRPC.Error{reason: {:rpc, :unauthorized}}} = JRPC.call(client, request)
    end

    test "HTTP 403 returns forbidden error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          %Tesla.Env{status: 403, body: "Forbidden"}
      end)

      assert {:error, %BTx.JRPC.Error{reason: {:rpc, :forbidden}}} = JRPC.call(client, request)
    end

    test "HTTP 404 returns not found error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          %Tesla.Env{status: 404, body: "Not Found"}
      end)

      assert {:error, %BTx.JRPC.Error{reason: :not_found}} = JRPC.call(client, request)
    end

    test "HTTP 405 returns method not allowed error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          %Tesla.Env{status: 405, body: "Method Not Allowed"}
      end)

      assert {:error, %BTx.JRPC.Error{reason: {:rpc, :method_not_allowed}}} =
               JRPC.call(client, request)
    end

    test "HTTP 503 returns service unavailable error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          %Tesla.Env{status: 503, body: "Service Unavailable"}
      end)

      assert {:error, %BTx.JRPC.Error{reason: {:rpc, :service_unavailable}}} =
               JRPC.call(client, request)
    end

    test "JSON-RPC error with HTTP 500 returns method error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
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

      assert {:error, %BTx.JRPC.MethodError{id: "test-id", code: -18, message: message}} =
               JRPC.call(client, request)

      assert message == "Requested wallet does not exist or is not loaded"
    end

    test "JSON-RPC error with HTTP 200 returns method error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
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

      assert {:error,
              %BTx.JRPC.MethodError{id: "test-id", code: -6, message: "Insufficient funds"}} =
               JRPC.call(client, request)
    end

    test "unknown HTTP status returns unknown error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          %Tesla.Env{
            status: 502,
            body: "Bad Gateway"
          }
      end)

      assert {:error, %BTx.JRPC.Error{reason: {:rpc, :unknown_error}, metadata: metadata}} =
               JRPC.call(client, request)

      assert Keyword.get(metadata, :status) == 502
      assert Keyword.get(metadata, :body) == "Bad Gateway"
    end

    test "Tesla adapter error returns error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          {:error, :timeout}
      end)

      assert {:error, %BTx.JRPC.Error{reason: :timeout, metadata: metadata}} =
               JRPC.call(client, request)

      assert Keyword.has_key?(metadata, :request)
    end

    test "connection refused error", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          {:error, :econnrefused}
      end)

      assert {:error, %BTx.JRPC.Error{reason: :econnrefused}} = JRPC.call(client, request)
    end
  end

  describe "call!/2" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      request =
        CreateWallet.new!(
          wallet_name: "test_wallet",
          passphrase: "test_pass",
          descriptors: true
        )

      %{client: client, request: request}
    end

    test "successful request returns response struct", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => %{"name" => "test_wallet"},
              "error" => nil
            }
          }
      end)

      assert %Response{id: "test-id", result: result} = JRPC.call!(client, request)
      assert result["name"] == "test_wallet"
    end

    test "error raises exception", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.JRPC.Error, ~r/Unauthorized/, fn ->
        JRPC.call!(client, request)
      end
    end

    test "method error raises MethodError exception", %{client: client, request: request} do
      mock(fn
        %{method: :post, url: "http://localhost:18443/"} ->
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

      assert_raise BTx.JRPC.MethodError, "Wallet does not exist", fn ->
        JRPC.call!(client, request)
      end
    end
  end

  describe "integration with real Bitcoin regtest" do
    @tag :integration
    test "can connect to regtest node" do
      client = new_client()
      wallet_name = "integration_test_#{UUID.generate()}"

      request = CreateWallet.new!(wallet_name: wallet_name, passphrase: "test")

      # This should work if regtest is running
      # You can skip this test if regtest is not available
      assert %Response{id: ^wallet_name, result: %{"name" => ^wallet_name}} =
               JRPC.call!(client, request, id: wallet_name)

      assert_raise BTx.JRPC.MethodError, ~r/already exists/, fn ->
        JRPC.call!(client, request, id: wallet_name)
      end
    end
  end

  ## Private functions

  defp new_client(opts \\ []) do
    [
      base_url: @base_url,
      username: @username,
      password: @password
    ]
    |> Keyword.merge(opts)
    |> JRPC.client()
  end
end
