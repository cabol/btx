defmodule BTx.RPC.Blockchain.GetBlockTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.BlockchainFixtures
  import Tesla.Mock

  alias BTx.RPC.{Blockchain, Encodable, Request}
  alias BTx.RPC.Blockchain.{GetBlock, GetBlockResultV1, GetBlockResultV2}
  alias BTx.RPC.RawTransactions.GetRawTransactionResult
  alias Ecto.Changeset

  @url "http://localhost:18443/"
  @valid_blockhash "0000000000000a1b2c3d4e5f6789abcdef0123456789abcdef0123456789abcd"

  ## GetBlock schema tests

  describe "GetBlock.new/1" do
    test "creates a new GetBlock with required fields" do
      assert {:ok, %GetBlock{} = request} =
               GetBlock.new(blockhash: @valid_blockhash)

      assert request.blockhash == @valid_blockhash
      # default
      assert request.verbosity == 1
    end

    test "creates a new GetBlock with custom verbosity" do
      assert {:ok, %GetBlock{} = request} =
               GetBlock.new(blockhash: @valid_blockhash, verbosity: 2)

      assert request.blockhash == @valid_blockhash
      assert request.verbosity == 2
    end

    test "validates required blockhash field" do
      assert {:error, %Changeset{} = changeset} = GetBlock.new(%{})
      assert "can't be blank" in errors_on(changeset).blockhash
    end

    test "validates blockhash format" do
      assert {:error, %Changeset{} = changeset} =
               GetBlock.new(blockhash: "invalid")

      errors = errors_on(changeset).blockhash
      assert "has invalid format" in errors
      assert "should be 64 character(s)" in errors
    end

    test "validates verbosity inclusion" do
      for valid_verbosity <- [0, 1, 2] do
        assert {:ok, %GetBlock{}} =
                 GetBlock.new(blockhash: @valid_blockhash, verbosity: valid_verbosity)
      end

      # Invalid verbosity
      assert {:error, %Changeset{} = changeset} =
               GetBlock.new(blockhash: @valid_blockhash, verbosity: 3)

      assert "is invalid" in errors_on(changeset).verbosity
    end
  end

  describe "GetBlock.new!/1" do
    test "creates a new GetBlock with valid params" do
      assert %GetBlock{} =
               GetBlock.new!(blockhash: @valid_blockhash, verbosity: 0)
    end

    test "raises error for invalid params" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetBlock.new!(blockhash: "invalid")
      end
    end
  end

  describe "GetBlock encodable" do
    test "encodes method with required fields only" do
      assert %Request{
               params: [@valid_blockhash, 1],
               method: "getblock",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetBlock.new!(blockhash: @valid_blockhash)
               |> Encodable.encode()
    end

    test "encodes method with custom verbosity" do
      assert %Request{
               params: [@valid_blockhash, 0],
               method: "getblock",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetBlock.new!(blockhash: @valid_blockhash, verbosity: 0)
               |> Encodable.encode()
    end

    test "encodes method with verbosity 2" do
      assert %Request{
               params: [@valid_blockhash, 2],
               method: "getblock",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetBlock.new!(blockhash: @valid_blockhash, verbosity: 2)
               |> Encodable.encode()
    end
  end

  ## GetBlockResultV1 tests

  describe "GetBlockResultV1.new/1" do
    test "creates result from valid block data" do
      attrs = get_block_result_v1_fixture()

      assert {:ok, %GetBlockResultV1{} = result} =
               GetBlockResultV1.new(attrs)

      assert result.hash == @valid_blockhash
      assert result.height == 750_123
      assert length(result.tx) == 2
      assert is_list(result.tx)
      # Verify tx contains transaction ID strings
      assert Enum.all?(result.tx, &is_binary/1)
    end

    test "validates hash format" do
      attrs = get_block_result_v1_fixture(%{"hash" => "invalid"})

      assert {:error, %Changeset{} = changeset} = GetBlockResultV1.new(attrs)

      errors = errors_on(changeset).hash
      assert "has invalid format" in errors
      assert "should be 64 character(s)" in errors
    end

    test "validates version hex format" do
      attrs = get_block_result_v1_fixture(%{"versionHex" => "invalid"})

      assert {:error, %Changeset{} = changeset} = GetBlockResultV1.new(attrs)

      errors = errors_on(changeset).version_hex
      assert "has invalid format" in errors
      assert "should be 8 character(s)" in errors
    end

    test "validates bits format" do
      attrs = get_block_result_v1_fixture(%{"bits" => "invalid"})

      assert {:error, %Changeset{} = changeset} = GetBlockResultV1.new(attrs)

      errors = errors_on(changeset).bits
      assert "has invalid format" in errors
      assert "should be 8 character(s)" in errors
    end
  end

  ## GetBlockResultV2 tests

  describe "GetBlockResultV2.new/1" do
    test "creates result from valid block data with transaction details" do
      attrs = get_block_result_v2_fixture()

      assert {:ok, %GetBlockResultV2{} = result} =
               GetBlockResultV2.new(attrs)

      assert result.hash == @valid_blockhash
      assert result.height == 750_123
      assert length(result.tx) == 2
      # Verify tx contains GetRawTransactionResult structs
      assert Enum.all?(result.tx, fn tx -> match?(%GetRawTransactionResult{}, tx) end)
    end
  end

  ## Blockchain RPC tests

  describe "(RPC) Blockchain.get_block/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns hex string when verbosity=0", %{client: client} do
      hex_result = get_block_hex_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getblock",
                   "params" => [@valid_blockhash, 0],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => hex_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, ^hex_result} =
               Blockchain.get_block(client, blockhash: @valid_blockhash, verbosity: 0)
    end

    test "successful call returns structured object when verbosity=1", %{client: client} do
      block_result = get_block_result_v1_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getblock",
                   "params" => [@valid_blockhash, 1],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => block_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetBlockResultV1{} = result} =
               Blockchain.get_block(client, blockhash: @valid_blockhash, verbosity: 1)

      assert result.hash == @valid_blockhash
      assert result.height == 750_123
      assert length(result.tx) == 2
    end

    test "successful call returns structured object with transaction details when verbosity=2", %{
      client: client
    } do
      block_result = get_block_result_v2_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "getblock",
                   "params" => [@valid_blockhash, 2],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => block_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetBlockResultV2{} = result} =
               Blockchain.get_block(client, blockhash: @valid_blockhash, verbosity: 2)

      assert result.hash == @valid_blockhash
      assert result.height == 750_123
      assert length(result.tx) == 2
      assert Enum.all?(result.tx, fn tx -> match?(%GetRawTransactionResult{}, tx) end)
    end

    test "handles block not found error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -5,
                "message" => "Block not found"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -5, message: "Block not found"}} =
               Blockchain.get_block(client, blockhash: @valid_blockhash)
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node
      real_client = new_client()

      assert {:ok, blockchain_info} = Blockchain.get_blockchain_info(real_client)

      blockhash = blockchain_info.bestblockhash

      # Test hex format (verbosity=0)
      assert {:ok, hex_string} =
               Blockchain.get_block(real_client,
                 blockhash: blockhash,
                 verbosity: 0
               )

      assert is_binary(hex_string)
      assert String.match?(hex_string, ~r/^[a-fA-F0-9]+$/)

      # Test block with transaction IDs (verbosity=1)
      assert {:ok, %GetBlockResultV1{} = result_v1} =
               Blockchain.get_block(real_client,
                 blockhash: blockhash,
                 verbosity: 1
               )

      assert result_v1.hash == blockhash
      assert is_integer(result_v1.height)
      assert result_v1.height >= 0
      assert is_list(result_v1.tx)
      assert Enum.all?(result_v1.tx, &is_binary/1)

      # Test block with transaction details (verbosity=2)
      assert {:ok, %GetBlockResultV2{} = result_v2} =
               Blockchain.get_block(real_client,
                 blockhash: blockhash,
                 verbosity: 2
               )

      assert result_v2.hash == blockhash
      assert result_v2.height == result_v1.height
      assert is_list(result_v2.tx)
      assert Enum.all?(result_v2.tx, fn tx -> match?(%GetRawTransactionResult{}, tx) end)
    end
  end

  describe "(RPC) Blockchain.get_block!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns hex string on success", %{client: client} do
      hex_result = get_block_hex_fixture()

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => hex_result,
              "error" => nil
            }
          }
      end)

      assert ^hex_result =
               Blockchain.get_block!(client, blockhash: @valid_blockhash, verbosity: 0)
    end

    test "returns GetBlockResultV1 on success", %{client: client} do
      block_result = get_block_result_v1_fixture()

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => block_result,
              "error" => nil
            }
          }
      end)

      assert %GetBlockResultV1{} =
               Blockchain.get_block!(client, blockhash: @valid_blockhash, verbosity: 1)
    end

    test "raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Blockchain.get_block!(client, blockhash: @valid_blockhash)
      end
    end
  end

  ## Helper functions for tests

  # defp get_block_hex_fixture do
  #   "010000000000000000000000000000000000000000000000000000000000000000000000 " <>
  #     "3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d1dac2b7c"
  # end

  # defp get_block_result_v1_fixture(overrides \\ %{}) do
  #   %{
  #     "hash" => @valid_blockhash,
  #     "confirmations" => 100,
  #     "size" => 285,
  #     "strippedsize" => 249,
  #     "weight" => 1140,
  #     "height" => 750_123,
  #     "version" => 1,
  #     "versionHex" => "00000001",
  #     "merkleroot" => "3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a",
  #     "tx" => [
  #       "3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a",
  #       "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"
  #     ],
  #     "time" => 1_640_995_200,
  #     "mediantime" => 1_640_995_000,
  #     "nonce" => 486_604_799,
  #     "bits" => "1d00ffff",
  #     "difficulty" => 1.0,
  #     "chainwork" => "0000000000000000000000000000000000000000000000000000000100010001",
  #     "nTx" => 2,
  #     "previousblockhash" => "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f",
  #     "nextblockhash" => "00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048"
  #   }
  #   |> Map.merge(overrides)
  # end

  # defp get_block_result_v2_fixture(overrides \\ %{}) do
  #   base_v1 = get_block_result_v1_fixture()

  #   %{
  #     base_v1
  #     | "tx" => [
  #         get_raw_transaction_result_fixture(%{
  #           "txid" => "3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a"
  #         }),
  #         get_raw_transaction_result_fixture(%{
  #           "txid" => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"
  #         })
  #       ]
  #   }
  #   |> Map.merge(overrides)
  # end
end
