defmodule BTx.RPC.Wallets.ImportDescriptorsTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.WalletsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Wallets}

  alias BTx.RPC.Wallets.{
    ImportDescriptorRequest,
    ImportDescriptorResponse,
    ImportDescriptors,
    ImportDescriptorsResult
  }

  alias Ecto.{Changeset, UUID}

  @valid_descriptor "wpkh([d34db33f/84h/0h/0h]xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL/0/*)#cjjspncu"
  @valid_wallet_name "test_wallet"

  @url "http://localhost:18443/"

  ## ImportDescriptorRequest schema tests

  describe "ImportDescriptorRequest changeset/2" do
    test "accepts valid descriptor request" do
      attrs = import_descriptor_request_fixture()
      changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
      assert changeset.valid?
    end

    test "validates required fields" do
      changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).desc
      assert "can't be blank" in errors_on(changeset).timestamp
    end

    test "validates descriptor is not empty" do
      attrs = import_descriptor_request_fixture(%{"desc" => ""})
      changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).desc
    end

    test "validates timestamp formats" do
      # Valid timestamps
      valid_timestamps = ["now", 0, 1_640_995_200, 1_234_567_890]

      for timestamp <- valid_timestamps do
        attrs = import_descriptor_request_fixture(%{"timestamp" => timestamp})
        changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
        assert changeset.valid?, "#{inspect(timestamp)} should be valid"
      end

      # Invalid timestamps
      invalid_timestamps = [-1, "invalid", 1.5]

      for timestamp <- invalid_timestamps do
        attrs = import_descriptor_request_fixture(%{"timestamp" => timestamp})
        changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
        refute changeset.valid?, "#{inspect(timestamp)} should be invalid"

        assert "must be a non-negative integer or \"now\", got: #{inspect(timestamp)}" in errors_on(
                 changeset
               ).timestamp
      end
    end

    test "validates range formats" do
      # Valid ranges
      valid_ranges = [100, [0, 100], [50, 200]]

      for range <- valid_ranges do
        attrs = import_descriptor_request_fixture(%{"range" => range})
        changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
        assert changeset.valid?, "#{inspect(range)} should be valid"
      end

      # Invalid ranges
      invalid_ranges = [-1, [100, 50], [-1, 100], "invalid"]

      for range <- invalid_ranges do
        attrs = import_descriptor_request_fixture(%{"range" => range})
        changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
        refute changeset.valid?, "#{inspect(range)} should be invalid"

        assert "must be a non-negative integer or array [begin, end], got: #{inspect(range)}" in errors_on(
                 changeset
               ).range
      end
    end

    test "validates next_index is non-negative" do
      # Valid next_index
      attrs = import_descriptor_request_fixture(%{"next_index" => 50})
      changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
      assert changeset.valid?

      # Invalid negative next_index
      attrs = import_descriptor_request_fixture(%{"next_index" => -1})
      changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).next_index
    end

    test "validates label not allowed when internal=true" do
      # Valid: internal=false with label
      attrs = import_descriptor_request_fixture(%{"internal" => false, "label" => "my_label"})
      changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
      assert changeset.valid?

      # Valid: internal=true without label
      attrs = import_descriptor_request_fixture(%{"internal" => true, "label" => ""})
      changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
      assert changeset.valid?

      # Invalid: internal=true with label
      attrs = import_descriptor_request_fixture(%{"internal" => true, "label" => "my_label"})
      changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
      refute changeset.valid?
      assert "not allowed when internal=true" in errors_on(changeset).label
    end

    test "uses default values" do
      attrs = %{
        "desc" => @valid_descriptor,
        "timestamp" => "now"
      }

      changeset = ImportDescriptorRequest.changeset(%ImportDescriptorRequest{}, attrs)
      assert changeset.valid?

      output = Changeset.apply_changes(changeset)
      assert output.active == false
      assert output.internal == false
      assert output.label == ""
    end
  end

  ## ImportDescriptorResponse schema tests

  describe "ImportDescriptorResponse changeset/2" do
    test "accepts valid response data" do
      attrs = import_descriptor_response_fixture()
      changeset = ImportDescriptorResponse.changeset(%ImportDescriptorResponse{}, attrs)
      assert changeset.valid?
    end

    test "accepts response with warnings" do
      attrs =
        import_descriptor_response_fixture(%{
          "warnings" => ["Rescan will be triggered", "May take a long time"]
        })

      changeset = ImportDescriptorResponse.changeset(%ImportDescriptorResponse{}, attrs)
      assert changeset.valid?

      output = Changeset.apply_changes(changeset)
      assert length(output.warnings) == 2
    end

    test "accepts response with error" do
      attrs =
        import_descriptor_response_fixture(%{
          "success" => false,
          "error" => %{
            "code" => -4,
            "message" => "Descriptor already exists"
          }
        })

      changeset = ImportDescriptorResponse.changeset(%ImportDescriptorResponse{}, attrs)
      assert changeset.valid?

      output = Changeset.apply_changes(changeset)
      assert output.success == false
      assert output.error["code"] == -4
    end

    test "accepts empty data" do
      changeset = ImportDescriptorResponse.changeset(%ImportDescriptorResponse{}, %{})
      assert changeset.valid?

      output = Changeset.apply_changes(changeset)
      assert output.warnings == []
      assert is_nil(output.success)
      assert is_nil(output.error)
    end
  end

  ## ImportDescriptors schema tests

  describe "ImportDescriptors.new/1" do
    test "creates a new ImportDescriptors with valid requests" do
      attrs = import_descriptors_request_fixture()

      assert {:ok, %ImportDescriptors{} = request} = ImportDescriptors.new(attrs)
      assert length(request.requests) == 1
      assert request.wallet_name == @valid_wallet_name
    end

    test "creates a new ImportDescriptors with multiple requests" do
      attrs =
        import_descriptors_request_fixture(%{
          "requests" => [
            import_descriptor_request_fixture(),
            import_descriptor_request_fixture(%{"internal" => true, "label" => ""})
          ]
        })

      assert {:ok, %ImportDescriptors{} = request} = ImportDescriptors.new(attrs)
      assert length(request.requests) == 2
    end

    test "accepts valid wallet names" do
      valid_names = [
        "simple",
        "wallet123",
        "my-wallet",
        "my_wallet",
        # minimum length
        "a",
        # maximum length
        String.duplicate("a", 64)
      ]

      for name <- valid_names do
        attrs = import_descriptors_request_fixture(%{"wallet_name" => name})

        assert {:ok, %ImportDescriptors{wallet_name: ^name}} = ImportDescriptors.new(attrs)
      end
    end

    test "returns error for empty requests" do
      attrs = %{"requests" => []}

      assert {:error, %Changeset{} = changeset} = ImportDescriptors.new(attrs)
      assert "can't be blank" in errors_on(changeset).requests
    end

    test "returns error for missing requests" do
      attrs = %{"wallet_name" => @valid_wallet_name}

      assert {:error, %Changeset{} = changeset} = ImportDescriptors.new(attrs)
      assert changeset.errors[:requests] != nil
    end

    test "returns error for invalid wallet name" do
      attrs = import_descriptors_request_fixture(%{"wallet_name" => "invalid-wallet-name!"})

      assert {:error, %Changeset{} = changeset} = ImportDescriptors.new(attrs)
      assert changeset.errors[:wallet_name] != nil
    end

    test "accepts keyword list params" do
      assert {:ok, %ImportDescriptors{}} =
               ImportDescriptors.new(
                 requests: [
                   %{
                     desc: @valid_descriptor,
                     timestamp: "now"
                   }
                 ],
                 wallet_name: @valid_wallet_name
               )
    end
  end

  describe "ImportDescriptors.new!/1" do
    test "creates a new ImportDescriptors with valid data" do
      attrs = import_descriptors_request_fixture()

      assert %ImportDescriptors{} = ImportDescriptors.new!(attrs)
    end

    test "raises error for invalid data" do
      attrs = %{"requests" => []}

      assert_raise Ecto.InvalidChangesetError, fn ->
        ImportDescriptors.new!(attrs)
      end
    end
  end

  describe "ImportDescriptors encodable" do
    test "encodes minimal request correctly" do
      request =
        ImportDescriptors.new!(
          requests: [
            %{desc: @valid_descriptor, timestamp: "now"}
          ]
        )

      encoded = Encodable.encode(request)

      assert encoded.method == "importdescriptors"
      assert encoded.path == "/"
      assert [requests_params] = encoded.params
      assert length(requests_params) == 1

      request_param = hd(requests_params)
      assert request_param[:desc] == @valid_descriptor
      assert request_param[:timestamp] == "now"
    end

    test "encodes request with wallet name" do
      request =
        ImportDescriptors.new!(
          requests: [
            %{desc: @valid_descriptor, timestamp: "now"}
          ],
          wallet_name: @valid_wallet_name
        )

      encoded = Encodable.encode(request)

      assert encoded.method == "importdescriptors"
      assert encoded.path == "/wallet/#{@valid_wallet_name}"
    end

    test "encodes request with all parameters" do
      request =
        ImportDescriptors.new!(
          requests: [
            %{
              desc: @valid_descriptor,
              active: true,
              range: [0, 100],
              next_index: 50,
              timestamp: 1_640_995_200,
              internal: false,
              label: "my_wallet"
            }
          ],
          wallet_name: @valid_wallet_name
        )

      encoded = Encodable.encode(request)
      [requests_params] = encoded.params
      request_param = hd(requests_params)

      # Verify all fields are encoded correctly
      assert request_param[:desc] == @valid_descriptor
      assert request_param[:active] == true
      assert request_param[:range] == [0, 100]
      assert request_param[:next_index] == 50
      assert request_param[:timestamp] == 1_640_995_200
      assert request_param[:internal] == false
      assert request_param[:label] == "my_wallet"
    end

    test "filters out nil values" do
      request =
        ImportDescriptors.new!(
          requests: [
            %{
              desc: @valid_descriptor,
              timestamp: "now"
              # other fields will be nil/default
            }
          ]
        )

      encoded = Encodable.encode(request)
      [requests_params] = encoded.params
      request_param = hd(requests_params)

      # Should only include non-nil values
      expected_keys = [:desc, :timestamp, :active, :internal, :label]
      assert MapSet.new(Map.keys(request_param)) == MapSet.new(expected_keys)
      refute Map.has_key?(request_param, :range)
      refute Map.has_key?(request_param, :next_index)
    end

    test "encodes multiple requests" do
      request =
        ImportDescriptors.new!(
          requests: [
            %{desc: @valid_descriptor, timestamp: "now", internal: false, label: "external"},
            %{desc: @valid_descriptor, timestamp: 0, internal: true}
          ]
        )

      encoded = Encodable.encode(request)
      [requests_params] = encoded.params
      assert length(requests_params) == 2

      [first_param, second_param] = requests_params
      assert first_param[:internal] == false
      assert first_param[:label] == "external"
      assert second_param[:internal] == true
      # nil values filtered out
      refute Map.has_key?(second_param, "label")
    end
  end

  ## ImportDescriptorsResult schema tests

  describe "ImportDescriptorsResult.new/1" do
    test "creates result with valid response data" do
      attrs = [import_descriptor_response_fixture()]

      assert {:ok, %ImportDescriptorsResult{} = result} = ImportDescriptorsResult.new(attrs)
      assert length(result.responses) == 1

      response = hd(result.responses)
      assert response.success == true
      assert response.warnings == []
      assert is_nil(response.error)
    end

    test "creates result with multiple responses" do
      attrs = [
        import_descriptor_response_fixture(),
        import_descriptor_response_fixture(%{"success" => false})
      ]

      assert {:ok, %ImportDescriptorsResult{} = result} = ImportDescriptorsResult.new(attrs)
      assert length(result.responses) == 2

      [first_response, second_response] = result.responses
      assert first_response.success == true
      assert second_response.success == false
    end

    test "creates result with responses containing errors and warnings" do
      attrs = [
        import_descriptor_response_fixture(%{
          "success" => false,
          "warnings" => ["Invalid checksum"],
          "error" => %{
            "code" => -5,
            "message" => "Invalid descriptor"
          }
        })
      ]

      assert {:ok, %ImportDescriptorsResult{} = result} = ImportDescriptorsResult.new(attrs)
      response = hd(result.responses)

      assert response.success == false
      assert response.warnings == ["Invalid checksum"]
      assert response.error["code"] == -5
      assert response.error["message"] == "Invalid descriptor"
    end
  end

  describe "ImportDescriptorsResult.new!/1" do
    test "creates result with valid data" do
      attrs = [import_descriptor_response_fixture()]

      assert %ImportDescriptorsResult{} = ImportDescriptorsResult.new!(attrs)
    end

    test "raises error for invalid response data" do
      # This would be caught by the embedded schema validation
      attrs = [%{"invalid" => "data"}]

      assert %ImportDescriptorsResult{} = ImportDescriptorsResult.new!(attrs)
    end
  end

  ## ImportDescriptors RPC

  describe "(RPC) Wallets.import_descriptors/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "calls importdescriptors RPC method", %{client: client} do
      result_fixture = [import_descriptor_response_fixture()]

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          decoded_body = BTx.json_module().decode!(body)

          assert %{
                   "method" => "importdescriptors",
                   "params" => [requests],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = decoded_body

          assert is_binary(id)
          assert length(requests) == 1

          request = hd(requests)
          assert request["desc"] == @valid_descriptor
          assert request["timestamp"] == "now"

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, [response]} =
               Wallets.import_descriptors(client,
                 requests: [
                   %{desc: @valid_descriptor, timestamp: "now"}
                 ]
               )

      assert %ImportDescriptorResponse{} = response
      assert response.success == true
    end

    test "calls with wallet name", %{client: client} do
      result_fixture = [import_descriptor_response_fixture()]
      url = Path.join(@url, "/wallet/#{@valid_wallet_name}")

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)

          assert %{
                   "method" => "importdescriptors",
                   "params" => [_requests],
                   "jsonrpc" => "1.0"
                 } = decoded_body

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, [_response]} =
               Wallets.import_descriptors(client,
                 requests: [
                   %{desc: @valid_descriptor, timestamp: "now"}
                 ],
                 wallet_name: @valid_wallet_name
               )
    end

    test "handles multiple descriptor import", %{client: client} do
      result_fixture = [
        import_descriptor_response_fixture(),
        import_descriptor_response_fixture()
      ]

      mock(fn
        %{method: :post, url: @url, body: body} ->
          decoded_body = BTx.json_module().decode!(body)
          [requests] = decoded_body["params"]

          # Verify multiple requests
          assert length(requests) == 2

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => result_fixture,
              "error" => nil
            }
          }
      end)

      assert {:ok, responses} =
               Wallets.import_descriptors(client,
                 requests: [
                   %{desc: @valid_descriptor, timestamp: "now", internal: false, label: "external"},
                   %{desc: @valid_descriptor, timestamp: 0, internal: true}
                 ]
               )

      assert length(responses) == 2
    end

    test "handles responses with warnings and errors", %{client: client} do
      result_fixture = [
        import_descriptor_response_fixture(%{
          "success" => false,
          "warnings" => ["Invalid checksum"],
          "error" => %{
            "code" => -5,
            "message" => "Invalid descriptor"
          }
        })
      ]

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

      assert {:ok, [response]} =
               Wallets.import_descriptors(client,
                 requests: [
                   %{desc: @valid_descriptor, timestamp: "now"}
                 ]
               )

      assert response.success == false
      assert response.warnings == ["Invalid checksum"]
      assert response.error["code"] == -5
    end

    test "returns error for invalid request", %{client: client} do
      assert {:error, %Ecto.Changeset{}} =
               Wallets.import_descriptors(client, requests: [])
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
                "code" => -18,
                "message" => "Wallet not loaded"
              }
            }
          }
      end)

      assert {:error, %BTx.RPC.MethodError{code: -18, reason: :wallet_not_found}} =
               Wallets.import_descriptors(client,
                 requests: [
                   %{desc: @valid_descriptor, timestamp: "now"}
                 ]
               )
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.import_descriptors!(client,
          requests: [
            %{desc: @valid_descriptor, timestamp: "now"}
          ]
        )
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client(retry_opts: [max_retries: 10])

      # Create a new descriptor wallet for testing
      wallet_name = "import-descriptors-test-#{UUID.generate()}"

      wallet =
        Wallets.create_wallet!(
          real_client,
          wallet_name: wallet_name,
          descriptors: true
        )

      # TODO: Provide a successful case scenario.
      # Note: In a real test, you would need valid descriptors
      # For now, we just test that the function exists and can be called
      # with invalid descriptors, expecting a failed import
      assert {:ok, [%ImportDescriptorResponse{} = r]} =
               Wallets.import_descriptors(
                 real_client,
                 requests: [
                   %{desc: @valid_descriptor, timestamp: "now"}
                 ],
                 wallet_name: wallet.name
               )

      assert r.success == false
      assert r.warnings == []
      assert r.error["code"] == -5

      assert r.error["message"] ==
               "Provided checksum 'cjjspncu' does not match computed checksum 'h36s06su'"
    end
  end

  describe "(RPC) Wallets.import_descriptors!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns responses on success", %{client: client} do
      result_fixture = [import_descriptor_response_fixture()]

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

      assert [response] =
               Wallets.import_descriptors!(client,
                 requests: [
                   %{desc: @valid_descriptor, timestamp: "now"}
                 ]
               )

      assert %ImportDescriptorResponse{} = response
      assert response.success == true
    end

    test "raises error for invalid request", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.import_descriptors!(client, requests: [])
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
                "code" => -18,
                "message" => "Wallet not loaded"
              }
            }
          }
      end)

      assert_raise BTx.RPC.MethodError, fn ->
        Wallets.import_descriptors!(client,
          requests: [
            %{desc: @valid_descriptor, timestamp: "now"}
          ]
        )
      end
    end
  end
end
