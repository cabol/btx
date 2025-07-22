defmodule BTx.Ecto.ChangesetUtils do
  @moduledoc false
  # Changeset utils for the project.

  import Ecto.Changeset

  ## API

  @doc """
  Validates the format of a Bitcoin address.
  """
  @spec valid_address_format(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def valid_address_format(changeset) do
    validate_change(changeset, :address, fn :address, address ->
      # Bitcoin addresses use Base58 (legacy/P2SH) or Bech32 (segwit) character sets
      # This is a basic check - Bitcoin Core will do the comprehensive validation
      if String.match?(address, ~r/^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$/) or
           String.match?(address, ~r/^[a-z0-9]+$/) do
        []
      else
        [address: "is not a valid Bitcoin address"]
      end
    end)
  end
end
