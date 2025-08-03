defmodule BTx.RPC.Utils.GetDescriptorInfoTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.UtilsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Utils}
  alias BTx.RPC.Utils.{GetDescriptorInfo, GetDescriptorInfoResult}
  alias Ecto.Changeset

  @valid_descriptor "wpkh([d34db33f/84h/0h/0h]0279be667ef9dcbbac55a06295Ce870b07029Bfcdb2dce28d959f2815b16f81798)"

  @url "http://localhost:18443/"

  ## Schema tests

  describe "GetDescriptorInfo.new/1" do
    test "creates a new GetDescriptorInfo with required fields" do
      assert {:ok, %GetDescriptorInfo{} = request} =
               GetDescriptorInfo.new(descriptor: @valid_descriptor)

      assert request.descriptor == @valid_descriptor
      assert request.method == "getdescriptorinfo"
    end

    test "returns error for missing descriptor" do
      assert {:error, %Changeset{errors: errors}} = GetDescriptorInfo.new(%{})

      assert Keyword.fetch!(errors, :descriptor) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for empty descriptor" do
      assert {:error, %Changeset{errors: errors}} =
               GetDescriptorInfo.new(descriptor: "")

      assert Keyword.fetch!(errors, :descriptor) ==
               {"can't be blank", [validation: :required]}
    end

    test "accepts keyword list params" do
      assert {:ok, %GetDescriptorInfo{} = request} =
               GetDescriptorInfo.new(descriptor: @valid_descriptor)

      assert request.descriptor == @valid_descriptor
    end
  end

  describe "GetDescriptorInfo.new!/1" do
    test "creates a new GetDescriptorInfo with valid data" do
      assert %GetDescriptorInfo{} =
               GetDescriptorInfo.new!(descriptor: @valid_descriptor)
    end

    test "raises error for invalid data" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetDescriptorInfo.new!(descriptor: "")
      end
    end
  end

  describe "GetDescriptorInfo encodable" do
    test "encodes request correctly" do
      request = GetDescriptorInfo.new!(descriptor: @valid_descriptor)

      assert %Request{
               method: "getdescriptorinfo",
               path: "/",
               params: [@valid_descriptor]
             } = Encodable.encode(request)
    end
  end

  describe "GetDescriptorInfo changeset/2" do
    test "accepts valid parameters" do
      attrs = %{descriptor: @valid_descriptor}

      changeset = GetDescriptorInfo.changeset(%GetDescriptorInfo{}, attrs)
      assert changeset.valid?
    end

    test "validates required descriptor field" do
      changeset = GetDescriptorInfo.changeset(%GetDescriptorInfo{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).descriptor
    end
  end

  ## GetDescriptorInfoResult schema tests

  describe "GetDescriptorInfoResult.new/1" do
    test "creates result with valid data" do
      attrs = get_descriptor_info_result_fixture()

      assert {:ok, %GetDescriptorInfoResult{} = result} =
               GetDescriptorInfoResult.new(attrs)

      assert result.descriptor == attrs["descriptor"]
      assert result.checksum == attrs["checksum"]
      assert result.isrange == attrs["isrange"]
      assert result.issolvable == attrs["issolvable"]
      assert result.hasprivatekeys == attrs["hasprivatekeys"]
    end

    test "creates result for ranged descriptor" do
      attrs =
        get_descriptor_info_result_fixture(%{
          "descriptor" =>
            "wpkh([d34db33f/84h/0h/0h]xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL/0/*)#cjjspncu",
          "isrange" => true
        })

      assert {:ok, %GetDescriptorInfoResult{} = result} =
               GetDescriptorInfoResult.new(attrs)

      assert result.isrange == true
      assert String.contains?(result.descriptor, "/0/*")
    end

    test "creates result for descriptor with private keys" do
      attrs =
        get_descriptor_info_result_fixture(%{
          "hasprivatekeys" => true
        })

      assert {:ok, %GetDescriptorInfoResult{} = result} =
               GetDescriptorInfoResult.new(attrs)

      assert result.hasprivatekeys == true
    end

    test "creates result for unsolvable descriptor" do
      attrs =
        get_descriptor_info_result_fixture(%{
          "issolvable" => false
        })

      assert {:ok, %GetDescriptorInfoResult{} = result} =
               GetDescriptorInfoResult.new(attrs)

      assert result.issolvable == false
    end

    test "handles minimal result data" do
      attrs = %{"descriptor" => @valid_descriptor}

      assert {:ok, %GetDescriptorInfoResult{} = result} =
               GetDescriptorInfoResult.new(attrs)

      assert result.descriptor == @valid_descriptor
      assert is_nil(result.checksum)
      assert is_nil(result.isrange)
      assert is_nil(result.issolvable)
      assert is_nil(result.hasprivatekeys)
    end
  end

  describe "GetDescriptorInfoResult.new!/1" do
    test "creates result with valid data" do
      attrs = get_descriptor_info_result_fixture()

      assert %GetDescriptorInfoResult{} = GetDescriptorInfoResult.new!(attrs)
    end

    test "handles empty data gracefully" do
      attrs = %{}

      assert %GetDescriptorInfoResult{} = GetDescriptorInfoResult.new!(attrs)
    end
  end

  describe "GetDescriptorInfoResult changeset/2" do
    test "casts all optional fields" do
      attrs = get_descriptor_info_result_fixture()

      changeset = GetDescriptorInfoResult.changeset(%GetDescriptorInfoResult{}, attrs)
      assert changeset.valid?

      output = Changeset.apply_changes(changeset)
      assert output.descriptor == attrs["descriptor"]
      assert output.checksum == attrs["checksum"]
      assert output.isrange == attrs["isrange"]
      assert output.issolvable == attrs["issolvable"]
      assert output.hasprivatekeys == attrs["hasprivatekeys"]
    end

    test "accepts empty data" do
      changeset = GetDescriptorInfoResult.changeset(%GetDescriptorInfoResult{}, %{})
      assert changeset.valid?

      output = Changeset.apply_changes(changeset)
      assert is_nil(output.descriptor)
      assert is_nil(output.checksum)
      assert is_nil(output.isrange)
      assert is_nil(output.issolvable)
      assert is_nil(output.hasprivatekeys)
    end
  end

  ## GetDescriptorInfo RPC

  describe "(RPC) Utils.get_descriptor_info/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "calls getdescriptorinfo RPC method", %{client: client} do
      result_fixture = get_descriptor_info_result_fixture()

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "getdescriptorinfo",
                   "params" => [@valid_descriptor],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetDescriptorInfoResult{} = result} =
               Utils.get_descriptor_info(client, descriptor: @valid_descriptor)

      assert result.descriptor == result_fixture["descriptor"]
      assert result.checksum == result_fixture["checksum"]
      assert result.isrange == result_fixture["isrange"]
      assert result.issolvable == result_fixture["issolvable"]
      assert result.hasprivatekeys == result_fixture["hasprivatekeys"]
    end

    test "analyzes ranged descriptor", %{client: client} do
      result_fixture = get_descriptor_info_preset(:ranged_descriptor)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetDescriptorInfoResult{} = result} =
               Utils.get_descriptor_info(client, descriptor: @valid_descriptor)

      assert result.isrange == true
    end

    test "analyzes descriptor with private keys", %{client: client} do
      result_fixture = get_descriptor_info_preset(:with_private_keys)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetDescriptorInfoResult{} = result} =
               Utils.get_descriptor_info(client, descriptor: @valid_descriptor)

      assert result.hasprivatekeys == true
    end

    test "analyzes unsolvable descriptor", %{client: client} do
      result_fixture = get_descriptor_info_preset(:unsolvable)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetDescriptorInfoResult{} = result} =
               Utils.get_descriptor_info(client, descriptor: @valid_descriptor)

      assert result.issolvable == false
    end

    test "returns error for invalid request", %{client: client} do
      assert {:error, %Ecto.Changeset{}} =
               Utils.get_descriptor_info(client, descriptor: "")
    end

    test "returns error for RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -5,
                "message" => "Invalid descriptor"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -5}} =
               Utils.get_descriptor_info(client, descriptor: @valid_descriptor)
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Utils.get_descriptor_info!(client, descriptor: @valid_descriptor)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client()

      # Test with a valid descriptor
      assert {:ok, %GetDescriptorInfoResult{} = result} =
               Utils.get_descriptor_info(
                 real_client,
                 [descriptor: @valid_descriptor],
                 retries: 10
               )

      # Verify the result has expected fields
      assert is_binary(result.descriptor)
      assert is_binary(result.checksum)
      assert is_boolean(result.isrange)
      assert is_boolean(result.issolvable)
      assert is_boolean(result.hasprivatekeys)

      # Test with an invalid descriptor should return an error
      assert {:error, %BTx.RPC.MethodError{}} =
               Utils.get_descriptor_info(
                 real_client,
                 [descriptor: "invalid_descriptor"],
                 retries: 10
               )
    end
  end

  describe "(RPC) Utils.get_descriptor_info!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns result on success", %{client: client} do
      result_fixture = get_descriptor_info_result_fixture()

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert %GetDescriptorInfoResult{} =
               Utils.get_descriptor_info!(client, descriptor: @valid_descriptor)
    end

    test "raises error for invalid request", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Utils.get_descriptor_info!(client, descriptor: "")
      end
    end

    test "raises error for RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => nil,
              "error" => %{
                "code" => -5,
                "message" => "Invalid descriptor"
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, fn ->
        Utils.get_descriptor_info!(client, descriptor: @valid_descriptor)
      end
    end
  end
end
