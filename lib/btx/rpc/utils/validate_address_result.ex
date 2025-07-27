defmodule BTx.RPC.Utils.ValidateAddressResult do
  @moduledoc """
  Result from the `validateaddress` JSON RPC API.

  Contains information about the validity and properties of a Bitcoin address.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "ValidateAddressResult"
  @type t() :: %__MODULE__{
          isvalid: boolean() | nil,
          address: String.t() | nil,
          script_pub_key: String.t() | nil,
          isscript: boolean() | nil,
          iswitness: boolean() | nil,
          witness_version: non_neg_integer() | nil,
          witness_program: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :isvalid, :boolean
    field :address, :string
    field :script_pub_key, :string
    field :isscript, :boolean
    field :iswitness, :boolean
    field :witness_version, :integer
    field :witness_program, :string
  end

  @required_fields ~w(isvalid)a
  @optional_fields ~w(address script_pub_key isscript iswitness witness_version witness_program)a

  ## API

  @doc """
  Creates a new `ValidateAddressResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action(:validateaddress_result)
  end

  @doc """
  Creates a new `ValidateAddressResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action!(:validateaddress_result)
  end

  @doc """
  Creates a changeset for the `ValidateAddressResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
