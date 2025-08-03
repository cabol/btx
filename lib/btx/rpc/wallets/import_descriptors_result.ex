defmodule BTx.RPC.Wallets.ImportDescriptorsResult do
  @moduledoc """
  Result from the `importdescriptors` JSON RPC API.

  Returns an array of responses with the same size as the input that has
  the execution result for each descriptor import request.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Response
  alias BTx.RPC.Wallets.ImportDescriptorResponse

  ## Types & Schema

  @typedoc "ImportDescriptorsResult"
  @type t() :: %__MODULE__{
          responses: [ImportDescriptorResponse.t()]
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    embeds_many :responses, ImportDescriptorResponse
  end

  ## API

  @doc """
  Creates a new `ImportDescriptorsResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_list(attrs) do
    # The result is an array, so we wrap it in a map with responses key
    %__MODULE__{}
    |> changeset(%{"responses" => attrs})
    |> apply_action(:importdescriptors_result)
  end

  @doc """
  Creates a new `ImportDescriptorsResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_list(attrs) do
    %__MODULE__{}
    |> changeset(%{"responses" => attrs})
    |> apply_action!(:importdescriptors_result)
  end

  @doc """
  Creates a changeset for the `ImportDescriptorsResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(attrs, [])
    |> cast_embed(:responses, with: &ImportDescriptorResponse.changeset/2)
  end
end
