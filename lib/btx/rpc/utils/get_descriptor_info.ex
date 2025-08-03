defmodule BTx.RPC.Utils.GetDescriptorInfo do
  @moduledoc """
  Analyses a descriptor.

  ## Schema fields (a.k.a "Arguments")

  - `:descriptor` - (required) The descriptor string to analyze.

  See [Bitcoin RPC API Reference `getdescriptorinfo`][getdescriptorinfo].
  [getdescriptorinfo]: https://developer.bitcoin.org/reference/rpc/getdescriptorinfo.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Request

  ## Constants

  @method "getdescriptorinfo"

  ## Types & Schema

  @typedoc "GetDescriptorInfo request"
  @type t() :: %__MODULE__{
          method: String.t(),
          descriptor: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: @method

    # Method fields
    field :descriptor, :string
  end

  @required_fields ~w(descriptor)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          descriptor: descriptor
        }) do
      Request.new(
        method: method,
        path: "/",
        params: [descriptor]
      )
    end
  end

  ## API

  @doc """
  Creates a new `GetDescriptorInfo` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:getdescriptorinfo)
  end

  @doc """
  Creates a new `GetDescriptorInfo` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:getdescriptorinfo)
  end

  @doc """
  Creates a changeset for the `GetDescriptorInfo` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:descriptor, min: 1)
  end
end
