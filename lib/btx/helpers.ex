defmodule BTx.Helpers do
  @moduledoc false
  # Helper functions for the BTx library.

  @doc """
  Convenience macro for wrapping the given `exception` into a tuple in the
  shape of `{:error, exception}`.

  ## Example

      iex> import BTx.Helpers
      iex> wrap_error BTx.RPC.Error, id: "1", code: -1, message: "Invalid params"
      {:error, %BTx.RPC.Error{id: "1", code: -32602, message: "Invalid params"}}

  """
  defmacro wrap_error(exception, opts) do
    quote do
      {:error, unquote(exception).exception(unquote(opts))}
    end
  end
end
