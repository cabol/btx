defmodule BTx.Ecto.Types.Scanning do
  @moduledoc false
  # This type is used to validate the scanning field in the`GetWalletInfoResult`
  # struct. It is not used for any other purpose.

  use Ecto.Type

  ## Ecto.Type Callbacks

  @impl true
  def type, do: :scanning

  @impl true
  def cast(%{"duration" => _, "progress" => _} = value), do: {:ok, value}
  def cast(false), do: {:ok, false}
  def cast(_value), do: {:error, message: "must be a map with scanning details or false"}

  @impl true
  def dump(value), do: {:ok, value}

  @impl true
  def load(value), do: {:ok, value}
end
