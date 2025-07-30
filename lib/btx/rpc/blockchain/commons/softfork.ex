defmodule BTx.RPC.Blockchain.Softfork.Bip9.Statistics do
  @moduledoc """
  Embedded schema for BIP9 softfork statistics.

  Contains numeric statistics about BIP9 signalling for a softfork
  (only present for "started" status).
  """

  use Ecto.Schema

  import Ecto.Changeset

  ## Types & Schema

  @typedoc "Softfork BIP9 Statistics"
  @type t() :: %__MODULE__{
          period: non_neg_integer() | nil,
          threshold: non_neg_integer() | nil,
          elapsed: non_neg_integer() | nil,
          count: non_neg_integer() | nil,
          possible: boolean() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :period, :integer
    field :threshold, :integer
    field :elapsed, :integer
    field :count, :integer
    field :possible, :boolean
  end

  @fields ~w(period threshold elapsed count possible)a

  ## API

  @doc """
  Creates a changeset for the `Statistics` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(statistics, attrs) do
    statistics
    |> cast(attrs, @fields)
  end
end

defmodule BTx.RPC.Blockchain.Softfork.Bip9 do
  @moduledoc """
  Embedded schema for BIP9 softfork information.

  Contains status information for BIP9 softforks (only for "bip9" type).
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Blockchain.Softfork.Bip9.Statistics

  ## Types & Schema

  @typedoc "Softfork BIP9"
  @type t() :: %__MODULE__{
          status: String.t() | nil,
          bit: non_neg_integer() | nil,
          start_time: non_neg_integer() | nil,
          timeout: non_neg_integer() | nil,
          since: non_neg_integer() | nil,
          statistics: Statistics.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :status, :string
    field :bit, :integer
    field :start_time, :integer
    field :timeout, :integer
    field :since, :integer
    embeds_one :statistics, Statistics
  end

  @required_fields ~w(status since)a
  @optional_fields ~w(bit start_time timeout)a

  # Valid BIP9 status values
  @valid_statuses ~w(defined started locked_in active failed)

  ## API

  @doc """
  Creates a changeset for the `Bip9` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(bip9, attrs) do
    bip9
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:statistics)
    |> validate_inclusion(:status, @valid_statuses)
  end
end

defmodule BTx.RPC.Blockchain.Softfork do
  @moduledoc """
  Embedded schema for softfork information.

  Contains information about a specific softfork deployment.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Blockchain.Softfork.Bip9

  ## Types & Schema

  @typedoc "Softfork"
  @type t() :: %__MODULE__{
          type: String.t() | nil,
          bip9: Bip9.t() | nil,
          height: non_neg_integer() | nil,
          active: boolean() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :type, :string
    field :height, :integer
    field :active, :boolean
    embeds_one :bip9, Bip9
  end

  @required_fields ~w(type active)a
  @optional_fields ~w(height)a

  # Valid softfork types
  @valid_types ~w(buried bip9)

  ## API

  @doc """
  Creates a changeset for the `Softfork` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(softfork, attrs) do
    softfork
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:bip9)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, @valid_types)
  end
end
