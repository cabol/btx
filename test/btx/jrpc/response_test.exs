defmodule BTx.JRPC.ResponseTest do
  use ExUnit.Case, async: true

  alias BTx.JRPC.{Error, MethodError, Response}

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
        {400, {:rpc, :bad_request}},
        {401, {:rpc, :unauthorized}},
        {403, {:rpc, :forbidden}},
        {404, :not_found},
        {405, {:rpc, :method_not_allowed}},
        {503, {:rpc, :service_unavailable}}
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

      assert {:error, %Error{reason: {:rpc, :unknown_error}, metadata: metadata}} =
               Response.new(env)

      assert Keyword.get(metadata, :status) == 418
      assert Keyword.get(metadata, :body) == "I'm a teapot"
    end
  end
end
