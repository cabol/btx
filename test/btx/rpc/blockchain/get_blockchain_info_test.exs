defmodule BTx.RPC.Blockchain.GetBlockchainInfoTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.BlockchainFixtures
  import Tesla.Mock

  alias BTx.RPC.{Blockchain, Encodable, Request}
  alias BTx.RPC.Blockchain.Commons.Softfork
  alias BTx.RPC.Blockchain.Commons.Softfork.Bip9
  alias BTx.RPC.Blockchain.Commons.Softfork.Bip9.Statistics
  alias BTx.RPC.Blockchain.{GetBlockchainInfo, GetBlockchainInfoResult}
  alias Ecto.Changeset

  @url "http://localhost:18443/"

  ## GetBlockchainInfo schema tests

  describe "GetBlockchainInfo.new/0" do
    test "creates a new GetBlockchainInfo with no parameters" do
      assert {:ok, %GetBlockchainInfo{}} = GetBlockchainInfo.new()
    end
  end

  describe "GetBlockchainInfo.new!/0" do
    test "creates a new GetBlockchainInfo with no parameters" do
      assert %GetBlockchainInfo{} = GetBlockchainInfo.new!()
    end
  end

  describe "GetBlockchainInfo encodable" do
    test "encodes method with no parameters" do
      assert %Request{
               params: [],
               method: "getblockchaininfo",
               jsonrpc: "1.0",
               path: "/"
             } = GetBlockchainInfo.new!() |> Encodable.encode()
    end
  end

  describe "GetBlockchainInfo changeset/2" do
    test "accepts empty parameters" do
      changeset = GetBlockchainInfo.changeset(%GetBlockchainInfo{}, %{})
      assert changeset.valid?
    end
  end

  ## Nested schema tests

  describe "Statistics changeset/2" do
    test "validates required fields" do
      attrs = %{
        "period" => 2016,
        "threshold" => 1916,
        "elapsed" => 1000,
        "count" => 1850,
        "possible" => true
      }

      changeset = Statistics.changeset(%Statistics{}, attrs)
      assert changeset.valid?
    end
  end

  describe "Bip9 changeset/2" do
    test "validates required fields" do
      attrs = %{
        "status" => "active",
        "since" => 709_632
      }

      changeset = Bip9.changeset(%Bip9{}, attrs)
      assert changeset.valid?
    end

    test "validates with statistics" do
      attrs = %{
        "status" => "started",
        "bit" => 2,
        "start_time" => 1_619_222_400,
        "timeout" => 1_628_640_000,
        "since" => 700_000,
        "statistics" => bip9_statistics_fixture()
      }

      changeset = Bip9.changeset(%Bip9{}, attrs)
      assert changeset.valid?

      applied = Changeset.apply_changes(changeset)
      assert applied.statistics.period == 2016
      assert applied.statistics.possible == true
    end

    test "validates status inclusion" do
      valid_statuses = ~w(defined started locked_in active failed)

      for status <- valid_statuses do
        attrs = %{"status" => status, "since" => 123}
        changeset = Bip9.changeset(%Bip9{}, attrs)
        assert changeset.valid?
      end

      # Invalid status
      attrs = %{"status" => "invalid", "since" => 123}
      changeset = Bip9.changeset(%Bip9{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).status
    end
  end

  describe "Softfork changeset/2" do
    test "validates buried softfork" do
      attrs = buried_softfork_fixture()
      changeset = Softfork.changeset(%Softfork{}, attrs)
      assert changeset.valid?

      applied = Changeset.apply_changes(changeset)
      assert applied.type == "buried"
      assert applied.active == true
      assert applied.height == 0
    end

    test "validates bip9 softfork" do
      attrs = bip9_softfork_fixture()
      changeset = Softfork.changeset(%Softfork{}, attrs)
      assert changeset.valid?

      applied = Changeset.apply_changes(changeset)
      assert applied.type == "bip9"
      assert applied.active == true
      assert applied.bip9.status == "active"
    end

    test "validates type inclusion" do
      valid_types = ~w(buried bip9)

      for type <- valid_types do
        attrs = %{"type" => type, "active" => true}
        changeset = Softfork.changeset(%Softfork{}, attrs)
        assert changeset.valid?
      end

      # Invalid type
      attrs = %{"type" => "invalid", "active" => true}
      changeset = Softfork.changeset(%Softfork{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).type
    end

    test "requires type and active" do
      changeset = Softfork.changeset(%Softfork{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).type
      assert "can't be blank" in errors_on(changeset).active
    end
  end

  ## GetBlockchainInfoResult tests

  describe "GetBlockchainInfoResult.new/1" do
    test "creates result with required fields" do
      attrs = get_blockchain_info_preset(:regtest)

      assert {:ok, %GetBlockchainInfoResult{} = result} = GetBlockchainInfoResult.new(attrs)
      assert result.chain == "regtest"
      assert result.blocks == 150
      assert result.headers == 150
      assert result.pruned == false
      assert is_map(result.softforks)
    end

    test "creates result for mainnet" do
      attrs = get_blockchain_info_preset(:mainnet)

      assert {:ok, %GetBlockchainInfoResult{} = result} = GetBlockchainInfoResult.new(attrs)
      assert result.chain == "main"
      assert result.blocks == 750_000
      assert result.difficulty > 30_000_000_000_000
      assert result.pruned == false
    end

    test "creates result for testnet" do
      attrs = get_blockchain_info_preset(:testnet)

      assert {:ok, %GetBlockchainInfoResult{} = result} = GetBlockchainInfoResult.new(attrs)
      assert result.chain == "test"
      assert result.blocks == 2_100_000
      assert result.pruned == false
    end

    test "creates result with pruning enabled" do
      attrs = get_blockchain_info_preset(:pruned)

      assert {:ok, %GetBlockchainInfoResult{} = result} = GetBlockchainInfoResult.new(attrs)
      assert result.pruned == true
      assert result.pruneheight == 500_000
      assert result.automatic_pruning == true
      assert result.prune_target_size == 5500
    end

    test "creates result while syncing" do
      attrs = get_blockchain_info_preset(:syncing)

      assert {:ok, %GetBlockchainInfoResult{} = result} = GetBlockchainInfoResult.new(attrs)
      assert result.blocks == 700_000
      assert result.headers == 750_000
      assert result.verificationprogress < 1.0
      assert result.initialblockdownload == true
      assert String.contains?(result.warnings, "Warning:")
    end

    test "parses softforks correctly" do
      attrs = get_blockchain_info_preset(:regtest)

      assert {:ok, %GetBlockchainInfoResult{} = result} = GetBlockchainInfoResult.new(attrs)
      assert is_map(result.softforks)

      # Check buried softforks
      assert Map.has_key?(result.softforks, "csv")
      assert Map.has_key?(result.softforks, "segwit")

      csv_fork = result.softforks["csv"]
      assert %Softfork{} = csv_fork
      assert csv_fork.type == "buried"
      assert csv_fork.active == true
      assert csv_fork.height == 0

      # Check BIP9 softfork
      assert Map.has_key?(result.softforks, "taproot")
      taproot_fork = result.softforks["taproot"]
      assert %Softfork{} = taproot_fork
      assert taproot_fork.type == "bip9"
      assert taproot_fork.active == true
      assert %Bip9{} = taproot_fork.bip9
      assert taproot_fork.bip9.status == "active"
    end

    test "handles invalid softforks structure" do
      attrs =
        get_blockchain_info_result_fixture(%{
          "softforks" => %{
            "invalid_fork" => %{
              "type" => "invalid_type",
              "active" => true
            }
          }
        })

      assert {:error, %Changeset{} = changeset} = GetBlockchainInfoResult.new(attrs)
      assert "invalid softforks structure" in errors_on(changeset).softforks
    end

    test "handles missing softforks field" do
      attrs = get_blockchain_info_result_fixture(%{"softforks" => nil})

      assert {:ok, %GetBlockchainInfoResult{} = result} = GetBlockchainInfoResult.new(attrs)
      assert result.softforks == nil
    end
  end

  ## Blockchain RPC tests

  describe "(RPC) Blockchain.get_blockchain_info/2" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns blockchain info", %{client: client} do
      blockchain_info = get_blockchain_info_preset(:regtest)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "getblockchaininfo",
                   "params" => [],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => blockchain_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetBlockchainInfoResult{} = result} = Blockchain.get_blockchain_info(client)

      assert result.chain == "regtest"
      assert result.blocks == 150
      assert result.headers == 150
      assert result.pruned == false
      assert is_map(result.softforks)
      assert Map.has_key?(result.softforks, "csv")
      assert Map.has_key?(result.softforks, "segwit")
    end

    test "call with mainnet data", %{client: client} do
      blockchain_info = get_blockchain_info_preset(:mainnet)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => blockchain_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Blockchain.get_blockchain_info(client)

      assert result.chain == "main"
      assert result.blocks == 750_000
      assert result.difficulty > 30_000_000_000_000
      assert result.initialblockdownload == false
    end

    test "call with pruned node", %{client: client} do
      blockchain_info = get_blockchain_info_preset(:pruned)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => blockchain_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Blockchain.get_blockchain_info(client)

      assert result.pruned == true
      assert result.pruneheight == 500_000
      assert result.automatic_pruning == true
      assert result.prune_target_size == 5500
    end

    test "call with syncing node", %{client: client} do
      blockchain_info = get_blockchain_info_preset(:syncing)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => blockchain_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} = Blockchain.get_blockchain_info(client)

      assert result.blocks < result.headers
      assert result.verificationprogress < 1.0
      assert result.initialblockdownload == true
      assert String.length(result.warnings) > 0
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Blockchain.get_blockchain_info!(client)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client()

      assert {:ok, %GetBlockchainInfoResult{} = result} =
               Blockchain.get_blockchain_info(real_client, retries: 10)

      # Verify basic structure
      assert is_binary(result.chain)
      assert result.chain in ["main", "test", "regtest"]
      assert is_integer(result.blocks)
      assert result.blocks >= 0
      assert is_integer(result.headers)
      assert result.headers >= result.blocks
      assert is_binary(result.bestblockhash)
      assert is_float(result.difficulty)
      assert result.difficulty > 0
      assert is_integer(result.mediantime)
      assert is_float(result.verificationprogress)
      assert result.verificationprogress >= 0 and result.verificationprogress <= 1
      assert is_boolean(result.initialblockdownload)
      assert is_binary(result.chainwork)
      assert is_integer(result.size_on_disk)
      assert result.size_on_disk > 0
      assert is_boolean(result.pruned)
      assert is_binary(result.warnings)

      # Verify softforks structure
      if result.softforks do
        assert is_map(result.softforks)

        for {name, softfork} <- result.softforks do
          assert is_binary(name)
          assert %Softfork{} = softfork
          assert softfork.type in ["buried", "bip9"]
          assert is_boolean(softfork.active)

          if softfork.type == "bip9" and softfork.bip9 do
            assert %Bip9{} = softfork.bip9
            assert softfork.bip9.status in ~w(defined started locked_in active failed)
            assert is_integer(softfork.bip9.since)
          end
        end
      end
    end
  end

  describe "(RPC) Blockchain.get_blockchain_info!/2" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns blockchain info result", %{client: client} do
      blockchain_info = get_blockchain_info_preset(:regtest)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => blockchain_info,
              "error" => nil
            }
          }
      end)

      assert %GetBlockchainInfoResult{} = result = Blockchain.get_blockchain_info!(client)

      assert result.chain == "regtest"
      assert result.blocks == 150
      assert is_map(result.softforks)
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Blockchain.get_blockchain_info!(client)
      end
    end

    test "raises on invalid result data", %{client: client} do
      # Invalid result missing required fields
      invalid_result = %{
        "chain" => "regtest",
        "softforks" => "invalid"
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => invalid_result,
              "error" => nil
            }
          }
      end)

      assert_raise Ecto.InvalidChangesetError, ~r"softforks", fn ->
        Blockchain.get_blockchain_info!(client)
      end
    end
  end
end
