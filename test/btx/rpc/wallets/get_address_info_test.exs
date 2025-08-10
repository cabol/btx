defmodule BTx.RPC.Wallets.GetAddressInfoTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils
  import BTx.WalletsFixtures
  import Tesla.Mock

  alias BTx.RPC.{Encodable, Request, Wallets}
  alias BTx.RPC.Wallets.{GetAddressInfo, GetAddressInfoResult}
  alias Ecto.{Changeset, UUID}

  # Valid Bitcoin addresses for testing
  @valid_legacy_address "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
  @valid_p2sh_address "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
  @valid_bech32_address "bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl"
  @valid_testnet_address "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"
  @valid_regtest_address "bcrt1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"

  @url "http://localhost:18443/"

  ## Schema tests

  describe "new/1" do
    test "creates a new GetAddressInfo with required address" do
      assert {:ok, %GetAddressInfo{address: @valid_bech32_address}} =
               GetAddressInfo.new(address: @valid_bech32_address)
    end

    test "creates a new GetAddressInfo with all parameters" do
      assert {:ok,
              %GetAddressInfo{
                address: @valid_legacy_address,
                wallet_name: "my_wallet"
              }} =
               GetAddressInfo.new(
                 address: @valid_legacy_address,
                 wallet_name: "my_wallet"
               )
    end

    test "accepts valid Bitcoin address types" do
      valid_addresses = [
        @valid_legacy_address,
        @valid_p2sh_address,
        @valid_bech32_address,
        @valid_testnet_address,
        @valid_regtest_address
      ]

      for address <- valid_addresses do
        assert {:ok, %GetAddressInfo{address: ^address}} =
                 GetAddressInfo.new(address: address)
      end
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
        assert {:ok, %GetAddressInfo{wallet_name: ^name}} =
                 GetAddressInfo.new(address: @valid_bech32_address, wallet_name: name)
      end
    end

    test "returns error for missing address" do
      assert {:error, %Changeset{errors: errors}} = GetAddressInfo.new(%{})

      assert Keyword.fetch!(errors, :address) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for invalid address" do
      invalid_addresses = [
        # Too short
        "1abc",
        # Too long
        String.duplicate("bc1q", 30),
        # Invalid characters for Base58
        "1InvalidChars0OIl",
        # Empty string
        ""
      ]

      for address <- invalid_addresses do
        assert {:error, %Changeset{} = changeset} = GetAddressInfo.new(address: address)
        assert changeset.errors[:address] != nil
      end
    end

    test "returns error for address too short" do
      short_address = "1abc"

      assert {:error, %Changeset{} = changeset} = GetAddressInfo.new(address: short_address)
      assert "should be at least 26 character(s)" in errors_on(changeset).address
    end

    test "returns error for address too long" do
      long_address = String.duplicate("bc1q", 30)

      assert {:error, %Changeset{} = changeset} = GetAddressInfo.new(address: long_address)
      assert "should be at most 90 character(s)" in errors_on(changeset).address
    end

    test "returns error for wallet name too long" do
      long_name = String.duplicate("a", 65)

      assert {:error, %Changeset{} = changeset} =
               GetAddressInfo.new(address: @valid_bech32_address, wallet_name: long_name)

      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name
    end

    test "accepts empty string wallet name as nil" do
      assert {:ok, %GetAddressInfo{wallet_name: nil}} =
               GetAddressInfo.new(address: @valid_bech32_address, wallet_name: "")
    end
  end

  describe "new!/1" do
    test "creates a new GetAddressInfo with required address" do
      assert %GetAddressInfo{address: @valid_bech32_address} =
               GetAddressInfo.new!(address: @valid_bech32_address)
    end

    test "creates a new GetAddressInfo with all options" do
      assert %GetAddressInfo{
               address: @valid_legacy_address,
               wallet_name: "my_wallet"
             } =
               GetAddressInfo.new!(
                 address: @valid_legacy_address,
                 wallet_name: "my_wallet"
               )
    end

    test "raises error for invalid address" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetAddressInfo.new!(address: "invalid")
      end
    end

    test "raises error for missing required fields" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetAddressInfo.new!([])
      end
    end

    test "raises error for validation failures" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GetAddressInfo.new!(address: "invalid", wallet_name: String.duplicate("a", 65))
      end
    end
  end

  describe "encodable" do
    test "encodes method with required address only" do
      assert %Request{
               params: [@valid_bech32_address],
               method: "getaddressinfo",
               jsonrpc: "1.0",
               path: "/"
             } =
               GetAddressInfo.new!(address: @valid_bech32_address)
               |> Encodable.encode()
    end

    test "encodes method with wallet name" do
      assert %Request{
               params: [@valid_bech32_address],
               method: "getaddressinfo",
               jsonrpc: "1.0",
               path: "/wallet/my_wallet"
             } =
               GetAddressInfo.new!(
                 address: @valid_bech32_address,
                 wallet_name: "my_wallet"
               )
               |> Encodable.encode()
    end

    test "encodes all valid address types correctly" do
      addresses = [
        @valid_legacy_address,
        @valid_p2sh_address,
        @valid_bech32_address,
        @valid_testnet_address,
        @valid_regtest_address
      ]

      for address <- addresses do
        encoded = GetAddressInfo.new!(address: address) |> Encodable.encode()
        assert encoded.params == [address]
        assert encoded.method == "getaddressinfo"
        assert encoded.path == "/"
      end
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = GetAddressInfo.changeset(%GetAddressInfo{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).address
    end

    test "validates address format" do
      # Valid addresses should pass
      for address <- [@valid_legacy_address, @valid_p2sh_address, @valid_bech32_address] do
        changeset = GetAddressInfo.changeset(%GetAddressInfo{}, %{address: address})
        assert changeset.valid?
      end

      # Invalid address should fail
      changeset = GetAddressInfo.changeset(%GetAddressInfo{}, %{address: "invalid"})
      refute changeset.valid?
      assert changeset.errors[:address] != nil
    end

    test "validates address length" do
      # Too short
      short_address = "1abc"
      changeset = GetAddressInfo.changeset(%GetAddressInfo{}, %{address: short_address})
      refute changeset.valid?
      assert "should be at least 26 character(s)" in errors_on(changeset).address

      # Too long
      long_address = String.duplicate("bc1q", 30)
      changeset = GetAddressInfo.changeset(%GetAddressInfo{}, %{address: long_address})
      refute changeset.valid?
      assert "should be at most 90 character(s)" in errors_on(changeset).address

      # Just right
      changeset = GetAddressInfo.changeset(%GetAddressInfo{}, %{address: @valid_bech32_address})
      assert changeset.valid?
    end

    test "validates wallet name length" do
      # Too long
      long_name = String.duplicate("a", 65)

      changeset =
        GetAddressInfo.changeset(%GetAddressInfo{}, %{
          address: @valid_bech32_address,
          wallet_name: long_name
        })

      refute changeset.valid?
      assert "should be at most 64 character(s)" in errors_on(changeset).wallet_name

      # Valid length
      valid_name = String.duplicate("a", 64)

      changeset =
        GetAddressInfo.changeset(%GetAddressInfo{}, %{
          address: @valid_bech32_address,
          wallet_name: valid_name
        })

      assert changeset.valid?
    end

    test "accepts optional wallet_name" do
      changeset =
        GetAddressInfo.changeset(%GetAddressInfo{}, %{
          address: @valid_bech32_address,
          wallet_name: "test_wallet"
        })

      assert changeset.valid?
      assert Changeset.get_change(changeset, :wallet_name) == "test_wallet"
    end
  end

  ## GetAddressInfoResult tests

  describe "GetAddressInfoResult.new/1" do
    test "creates result with required fields" do
      attrs = %{
        "address" => @valid_bech32_address,
        "scriptPubKey" => "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
        "ismine" => true,
        "iswatchonly" => false,
        "solvable" => true,
        "isscript" => false,
        "ischange" => false,
        "iswitness" => true
      }

      assert {:ok, %GetAddressInfoResult{} = result} = GetAddressInfoResult.new(attrs)
      assert result.address == @valid_bech32_address
      assert result.script_pub_key == "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
      assert result.ismine == true
      assert result.iswitness == true
    end

    test "creates result with all fields including witness info" do
      attrs = %{
        "address" => @valid_bech32_address,
        "scriptPubKey" => "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
        "ismine" => true,
        "iswatchonly" => false,
        "solvable" => true,
        "desc" =>
          "wpkh([d34db33f/0'/0'/0']03a34b99f22c790c4e36b2b3c2c35a36db06226e41c692fc82b8b56ac1c540c5bd)#8fhd9pwu",
        "isscript" => false,
        "ischange" => false,
        "iswitness" => true,
        "witness_version" => 0,
        "witness_program" => "389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
        "pubkey" => "03a34b99f22c790c4e36b2b3c2c35a36db06226e41c692fc82b8b56ac1c540c5bd",
        "iscompressed" => true,
        "timestamp" => 1_640_995_200,
        "hdkeypath" => "m/0'/0'/0'",
        "hdseedid" => "d34db33f",
        "hdmasterfingerprint" => "d34db33f",
        "labels" => [""]
      }

      assert {:ok, %GetAddressInfoResult{} = result} = GetAddressInfoResult.new(attrs)
      assert result.witness_version == 0
      assert result.witness_program == "389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
      assert result.iscompressed == true
      assert result.timestamp == 1_640_995_200
      assert result.labels == [""]
    end

    test "creates result for legacy P2PKH address" do
      attrs = %{
        "address" => @valid_legacy_address,
        "scriptPubKey" => "76a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688ac",
        "ismine" => false,
        "iswatchonly" => false,
        "solvable" => true,
        "isscript" => false,
        "ischange" => false,
        "iswitness" => false,
        "labels" => []
      }

      assert {:ok, %GetAddressInfoResult{} = result} = GetAddressInfoResult.new(attrs)
      assert result.address == @valid_legacy_address
      assert result.iswitness == false
      assert result.witness_version == nil
      assert result.labels == []
    end

    test "creates result for multisig P2SH address" do
      attrs = %{
        "address" => @valid_p2sh_address,
        "scriptPubKey" => "a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2687",
        "ismine" => true,
        "iswatchonly" => false,
        "solvable" => true,
        "isscript" => true,
        "ischange" => false,
        "iswitness" => false,
        "script" => "multisig",
        "hex" =>
          "5221033add1f0e8e3c3e5119d0e274283c498d149df99d98ac93724d6a5b3c4c589d0ae5121033b3636a87b7c9bb1a6c17c0f9aee64c3b8b6b87b8a5a7b1c8c5b9b2d6f3a1b2f52ae",
        "pubkeys" => [
          "033add1f0e8e3c3e5119d0e274283c498d149df99d98ac93724d6a5b3c4c589d0ae51",
          "033b3636a87b7c9bb1a6c17c0f9aee64c3b8b6b87b8a5a7b1c8c5b9b2d6f3a1b2f"
        ],
        "sigsrequired" => 2,
        "labels" => []
      }

      assert {:ok, %GetAddressInfoResult{} = result} = GetAddressInfoResult.new(attrs)
      assert result.isscript == true
      assert result.script == "multisig"
      assert result.sigsrequired == 2
      assert length(result.pubkeys) == 2
    end

    test "creates result with embedded address info" do
      embedded_info = %{
        "address" => "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
        "scriptPubKey" => "0014751e76dc81",
        "isscript" => false,
        "iswitness" => true,
        "witness_version" => 0,
        "witness_program" => "751e76dc81"
      }

      attrs = %{
        "address" => @valid_p2sh_address,
        "scriptPubKey" => "a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2687",
        "ismine" => true,
        "iswatchonly" => false,
        "solvable" => true,
        "isscript" => true,
        "ischange" => false,
        "iswitness" => false,
        "script" => "witness_v0_keyhash",
        "embedded" => embedded_info,
        "labels" => []
      }

      assert {:ok, %GetAddressInfoResult{} = result} = GetAddressInfoResult.new(attrs)
      assert result.embedded == embedded_info
      assert result.script == "witness_v0_keyhash"
    end

    test "validates required fields" do
      incomplete_attrs = %{
        "address" => @valid_bech32_address
        # Missing other required fields
      }

      assert {:error, %Changeset{errors: errors}} = GetAddressInfoResult.new(incomplete_attrs)
      assert Keyword.has_key?(errors, :script_pub_key)
      assert Keyword.has_key?(errors, :ismine)
      assert Keyword.has_key?(errors, :solvable)
    end

    test "validates script type when provided" do
      attrs = %{
        "address" => @valid_bech32_address,
        "scriptPubKey" => "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
        "ismine" => true,
        "iswatchonly" => false,
        "solvable" => true,
        "isscript" => true,
        "ischange" => false,
        "iswitness" => true,
        "script" => "invalid_script_type"
      }

      assert {:error, %Changeset{} = changeset} = GetAddressInfoResult.new(attrs)
      assert "is invalid" in errors_on(changeset).script
    end

    test "accepts valid script types" do
      valid_script_types = [
        "nonstandard",
        "pubkey",
        "pubkeyhash",
        "scripthash",
        "multisig",
        "nulldata",
        "witness_v0_keyhash",
        "witness_v0_scripthash",
        "witness_unknown"
      ]

      for script_type <- valid_script_types do
        attrs = %{
          "address" => @valid_bech32_address,
          "scriptPubKey" => "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
          "ismine" => true,
          "iswatchonly" => false,
          "solvable" => true,
          "isscript" => true,
          "ischange" => false,
          "iswitness" => true,
          "script" => script_type
        }

        assert {:ok, %GetAddressInfoResult{script: ^script_type}} = GetAddressInfoResult.new(attrs)
      end
    end
  end

  ## GetAddressInfo RPC

  describe "(RPC) Wallets.get_address_info/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "successful call returns address info for bech32 address", %{client: client} do
      address_info = get_address_info_preset(:bech32)

      mock(fn
        %{method: :post, url: @url, body: body} ->
          # Verify the request body structure
          assert %{
                   "method" => "getaddressinfo",
                   "params" => [@valid_bech32_address],
                   "jsonrpc" => "1.0",
                   "id" => id
                 } = BTx.json_module().decode!(body)

          assert is_binary(id)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => id,
              "result" => address_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetAddressInfoResult{} = result} =
               Wallets.get_address_info(client, address: @valid_bech32_address)

      assert result.address == @valid_bech32_address
      assert result.ismine == true
      assert result.iswitness == true
      assert result.witness_version == 0
      assert result.witness_program == "389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26"
      assert result.labels == [""]
    end

    test "call with wallet name", %{client: client} do
      url = Path.join(@url, "/wallet/my_wallet")
      address_info = get_address_info_preset(:legacy)

      mock(fn
        %{method: :post, url: ^url, body: body} ->
          assert %{
                   "method" => "getaddressinfo",
                   "params" => [@valid_legacy_address],
                   "jsonrpc" => "1.0"
                 } = BTx.json_module().decode!(body)

          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => address_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_address_info(client,
                 address: @valid_legacy_address,
                 wallet_name: "my_wallet"
               )

      assert result.address == @valid_legacy_address
      assert result.ismine == false
      assert result.iswitness == false
    end

    test "call for multisig P2SH address", %{client: client} do
      address_info = get_address_info_preset(:multisig)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => address_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_address_info(client, address: @valid_p2sh_address)

      assert result.isscript == true
      assert result.script == "multisig"
      assert result.sigsrequired == 2
      assert length(result.pubkeys) == 2
      assert result.labels == ["multisig_wallet"]
    end

    test "call for address with embedded witness info", %{client: client} do
      address_info = get_address_info_preset(:embedded_witness)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => address_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_address_info(client, address: @valid_p2sh_address)

      assert result.embedded["address"] == "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
      assert result.script == "witness_v0_keyhash"
    end

    test "call for watch-only address", %{client: client} do
      address_info = get_address_info_preset(:watch_only)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => address_info,
              "error" => nil
            }
          }
      end)

      assert {:ok, result} =
               Wallets.get_address_info(client, address: @valid_bech32_address)

      assert result.ismine == false
      assert result.iswatchonly == true
      assert result.labels == ["watch_only"]
    end

    test "handles response with minimal required fields", %{client: client} do
      # Test with only the required fields
      minimal_data = %{
        "address" => @valid_bech32_address,
        "scriptPubKey" => "0014389ffce9cd9ae88dcc0631e88a821ffdbe9bfe26",
        "ismine" => true,
        "iswatchonly" => false,
        "solvable" => true,
        "isscript" => false,
        "ischange" => false,
        "iswitness" => true
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => minimal_data,
              "error" => nil
            }
          }
      end)

      assert {:ok, %GetAddressInfoResult{} = result} =
               Wallets.get_address_info(client, address: @valid_bech32_address)

      # Required fields should be present
      assert result.address == @valid_bech32_address
      assert result.ismine == true
      assert result.iswitness == true

      # Optional fields should have defaults
      assert result.labels == []
      assert result.pubkeys == []
    end

    test "verifies all address types work", %{client: client} do
      address_types = [
        {@valid_legacy_address, :legacy, false},
        {@valid_p2sh_address, :p2sh, false},
        {@valid_bech32_address, :bech32, true},
        {@valid_testnet_address, :bech32, true},
        {@valid_regtest_address, :bech32, true}
      ]

      for {address, _preset_type, is_witness} <- address_types do
        address_info =
          get_address_info_result_fixture(%{
            "address" => address,
            "iswitness" => is_witness
          })

        mock(fn
          %{method: :post, url: @url, body: body} ->
            # Verify correct parameters are sent
            assert %{
                     "method" => "getaddressinfo",
                     "params" => [^address]
                   } = BTx.json_module().decode!(body)

            %Tesla.Env{
              status: 200,
              body: %{
                "id" => "test-id",
                "result" => address_info,
                "error" => nil
              }
            }
        end)

        assert {:ok, result} = Wallets.get_address_info(client, address: address)
        assert result.address == address
        assert result.iswitness == is_witness
      end
    end

    @tag :integration
    test "real Bitcoin regtest integration" do
      # This test requires a real Bitcoin regtest node running
      real_client = new_client(retry_opts: [max_retries: 10, delay: :timer.seconds(1)])

      # First ensure we have a wallet loaded, create one if needed
      wallet_name =
        Wallets.create_wallet!(
          real_client,
          wallet_name: "address-info-test-#{UUID.generate()}",
          passphrase: "test"
        ).name

      # Get a new address from our wallet
      address = Wallets.get_new_address!(real_client, wallet_name: wallet_name)

      # Get address info
      assert {:ok, %GetAddressInfoResult{} = result} =
               Wallets.get_address_info(
                 real_client,
                 address: address,
                 wallet_name: wallet_name
               )

      # Verify the address info has expected fields
      assert result.address == address
      assert is_binary(result.script_pub_key)
      assert is_boolean(result.ismine)
      assert is_boolean(result.iswatchonly)
      assert is_boolean(result.solvable)
      assert is_boolean(result.isscript)
      assert is_boolean(result.ischange)
      assert is_boolean(result.iswitness)
      assert is_list(result.labels)

      # Since this is our address, it should be ours
      assert result.ismine == true
      assert result.iswatchonly == false
      assert result.solvable == true
    end
  end

  describe "(RPC) Wallets.get_address_info!/3" do
    setup do
      client = new_client(adapter: Tesla.Mock)

      %{client: client}
    end

    test "returns address info result", %{client: client} do
      address_info = get_address_info_preset(:bech32)

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => address_info,
              "error" => nil
            }
          }
      end)

      assert %GetAddressInfoResult{} =
               result = Wallets.get_address_info!(client, address: @valid_bech32_address)

      assert result.address == @valid_bech32_address
      assert result.ismine == true
      assert result.iswitness == true
    end

    test "raises on validation error", %{client: client} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.get_address_info!(client, address: "invalid")
      end
    end

    test "raises on RPC error", %{client: client} do
      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{status: 401, body: "Unauthorized"}
      end)

      assert_raise BTx.RPC.Error, ~r/Unauthorized/, fn ->
        Wallets.get_address_info!(client, address: @valid_bech32_address)
      end
    end

    test "raises on invalid result data", %{client: client} do
      # Invalid result missing required fields
      invalid_info = %{
        "address" => @valid_bech32_address
        # Missing other required fields
      }

      mock(fn
        %{method: :post, url: @url} ->
          %Tesla.Env{
            status: 200,
            body: %{
              "id" => "test-id",
              "result" => invalid_info,
              "error" => nil
            }
          }
      end)

      assert_raise Ecto.InvalidChangesetError, fn ->
        Wallets.get_address_info!(client, address: @valid_bech32_address)
      end
    end
  end
end
