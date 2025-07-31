defmodule BTx.RPC.RawTransactions.RawTransaction.Output.Address do
  @moduledoc """
  Represents a Bitcoin address output for the `createrawtransaction`
  JSON RPC API.

  This output type sends Bitcoin to a specific address.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "RawTransactions Address Output"
  @type t() :: %__MODULE__{
          address: String.t() | nil,
          amount: float() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :address, :string
    field :amount, :float
  end

  @required_fields ~w(address amount)a

  ## API

  @doc """
  Creates a changeset for the `Address` output schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(address_output, attrs) do
    address_output
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> valid_address_format(:address)
    |> validate_number(:amount, greater_than: 0)
  end
end

defmodule BTx.RPC.RawTransactions.RawTransaction.Output do
  @moduledoc """
  Represents a raw transaction output for the `createrawtransaction`
  JSON RPC API.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias __MODULE__.Address

  ## Types & Schema

  @typedoc "RawTransactions Data Output"
  @type t() :: %__MODULE__{
          addresses: [Address.t()] | nil,
          data: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    embeds_many :addresses, Address
    field :data, :string
  end

  @optional_fields ~w(data)a

  ## API

  @doc """
  Creates a changeset for the `Output` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(output, attrs) do
    output
    |> cast(attrs, @optional_fields)
    |> cast_embed(:addresses)
    |> validate_hexstring(:data)
  end
end
