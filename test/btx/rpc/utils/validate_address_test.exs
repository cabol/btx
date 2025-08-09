defmodule BTx.RPC.Utils.ValidateAddressTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.UtilsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Utils}
  alias BTx.RPC.Utils.{ValidateAddress, ValidateAddressResult}
  alias Ecto.Changeset

  # Valid Bitcoin addresses for testing
  @valid_bech32_address "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl"
  @valid_legacy_address "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
  @valid_p2sh_address "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
  @valid_testnet_address "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"
  @invalid_address String.duplicate("a", 32)

  @url "http://localhost:18443/"

  ## ValidateAddress schema tests

  describe "ValidateAddress.new/1" do
    test "creates a new ValidateAddress with required address" do
      assert {:ok, %ValidateAddress{address: @valid_bech32_address}} =
               ValidateAddress.new(address: @valid_bech32_address)
    end

    test "accepts valid Bitcoin address types" do
      valid_addresses = [
        @valid_legacy_address,
        @valid_p2sh_address,
        @valid_bech32_address,
        @valid_testnet_address
      ]

      for address <- valid_addresses do
        assert {:ok, %ValidateAddress{address: ^address}} =
                 ValidateAddress.new(address: address)
      end
    end

    test "accepts valid string as address (validation happens server-side)" do
      test_addresses = [
        @invalid_address,
        String.duplicate("1", 90)
      ]

      for address <- test_addresses do
        assert {:ok, %ValidateAddress{address: ^address}} =
                 ValidateAddress.new(address: address)
      end
    end

    test "returns error for missing address" do
      assert {:error, %Changeset{errors: errors}} = ValidateAddress.new(%{})

      assert Keyword.fetch!(errors, :address) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for empty address" do
      assert {:error, %Changeset{errors: errors}} = ValidateAddress.new(address: "")

      assert Keyword.fetch!(errors, :address) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for address too long" do
      long_address = String.duplicate("a", 91)

      assert {:error, %Changeset{} = changeset} = ValidateAddress.new(address: long_address)
      assert "should be at most 90 character(s)" in errors_on(changeset).address
    end
  end

  describe "ValidateAddress.new!/1" do
    test "creates a new ValidateAddress with required address" do
      assert %ValidateAddress{address: @valid_bech32_address} =
               ValidateAddress.new!(address: @valid_bech32_address)
    end

    test "raises error for invalid parameters" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        ValidateAddress.new!(address: "")
      end
    end

    test "raises error for missing required fields" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        ValidateAddress.new!([])
      end
    end
  end

  describe "ValidateAddress encodable" do
    test "encodes method with address parameter" do
      assert %Request{
               params: [@valid_bech32_address],
               method: "validateaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               ValidateAddress.new!(address: @valid_bech32_address)
               |> Encodable.encode()
    end

    test "encodes all valid address types correctly" do
      addresses = [
        @valid_legacy_address,
        @valid_p2sh_address,
        @valid_bech32_address,
        @valid_testnet_address,
        @invalid_address
      ]

      for address <- addresses do
        encoded = ValidateAddress.new!(address: address) |> Encodable.encode()
        assert encoded.params == [address]
        assert encoded.method == "validateaddress"
        assert encoded.path == "/"
      end
    end
  end

  describe "ValidateAddress changeset/2" do
    test "validates required fields" do
      changeset = ValidateAddress.changeset(%ValidateAddress{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).address
    end

    test "validates address length" do
      # Too long
      long_address = String.duplicate("a", 91)
      changeset = ValidateAddress.changeset(%ValidateAddress{}, %{address: long_address})
      refute changeset.valid?
      assert "should be at most 90 character(s)" in errors_on(changeset).address

      # Valid length
      valid_address = String.duplicate("a", 90)
      changeset = ValidateAddress.changeset(%ValidateAddress{}, %{address: valid_address})
      assert changeset.valid?
    end

    test "accepts all address formats" do
      addresses = [
        @valid_legacy_address,
        @valid_p2sh_address,
        @valid_bech32_address,
        @invalid_address
      ]

      for address <- addresses do
        changeset = ValidateAddress.changeset(%ValidateAddress{}, %{address: address})
        assert changeset.valid?
      end
    end
  end

  ## ValidateAddressResult tests

  describe "ValidateAddressResult.new/1" do
    test "creates result for valid bech32 address" do
      attrs = validate_address_preset(:valid_bech32)

      assert {:ok, %ValidateAddressResult{} = result} = ValidateAddressResult.new(attrs)
      assert result.isvalid == true
      assert result.address == @valid_bech32_address
      assert result.iswitness == true
      assert result.witness_version == 0
      assert result.witness_program == "389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
    end

    test "creates result for valid legacy address" do
      attrs = validate_address_preset(:valid_legacy)

      assert {:ok, %ValidateAddressResult{} = result} = ValidateAddressResult.new(attrs)
      assert result.isvalid == true
      assert result.address == @valid_legacy_address
      assert result.iswitness == false
      assert result.witness_version == nil
      assert result.witness_program == nil
    end

    test "creates result for valid P2SH address" do
      attrs = validate_address_preset(:valid_p2sh)

      assert {:ok, %ValidateAddressResult{} = result} = ValidateAddressResult.new(attrs)
      assert result.isvalid == true
      assert result.address == @valid_p2sh_address
      assert result.isscript == true
      assert result.iswitness == false
    end

    test "creates result for invalid address" do
      attrs = validate_address_preset(:invalid)

      assert {:ok, %ValidateAddressResult{} = result} = ValidateAddressResult.new(attrs)
      assert result.isvalid == false
      assert result.address == nil
      assert result.script_pub_key == nil
      assert result.isscript == nil
      assert result.iswitness == nil
    end

    test "validates required fields" do
      incomplete_attrs = %{
        "address" => @valid_bech32_address
        # Missing isvalid field
      }

      assert {:error, %Changeset{errors: errors}} = ValidateAddressResult.new(incomplete_attrs)
      assert Keyword.has_key?(errors, :isvalid)
    end

    test "validates scriptPubKey field mapping" do
      attrs = %{
        "isvalid" => true,
        "address" => @valid_bech32_address,
        "scriptPubKey" => "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
        "isscript" => false,
        "iswitness" => true
      }

      assert {:ok, %ValidateAddressResult{} = result} = ValidateAddressResult.new(attrs)
      assert result.script_pub_key == "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
    end
  end

  ## ValidateAddress RPC tests

  describe "(RPC) Utils.validate_address/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "successful call returns valid bech32 address info", %{client: client} do
      address_result = validate_address_preset(:valid_bech32)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "validateaddress",
                   "params" => [@valid_bech32_address],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => address_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, %ValidateAddressResult{} = result} =
               Utils.validate_address(client, address: @valid_bech32_address)

      assert result.isvalid == true
      assert result.address == @valid_bech32_address
      assert result.iswitness == true
      assert result.witness_version == 0
      assert result.witness_program == "389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
    end

    test "call with valid legacy address", %{client: client} do
      address_result = validate_address_preset(:valid_legacy)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "validateaddress",
                   "params" => [@valid_legacy_address],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => address_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Utils.validate_address(client, address: @valid_legacy_address)

      assert result.isvalid == true
      assert result.address == @valid_legacy_address
      assert result.iswitness == false
      assert result.witness_version == nil
    end

    test "call with valid P2SH address", %{client: client} do
      address_result = validate_address_preset(:valid_p2sh)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => address_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Utils.validate_address(client, address: @valid_p2sh_address)

      assert result.isvalid == true
      assert result.address == @valid_p2sh_address
      assert result.isscript == true
      assert result.iswitness == false
    end

    test "call with invalid address", %{client: client} do
      address_result = validate_address_preset(:invalid)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          assert %{
                   "method" => "validateaddress",
                   "params" => [@invalid_address],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => address_result,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Utils.validate_address(client, address: @invalid_address)

      assert result.isvalid == false
      assert result.address == nil
      assert result.script_pub_key == nil
    end

    test "verifies all address types work", %{client: client} do
      address_types = [
        {@valid_legacy_address, false},
        {@valid_p2sh_address, false},
        {@valid_bech32_address, true},
        {@valid_testnet_address, true}
      ]

      for {address, is_witness} <- address_types do
        address_result =
          validate_address_result_fixture(%{
            "address" => address,
            "iswitness" => is_witness
          })

        mock(fn
          %{method: :post, url: @url, body: body} ->
            # Verify correct parameters are sent
            assert %{
                     "method" => "validateaddress",
                     "params" => [^address]
                   } = BTx.json_module().decode!(body)

            %Tesla.Env{
              status: 200,
              body: %{
                "id" => "test-id",
                "result" => address_result,
                "error" => nil
              }
            }
        end)

        assert {:ok, result} = Utils.validate_address(client, address: address)
        assert result.isvalid == true
        assert result.address == address
        assert result.iswitness == is_witness
      end
    end

    test "call! raises on error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Utils.validate_address!(client, address: @valid_bech32_address)
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client(retry_opts: [max_retries: 10])

      # Test various address types
      test_addresses = [
        # These are well-known addresses that should be valid
        # bech32
        "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
        # legacy
        "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
        # P2SH
        "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
        # Invalid address
        @invalid_address
      ]

      for address <- test_addresses do
        assert {:ok, %ValidateAddressResult{} = result} =
                 Utils.validate_address(real_client, address: address)

        assert is_boolean(result.isvalid)

        if result.isvalid do
          assert is_binary(result.address)
          assert is_binary(result.script_pub_key)
          assert is_boolean(result.isscript)
          assert is_boolean(result.iswitness)

          if result.iswitness do
            assert is_integer(result.witness_version)
            assert is_binary(result.witness_program)
          end
        else
          # Invalid addresses should have minimal info
          assert result.address == nil
          assert result.script_pub_key == nil
        end
      end
    end
  end

  describe "(RPC) Utils.validate_address!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)
      %{client: client}
    end

    test "returns address validation result", %{client: client} do
      address_result = validate_address_preset(:valid_bech32)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => address_result,
              "error" => nil
            }
          }
      end)

      assert %ValidateAddressResult{} =
               result = Utils.validate_address!(client, address: @valid_bech32_address)

      assert result.isvalid == true
      assert result.address == @valid_bech32_address
      assert result.iswitness == true
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Utils.validate_address!(client, address: "")
      end
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Utils.validate_address!(client, address: @valid_bech32_address)
      end
    end

    test "raises on invalid result data", %{client: client} do
      # Invalid result missing required fields
      invalid_result = %{
        "address" => @valid_bech32_address
        # Missing isvalid field
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

      assert_raise Ecto.InvalidChangesetError, fn ->
        Utils.validate_address!(client, address: @valid_bech32_address)
      end
    end
  end
end
