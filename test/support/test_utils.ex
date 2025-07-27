defmodule BTx.TestUtils do
  @moduledoc false

  alias BTx.RPC
  alias Ecto.Changeset

  @doc """
  Creates a new RPC client for the Bitcoin regtest node.
  """
  @spec new_client(keyword()) :: BTx.RPC.client()
  def new_client(opts \\ []) do
    [
      base_url: "http://localhost:18443/",
      username: "btx-user",
      password: "btx-pass"
    ]
    |> Keyword.merge(opts)
    |> RPC.client()
  end

  @doc """
  Helper function for testing changeset errors
  """
  @spec errors_on(Ecto.Changeset.t()) :: Changeset.traverse_result()
  def errors_on(changeset) do
    Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc false
  defmacro assert_eventually(retries \\ 50, delay \\ 100, expr) do
    quote do
      unquote(__MODULE__).wait_until(unquote(retries), unquote(delay), fn ->
        unquote(expr)
      end)
    end
  end

  @doc false
  def wait_until(retries \\ 50, delay \\ 100, fun)

  def wait_until(1, _delay, fun), do: fun.()

  def wait_until(retries, delay, fun) when retries > 1 do
    fun.()
  rescue
    _ ->
      :ok = Process.sleep(delay)

      wait_until(retries - 1, delay, fun)
  end

  @doc """
  Helper function for testing telemetry events.
  """
  @spec with_telemetry_handler(any(), [atom()], (-> any())) :: any()
  def with_telemetry_handler(handler_id \\ self(), events, fun) do
    :ok =
      :telemetry.attach_many(
        handler_id,
        events,
        &__MODULE__.handle_event/4,
        %{pid: self()}
      )

    fun.()
  after
    :telemetry.detach(handler_id)
  end

  @doc false
  def handle_event(event, measurements, metadata, %{pid: pid}) do
    send(pid, {event, measurements, metadata})
  end

  @doc false
  def deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, left, right) when is_map(left) and is_map(right) do
    deep_merge(left, right)
  end

  defp deep_resolve(_key, _left, right) do
    right
  end
end
