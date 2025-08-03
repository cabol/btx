defmodule BTx.Ecto.Types.DescTimestamp do
  @moduledoc false
  # This type is used to validate the timestamp field in the
  # `ImportDescriptorRequest`.

  use Ecto.Type

  ## Ecto.Type Callbacks

  @impl true
  def type, do: :desc_timestamp

  @impl true
  def cast(n)

  def cast("now") do
    {:ok, "now"}
  end

  def cast(ts) when is_integer(ts) and ts >= 0 do
    {:ok, ts}
  end

  def cast(other) do
    {:error, message: "must be a non-negative integer or \"now\", got: #{inspect(other)}"}
  end

  @impl true
  def dump(value), do: {:ok, value}

  @impl true
  def load(value), do: {:ok, value}
end
