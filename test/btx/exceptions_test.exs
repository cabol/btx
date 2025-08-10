defmodule BTx.ExceptionsTest do
  use ExUnit.Case, async: true

  alias BTx.RPC.{Error, MethodError}

  describe "BTx.RPC.Error exception" do
    test "formats RPC error messages correctly" do
      error_types = [
        {:http_bad_request, "Bad Request"},
        {:http_unauthorized, "Unauthorized"},
        {:http_forbidden, "Forbidden"},
        {:http_not_found, "Not Found"},
        {:http_method_not_allowed, "Method Not Allowed"},
        {:http_internal_server_error, "Internal Server Error"},
        {:http_bad_gateway, "Bad Gateway"},
        {:http_service_unavailable, "Service Unavailable"},
        {:http_gateway_timeout, "Gateway Timeout"},
        {:unknown_error, "Unknown Error"},
        {:econnrefused, "connection refused"},
        {:timeout, "timeout"},
        {:nxdomain, "non-existing domain"}
      ]

      for {reason, expected_prefix} <- error_types do
        error = %Error{reason: reason, metadata: []}
        message = Exception.message(error)
        assert message =~ expected_prefix
      end
    end

    test "includes metadata in error messages" do
      error = %Error{
        reason: :unknown_error,
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
    test "maps error codes to reasons correctly" do
      # Test some common error codes
      error_codes_and_reasons = [
        {-1, :misc_error},
        {-3, :type_error},
        {-4, :wallet_error},
        {-6, :wallet_insufficient_funds},
        {-8, :invalid_parameter},
        {-13, :wallet_unlock_needed},
        {-18, :wallet_not_found},
        {-32_602, :invalid_params},
        {-32_603, :internal_error}
      ]

      for {code, expected_reason} <- error_codes_and_reasons do
        assert MethodError.reason(code) == expected_reason
      end
    end

    test "handles unknown error codes" do
      assert MethodError.reason(999_999) == :unknown_error
    end

    test "maps all wallet error codes" do
      wallet_error_codes = [-4, -6, -11, -12, -13, -14, -15, -16, -17, -18, -19, -35, -36]

      for code <- wallet_error_codes do
        reason = MethodError.reason(code)
        assert reason in ~w(wallet_error wallet_insufficient_funds wallet_invalid_label_name
                           wallet_keypool_ran_out wallet_unlock_needed wallet_passphrase_incorrect
                           wallet_wrong_enc_state wallet_encryption_failed wallet_already_unlocked
                           wallet_not_found wallet_not_specified wallet_already_loaded
                           wallet_already_exists)a
      end
    end

    test "maps all validation error codes" do
      validation_error_codes = [-3, -5, -8, -11, -32_602]

      for code <- validation_error_codes do
        reason = MethodError.reason(code)
        assert reason in ~w(type_error invalid_address_or_key invalid_parameter
                           wallet_invalid_label_name invalid_params)a
      end
    end

    test "maps all connection error codes" do
      connection_error_codes = [-9, -10, -29, -31]

      for code <- connection_error_codes do
        reason = MethodError.reason(code)
        assert reason in ~w(client_not_connected client_in_initial_download
                           client_node_not_connected client_p2p_disabled)a
      end
    end

    test "formats error message correctly" do
      error = %MethodError{
        id: "test-id",
        code: -6,
        message: "Insufficient funds",
        reason: :wallet_insufficient_funds
      }

      message = Exception.message(error)
      assert message == "Insufficient funds"
    end
  end
end
