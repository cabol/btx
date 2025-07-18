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
end
