defmodule BTx.RPC.Wallets.ImportDescriptorRequest do
  @moduledoc """
  Represents a single descriptor import request for the `importdescriptors`
  JSON RPC API.

  This schema describes a descriptor to be imported with its associated metadata.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.Ecto.Types.{DescRange, DescTimestamp}

  ## Types & Schema

  @typedoc "ImportDescriptorRequest"
  @type t() :: %__MODULE__{
          desc: String.t() | nil,
          active: boolean() | nil,
          range: integer() | [integer()] | nil,
          next_index: integer() | nil,
          timestamp: integer() | String.t() | nil,
          internal: boolean() | nil,
          label: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :desc, :string
    field :active, :boolean, default: false
    field :range, DescRange
    field :next_index, :integer
    field :timestamp, DescTimestamp
    field :internal, :boolean, default: false
    field :label, :string, default: ""
  end

  @required_fields ~w(desc timestamp)a
  @optional_fields ~w(active range next_index internal label)a

  ## API

  @doc """
  Creates a changeset for the `ImportDescriptorRequest` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(request, attrs) do
    request
    |> cast(normalize_attrs(attrs), @required_fields ++ @optional_fields, empty_values: [])
    |> validate_required(@required_fields)
    |> validate_length(:desc, min: 1)
    |> validate_number(:next_index, greater_than_or_equal_to: 0)
    |> validate_label()
  end

  @doc """
  Converts a `ImportDescriptorRequest` schema to a map.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = request) do
    request
    |> Map.take(__schema__(:fields))
    |> Map.filter(fn {_key, value} -> not is_nil(value) end)
  end

  ## Private functions

  defp validate_label(changeset) do
    case {get_field(changeset, :internal), get_change(changeset, :label)} do
      {true, label} when is_binary(label) and byte_size(label) > 0 ->
        add_error(changeset, :label, "not allowed when internal=true")

      _ ->
        changeset
    end
  end
end
