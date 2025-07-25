defmodule BTx.Ecto.ChangesetUtils do
  @moduledoc false
  # Changeset utils for the project.

  import Ecto.Changeset

  @bitcoin_address_regex ~r/^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$/
  @bech32_address_regex ~r/^[a-z0-9]+$/

  ## API

  @doc """
  Validates the format of a Bitcoin address.
  """
  @spec valid_address_format(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def valid_address_format(changeset, field \\ :address) do
    changeset
    |> validate_length(field, min: 26, max: 90)
    |> validate_change(field, fn ^field, address ->
      # Bitcoin addresses use Base58 (legacy/P2SH) or Bech32 (segwit) character sets
      # This is a basic check - Bitcoin Core will do the comprehensive validation
      if String.match?(address, @bitcoin_address_regex) or
           String.match?(address, @bech32_address_regex) do
        []
      else
        [address: "is not a valid Bitcoin address"]
      end
    end)
  end

  @doc """
  Validates if a given address is a valid Bitcoin address.

  ## Examples

      iex> BTx.Ecto.ChangesetUtils.valid_address?("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
      true

      iex> BTx.Ecto.ChangesetUtils.valid_address?("bc1q09vm5lfy0j5reeulh4x5752q25uqqvz34hufdl")
      true

  """
  @spec valid_address?(String.t()) :: boolean()
  def valid_address?(address) when is_binary(address) do
    String.length(address) >= 26 and String.length(address) <= 90 and
      (String.match?(address, @bitcoin_address_regex) or
         String.match?(address, @bech32_address_regex))
  end

  @doc """
  Normalizes the attributes of a schema.
  """
  @spec normalize_attrs(map()) :: map()
  def normalize_attrs(attrs) when is_map(attrs) do
    attrs
    |> Enum.map(&normalize_field/1)
    |> Enum.into(%{})
  end

  # Handle field name mapping from Bitcoin Core JSON to our schema
  defp normalize_field({"bip125-replaceable", value}), do: {"bip125_replaceable", value}
  defp normalize_field({"fee reason", value}), do: {"fee_reason", value}
  defp normalize_field({"involvesWatchonly", value}), do: {"involves_watchonly", value}
  defp normalize_field({"scriptPubKey", value}), do: {"script_pub_key", value}
  defp normalize_field({"minimumAmount", value}), do: {"minimum_amount", value}
  defp normalize_field({"maximumAmount", value}), do: {"maximum_amount", value}
  defp normalize_field({"maximumCount", value}), do: {"maximum_count", value}
  defp normalize_field({"minimumSumAmount", value}), do: {"minimum_sum_amount", value}
  defp normalize_field({"redeemScript", value}), do: {"redeem_script", value}
  defp normalize_field({"witnessScript", value}), do: {"witness_script", value}
  defp normalize_field({key, value}), do: {key, value}
end
