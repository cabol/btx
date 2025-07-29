defmodule BTx.RPC.Blockchain.GetBlockCountTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import Tesla.Mock

  alias BTx.RPC.{Blockchain, Encodable, Request}
  alias BTx.RPC.Blockchain.GetBlockCount

  @url "http://localhost:18443/"

  ## GetBlockCount schema tests

  describe "GetBlockCount.new/0" do
    test "creates a new GetBlockCount with no parameters" do
      assert {:ok, %GetBlockCount{}} = GetBlockCount.new()
    end
  end

  describe "GetBlockCount.new!/0" do
    test "creates a new GetBlockCount with no parameters" do
      assert %GetBlockCount{} = GetBlockCount.new!()
    end
  end

  describe "GetBlockCount encodable" do
    test "encodes method with no parameters" do
      assert %Request{
               params: [],
               method: "getblockcount",
               jsonrpc: "1.0",
               path: "/"
             } = GetBlockCount.new!() |> Encodable.encode()
    end
  end

  describe "GetBlockCount changeset/2" do
    test "accepts empty parameters" do
      changeset = GetBlockCount.changeset(%GetBlockCount{}, %{})
      assert changeset.valid?
    end
  end

  ## Blockchain RPC tests

  describe "(RPC) Blockchain.get_block_count/2" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns block count", %{client: client} do
      block_count = 750_123

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "getblockcount",
                   "params" => [],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => block_count,
              "error" => nil
            }
          }
      end)

      assert {:ok, ^block_count} = Blockchain.get_block_count(client)
    end

    test "handles error response", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -1,
                "message" => "RPC server error"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -1, message: "RPC server error"}} =
               Blockchain.get_block_count(client)
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node
      real_client = new_client()

      assert {:ok, block_count} = Blockchain.get_block_count(real_client, retries: 10)
      assert is_integer(block_count)
      assert block_count >= 0
    end
  end

  describe "(RPC) Blockchain.get_block_count!/1" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns block count on success", %{client: client} do
      block_count = 123_456

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => block_count,
              "error" => nil
            }
          }
      end)

      assert ^block_count = Blockchain.get_block_count!(client)
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -1,
                "message" => "RPC server error"
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, fn ->
        Blockchain.get_block_count!(client)
      end
    end
  end
end
