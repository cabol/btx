defmodule BTx.RPC.Wallets.ImportDescriptorResponse do
  @moduledoc """
  Represents a single descriptor import response from the `importdescriptors`
  JSON RPC API.

  This schema describes the result of importing a single descriptor.
  """

  use Ecto.Schema

  import Ecto.Changeset

  ## Types & Schema

  @typedoc "ImportDescriptorResponse"
  @type t() :: %__MODULE__{
          success: boolean() | nil,
          warnings: [String.t()],
          error: map() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :success, :boolean
    field :warnings, {:array, :string}, default: []
    field :error, :map
  end

  @optional_fields ~w(success warnings error)a

  ## API

  @doc """
  Creates a changeset for the `ImportDescriptorResponse` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(response, attrs) do
    response
    |> cast(attrs, @optional_fields)
  end
end
