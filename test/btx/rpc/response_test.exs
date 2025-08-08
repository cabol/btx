defmodule BTx.RPC.ResponseTest do
  use ExUnit.Case, async: true

  alias BTx.RPC.{Error, MethodError, Response}

  describe "Response.new/1" do
    test "creates response from successful Tesla.Env" do
      env = %Tesla.Env{
        status: 200,
        body: %{
          "id" => "test-id",
          "result" => %{"key" => "value"},
          "error" => nil
        }
      }

      assert {:ok, %Response{id: "test-id", result: %{"key" => "value"}}} = Response.new(env)
    end

    test "handles various HTTP error statuses" do
      statuses_and_reasons = [
        {400, :http_bad_request},
        {401, :http_unauthorized},
        {403, :http_forbidden},
        {404, :http_not_found},
        {405, :http_method_not_allowed},
        {500, :http_internal_server_error},
        {502, :http_bad_gateway},
        {503, :http_service_unavailable},
        {504, :http_gateway_timeout}
      ]

      for {status, expected_reason} <- statuses_and_reasons do
        env = %Tesla.Env{status: status, body: "Error"}
        assert {:error, %Error{reason: ^expected_reason}} = Response.new(env)
      end
    end

    test "handles JSON-RPC errors" do
      env = %Tesla.Env{
        status: 500,
        body: %{
          "id" => "test-id",
          "result" => nil,
          "error" => %{
            "code" => -32_602,
            "message" => "Invalid params"
          }
        }
      }

      assert {:error, %MethodError{id: "test-id", code: -32_602, message: "Invalid params"}} =
               Response.new(env)
    end

    test "handles unknown status codes" do
      env = %Tesla.Env{
        # I'm a teapot
        status: 418,
        body: "I'm a teapot"
      }

      assert {:error, %Error{reason: :unknown_error, metadata: metadata}} =
               Response.new(env)

      assert Keyword.get(metadata, :status) == 418
      assert Keyword.get(metadata, :body) == "I'm a teapot"
    end
  end
end
