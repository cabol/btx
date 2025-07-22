defmodule BTx.JRPC.Mining.GenerateToAddressTest do
  use ExUnit.Case, async: true

  import BTx.TestUtils

  alias BTx.JRPC.{Encodable, Request}
  alias BTx.JRPC.Mining.GenerateToAddress
  alias Ecto.Changeset

  # Valid Bitcoin addresses for testing
  @valid_legacy_address "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
  @valid_p2sh_address "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
  @valid_bech32_address "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
  @valid_testnet_address "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"
  @valid_regtest_address "bcrt1qw508d6qejxtdg4y5r3zarvary0c5xw7kyuewjq"

  describe "new/1" do
    test "creates a GenerateToAddress with required fields" do
      assert {:ok,
              %GenerateToAddress{
                nblocks: 10,
                address: @valid_bech32_address,
                maxtries: 1_000_000
              }} = GenerateToAddress.new(nblocks: 10, address: @valid_bech32_address)
    end

    test "creates a GenerateToAddress with all parameters" do
      assert {:ok,
              %GenerateToAddress{
                nblocks: 5,
                address: @valid_legacy_address,
                maxtries: 500_000
              }} =
               GenerateToAddress.new(
                 nblocks: 5,
                 address: @valid_legacy_address,
                 maxtries: 500_000
               )
    end

    test "uses default value for maxtries" do
      assert {:ok, %GenerateToAddress{maxtries: 1_000_000}} =
               GenerateToAddress.new(nblocks: 1, address: @valid_bech32_address)
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
        assert {:ok, %GenerateToAddress{address: ^address}} =
                 GenerateToAddress.new(nblocks: 1, address: address)
      end
    end

    test "accepts valid nblocks values" do
      valid_nblocks = [1, 10, 100, 1000]

      for nblocks <- valid_nblocks do
        assert {:ok, %GenerateToAddress{nblocks: ^nblocks}} =
                 GenerateToAddress.new(nblocks: nblocks, address: @valid_bech32_address)
      end
    end

    test "accepts valid maxtries values" do
      valid_maxtries = [1, 100, 1000, 500_000, 1_000_000, 10_000_000]

      for maxtries <- valid_maxtries do
        assert {:ok, %GenerateToAddress{maxtries: ^maxtries}} =
                 GenerateToAddress.new(
                   nblocks: 1,
                   address: @valid_bech32_address,
                   maxtries: maxtries
                 )
      end
    end

    test "returns error for missing nblocks" do
      assert {:error, %Changeset{errors: errors}} =
               GenerateToAddress.new(address: @valid_bech32_address)

      assert Keyword.fetch!(errors, :nblocks) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for missing address" do
      assert {:error, %Changeset{errors: errors}} = GenerateToAddress.new(nblocks: 10)

      assert Keyword.fetch!(errors, :address) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for both missing required fields" do
      assert {:error, %Changeset{errors: errors}} = GenerateToAddress.new(%{})

      assert Keyword.fetch!(errors, :nblocks) == {"can't be blank", [{:validation, :required}]}
      assert Keyword.fetch!(errors, :address) == {"can't be blank", [{:validation, :required}]}
    end

    test "returns error for invalid nblocks values" do
      invalid_nblocks = [0, -1, -10]

      for nblocks <- invalid_nblocks do
        assert {:error, %Changeset{errors: errors}} =
                 GenerateToAddress.new(nblocks: nblocks, address: @valid_bech32_address)

        assert Keyword.fetch!(errors, :nblocks) ==
                 {"must be greater than %{number}",
                  [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}
      end
    end

    test "returns error for invalid maxtries values" do
      invalid_maxtries = [0, -1, -100]

      for maxtries <- invalid_maxtries do
        assert {:error, %Changeset{errors: errors}} =
                 GenerateToAddress.new(
                   nblocks: 1,
                   address: @valid_bech32_address,
                   maxtries: maxtries
                 )

        assert Keyword.fetch!(errors, :maxtries) ==
                 {"must be greater than %{number}",
                  [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}
      end
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
        assert {:error, %Changeset{} = changeset} =
                 GenerateToAddress.new(nblocks: 1, address: address)

        assert changeset.errors[:address] != nil
      end
    end

    test "returns error for address too short" do
      short_address = "1abc"

      assert {:error, %Changeset{} = changeset} =
               GenerateToAddress.new(nblocks: 1, address: short_address)

      assert "should be at least 26 character(s)" in errors_on(changeset).address
    end

    test "returns error for address too long" do
      long_address = String.duplicate("bc1q", 30)

      assert {:error, %Changeset{} = changeset} =
               GenerateToAddress.new(nblocks: 1, address: long_address)

      assert "should be at most 90 character(s)" in errors_on(changeset).address
    end

    test "accepts address at minimum valid length" do
      # Minimum valid Bitcoin address length
      min_address = String.duplicate("1", 26)

      assert {:ok, %GenerateToAddress{address: ^min_address}} =
               GenerateToAddress.new(nblocks: 1, address: min_address)
    end

    test "accepts address at maximum valid length" do
      # Maximum valid Bitcoin address length
      # 90 chars
      max_address = String.duplicate("bc1q", 22) <> "12"

      assert {:ok, %GenerateToAddress{address: ^max_address}} =
               GenerateToAddress.new(nblocks: 1, address: max_address)
    end

    test "returns multiple errors for multiple invalid fields" do
      assert {:error, %Changeset{errors: errors}} =
               GenerateToAddress.new(nblocks: -1, address: "invalid", maxtries: 0)

      assert Keyword.fetch!(errors, :nblocks) ==
               {"must be greater than %{number}",
                [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}

      assert Keyword.fetch!(errors, :maxtries) ==
               {"must be greater than %{number}",
                [{:validation, :number}, {:kind, :greater_than}, {:number, 0}]}

      assert errors[:address] != nil
    end
  end

  describe "new!/1" do
    test "creates a GenerateToAddress with required fields" do
      assert %GenerateToAddress{nblocks: 10, address: @valid_bech32_address} =
               GenerateToAddress.new!(nblocks: 10, address: @valid_bech32_address)
    end

    test "creates a GenerateToAddress with all options" do
      assert %GenerateToAddress{
               nblocks: 5,
               address: @valid_legacy_address,
               maxtries: 500_000
             } =
               GenerateToAddress.new!(
                 nblocks: 5,
                 address: @valid_legacy_address,
                 maxtries: 500_000
               )
    end

    test "raises error for invalid nblocks" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GenerateToAddress.new!(nblocks: 0, address: @valid_bech32_address)
      end
    end

    test "raises error for invalid address" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GenerateToAddress.new!(nblocks: 1, address: "invalid")
      end
    end

    test "raises error for missing required fields" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GenerateToAddress.new!([])
      end
    end

    test "raises error for multiple validation failures" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        GenerateToAddress.new!(nblocks: -1, address: "invalid", maxtries: 0)
      end
    end
  end

  describe "encodable" do
    test "encodes method with required fields only" do
      assert %Request{
               params: [10, @valid_bech32_address, 1_000_000],
               method: "generatetoaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               GenerateToAddress.new!(nblocks: 10, address: @valid_bech32_address)
               |> Encodable.encode()
    end

    test "encodes method with custom maxtries" do
      assert %Request{
               params: [5, @valid_legacy_address, 500_000],
               method: "generatetoaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               GenerateToAddress.new!(
                 nblocks: 5,
                 address: @valid_legacy_address,
                 maxtries: 500_000
               )
               |> Encodable.encode()
    end

    test "encodes method with all address types" do
      addresses = [
        @valid_legacy_address,
        @valid_p2sh_address,
        @valid_bech32_address,
        @valid_testnet_address,
        @valid_regtest_address
      ]

      for address <- addresses do
        encoded =
          GenerateToAddress.new!(nblocks: 1, address: address)
          |> Encodable.encode()

        assert encoded.params == [1, address, 1_000_000]
        assert encoded.method == "generatetoaddress"
        assert encoded.path == "/"
      end
    end

    test "encodes method with minimum values" do
      assert %Request{
               params: [1, @valid_bech32_address, 1],
               method: "generatetoaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               GenerateToAddress.new!(
                 nblocks: 1,
                 address: @valid_bech32_address,
                 maxtries: 1
               )
               |> Encodable.encode()
    end

    test "encodes method with large values" do
      assert %Request{
               params: [1000, @valid_bech32_address, 10_000_000],
               method: "generatetoaddress",
               jsonrpc: "1.0",
               path: "/"
             } =
               GenerateToAddress.new!(
                 nblocks: 1000,
                 address: @valid_bech32_address,
                 maxtries: 10_000_000
               )
               |> Encodable.encode()
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = GenerateToAddress.changeset(%GenerateToAddress{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).nblocks
      assert "can't be blank" in errors_on(changeset).address
    end

    test "validates nblocks is positive" do
      # Valid values
      for nblocks <- [1, 10, 100, 1000] do
        changeset =
          GenerateToAddress.changeset(%GenerateToAddress{}, %{
            nblocks: nblocks,
            address: @valid_bech32_address
          })

        assert changeset.valid?
      end

      # Invalid values
      for nblocks <- [0, -1, -10] do
        changeset =
          GenerateToAddress.changeset(%GenerateToAddress{}, %{
            nblocks: nblocks,
            address: @valid_bech32_address
          })

        refute changeset.valid?
        assert "must be greater than 0" in errors_on(changeset).nblocks
      end
    end

    test "validates maxtries is positive" do
      # Valid values
      for maxtries <- [1, 100, 500_000, 1_000_000] do
        changeset =
          GenerateToAddress.changeset(%GenerateToAddress{}, %{
            nblocks: 1,
            address: @valid_bech32_address,
            maxtries: maxtries
          })

        assert changeset.valid?
      end

      # Invalid values
      for maxtries <- [0, -1, -100] do
        changeset =
          GenerateToAddress.changeset(%GenerateToAddress{}, %{
            nblocks: 1,
            address: @valid_bech32_address,
            maxtries: maxtries
          })

        refute changeset.valid?
        assert "must be greater than 0" in errors_on(changeset).maxtries
      end
    end

    test "validates address format" do
      # Valid addresses should pass
      for address <- [@valid_legacy_address, @valid_p2sh_address, @valid_bech32_address] do
        changeset =
          GenerateToAddress.changeset(%GenerateToAddress{}, %{
            nblocks: 1,
            address: address
          })

        assert changeset.valid?
      end

      # Invalid address should fail
      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 1,
          address: "invalid"
        })

      refute changeset.valid?
      assert changeset.errors[:address] != nil
    end

    test "validates address length" do
      # Too short
      short_address = "1abc"

      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 1,
          address: short_address
        })

      refute changeset.valid?
      assert "should be at least 26 character(s)" in errors_on(changeset).address

      # Too long
      long_address = String.duplicate("bc1q", 30)

      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 1,
          address: long_address
        })

      refute changeset.valid?
      assert "should be at most 90 character(s)" in errors_on(changeset).address

      # Just right
      valid_address = @valid_bech32_address

      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 1,
          address: valid_address
        })

      assert changeset.valid?
    end

    test "accepts valid changeset data" do
      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 10,
          address: @valid_bech32_address,
          maxtries: 500_000
        })

      assert changeset.valid?
      assert Changeset.get_change(changeset, :nblocks) == 10
      assert Changeset.get_change(changeset, :address) == @valid_bech32_address
      assert Changeset.get_change(changeset, :maxtries) == 500_000
    end

    test "uses default value for maxtries when not provided" do
      changeset =
        GenerateToAddress.changeset(%GenerateToAddress{}, %{
          nblocks: 1,
          address: @valid_bech32_address
        })

      assert changeset.valid?

      # Test that default is applied when action is performed
      {:ok, result} =
        GenerateToAddress.new(%{
          nblocks: 1,
          address: @valid_bech32_address
        })

      assert result.maxtries == 1_000_000
    end
  end
end
