defmodule BTx do
  @moduledoc """
  Documentation for `BTx`.
  """

  ## API

  # Inline common instructions
  @compile {:inline, json_module: 0}

  @doc """
  Returns the JSON module to use for encoding and decoding JSON.
  """
  @spec json_module() :: module()
  if Code.ensure_loaded?(JSON) do
    def json_module, do: JSON

    def json_encoder, do: JSON.Encoder
  else
    def json_module, do: Jason

    def json_encoder, do: Jason.Encoder
  end
end
