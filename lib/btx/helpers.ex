defmodule BTx.Helpers do
  @moduledoc false
  # Helper functions for the BTx library.

  @doc """
  Convenience macro for wrapping the given `exception` into a tuple in the
  shape of `{:error, exception}`.

  ## Example

      iex> import BTx.Helpers
      iex> wrap_error BTx.RPC.MethodError, id: "1", code: -1, message: "Invalid params"
      {:error, %BTx.RPC.MethodError{id: "1", code: -1, message: "Invalid params"}}

  """
  defmacro wrap_error(exception, opts) do
    quote do
      {:error, unquote(exception).exception(unquote(opts))}
    end
  end

  @doc """
  Trims trailing `nil` values from the given enumerable.

  ## Example

      iex> import BTx.Helpers
      iex> trim_trailing_nil([1, 2, nil, 3, nil, nil, nil])
      [1, 2, nil, 3]

  """
  @spec trim_trailing_nil(Enumerable.t()) :: Enumerable.t()
  def trim_trailing_nil(enum) do
    enum
    |> Enum.reverse()
    |> Enum.drop_while(&is_nil/1)
    |> Enum.reverse()
  end
end
