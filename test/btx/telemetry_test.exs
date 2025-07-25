defmodule BTx.TelemetryTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC
  alias BTx.RPC.Wallets.CreateWallet
  alias Ecto.UUID

  describe "BTx.RPC.call/2" do
    @prefix [:btx, :rpc, :call]
    @start_event @prefix ++ [:start]
    @stop_event @prefix ++ [:stop]
    @exception_event @prefix ++ [:exception]

    @events [@start_event, @stop_event, @exception_event]

    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "emits telemetry start and stop events", %{client: client} do
      with_telemetry_handler self(), @events, fn ->
        mock(fn _ ->
          %Tesla.Env{
            status: 200,
            body: %{"id" => "test", "result" => %{"name" => "test"}, "error" => nil}
          }
        end)

        id = UUID.generate()
        request = CreateWallet.new!(wallet_name: id, passphrase: "test")

        assert {:ok, _} = RPC.call(client, request, id: id)

        assert_receive {@start_event, %{system_time: _}, %{id: ^id} = meta}

        assert meta.client == client
        assert meta.method == "createwallet"
        assert meta.method_object == request

        assert_receive {@stop_event, %{duration: _}, %{id: ^id} = meta}

        assert meta.client == client
        assert meta.method == "createwallet"
        assert meta.status == :ok
        assert meta.result.id == "test"
        assert meta.result.result == %{"name" => "test"}

        refute_receive {@exception_event, _, %{id: ^id}}
      end
    end

    test "emits telemetry exception event", %{client: client} do
      with_telemetry_handler self(), @events, fn ->
        mock(fn _ ->
          raise "test error"
        end)

        id = UUID.generate()
        request = CreateWallet.new!(wallet_name: "test", passphrase: "test")

        assert_raise RuntimeError, fn ->
          RPC.call(client, request, id: id)
        end

        assert_receive {@start_event, %{system_time: _}, %{id: ^id} = meta}

        assert meta.client == client
        assert meta.method == "createwallet"
        assert meta.method_object == request

        assert_receive {@exception_event, %{duration: _}, %{id: ^id} = meta}

        assert meta.client == client
        assert meta.method == "createwallet"
        assert meta.kind == :error
        assert meta.reason == %RuntimeError{message: "test error"}

        refute_receive {@stop_event, _, %{id: ^id}}
      end
    end
  end
end
