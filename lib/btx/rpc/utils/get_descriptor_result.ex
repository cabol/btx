defmodule BTx.RPC.Utils.GetDescriptorInfoResult do
  @moduledoc """
  Result from the `getdescriptorinfo` JSON RPC API.

  Returns analysis information about a descriptor.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "GetDescriptorInfoResult"
  @type t() :: %__MODULE__{
          descriptor: String.t() | nil,
          checksum: String.t() | nil,
          isrange: boolean() | nil,
          issolvable: boolean() | nil,
          hasprivatekeys: boolean() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :descriptor, :string
    field :checksum, :string
    field :isrange, :boolean
    field :issolvable, :boolean
    field :hasprivatekeys, :boolean
  end

  @optional_fields ~w(descriptor checksum isrange issolvable hasprivatekeys)a

  ## API

  @doc """
  Creates a new `GetDescriptorInfoResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:getdescriptorinfo_result)
  end

  @doc """
  Creates a new `GetDescriptorInfoResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:getdescriptorinfo_result)
  end

  @doc """
  Creates a changeset for the `GetDescriptorInfoResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(attrs, @optional_fields)
  end
end
