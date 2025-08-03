defmodule BTx.Ecto.Types.DescRange do
  @moduledoc false
  # This type is used to validate the range field in the
  # `ImportDescriptorRequest`.

  use Ecto.Type

  ## Ecto.Type Callbacks

  @impl true
  def type, do: :desc_range

  @impl true
  def cast(n)

  def cast([begin_range, end_range] = range)
      when is_integer(begin_range) and is_integer(end_range) and begin_range <= end_range and
             begin_range >= 0 do
    {:ok, range}
  end

  def cast(n) when is_integer(n) and n >= 0 do
    {:ok, n}
  end

  def cast(other) do
    {:error,
     message: "must be a non-negative integer or array [begin, end], got: #{inspect(other)}"}
  end

  @impl true
  def dump(value), do: {:ok, value}

  @impl true
  def load(value), do: {:ok, value}
end
