defmodule BTx.ExceptionsTest do
  use ExUnit.Case, async: true

  alias BTx.RPC.{Error, MethodError}

  describe "BTx.RPC.Error exception" do
    test "formats RPC error messages correctly" do
      error_types = [
        {{:rpc, :bad_request}, "Bad Request"},
        {{:rpc, :unauthorized}, "Unauthorized"},
        {{:rpc, :forbidden}, "Forbidden"},
        {{:rpc, :not_found}, "Not Found"},
        {{:rpc, :method_not_allowed}, "Method Not Allowed"},
        {{:rpc, :service_unavailable}, "Service Unavailable"},
        {{:rpc, :unknown_error}, "Unknown Error"}
      ]

      for {reason, expected_prefix} <- error_types do
        error = %Error{reason: reason, metadata: []}
        message = Exception.message(error)
        assert message =~ expected_prefix
      end
    end

    test "includes metadata in error messages" do
      error = %Error{
        reason: {:rpc, :unknown_error},
        metadata: [status: 502, body: "Bad Gateway"]
      }

      message = Exception.message(error)
      assert message =~ "Error metadata:"
      assert message =~ "status: 502"
    end

    test "formats exception errors" do
      exception = %RuntimeError{message: "Something went wrong"}
      error = %Error{reason: exception, metadata: [stacktrace: []]}

      message = Exception.message(error)
      assert message =~ "the following exception occurred"
      assert message =~ "Something went wrong"
    end

    test "formats other exceptions" do
      error = %Error{reason: :other, metadata: [stacktrace: []]}

      message = Exception.message(error)
      assert message =~ "JSON RPC request failed with reason: :other"
    end
  end

  describe "BTx.RPC.MethodError exception" do
    test "creates method error with required fields" do
      error = %MethodError{id: "test-id", code: -18, message: "Wallet not found"}

      assert error.id == "test-id"
      assert error.code == -18
      assert error.message == "Wallet not found"
      assert Exception.message(error) == "Wallet not found"
    end

    test "exception/1 creates from keyword list" do
      error = MethodError.exception(id: "test", code: -1, message: "Test error")

      assert %MethodError{id: "test", code: -1, message: "Test error"} = error
    end
  end
end
