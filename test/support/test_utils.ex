defmodule BTx.TestUtils do
  @moduledoc false

  alias BTx.JRPC
  alias Ecto.Changeset

  @doc """
  Creates a new JRPC client for the Bitcoin regtest node.
  """
  @spec new_client(keyword()) :: BTx.JRPC.client()
  def new_client(opts \\ []) do
    [
      base_url: "http://localhost:18443/",
      username: "btx-user",
      password: "btx-pass"
    ]
    |> Keyword.merge(opts)
    |> JRPC.client()
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
end
