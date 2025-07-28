defmodule BTx.RPC.Blockchain.GetBlockchainInfoResult do
  @moduledoc """
  Result from the `getblockchaininfo` JSON RPC API.

  Contains various state information regarding blockchain processing.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.RPC.Blockchain.Commons.Softfork
  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "GetBlockchainInfoResult"
  @type t() :: %__MODULE__{
          chain: String.t() | nil,
          blocks: non_neg_integer() | nil,
          headers: non_neg_integer() | nil,
          bestblockhash: String.t() | nil,
          difficulty: float() | nil,
          mediantime: non_neg_integer() | nil,
          verificationprogress: float() | nil,
          initialblockdownload: boolean() | nil,
          chainwork: String.t() | nil,
          size_on_disk: non_neg_integer() | nil,
          pruned: boolean() | nil,
          pruneheight: non_neg_integer() | nil,
          automatic_pruning: boolean() | nil,
          prune_target_size: non_neg_integer() | nil,
          softforks: map() | nil,
          warnings: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :chain, :string
    field :blocks, :integer
    field :headers, :integer
    field :bestblockhash, :string
    field :difficulty, :float
    field :mediantime, :integer
    field :verificationprogress, :float
    field :initialblockdownload, :boolean
    field :chainwork, :string
    field :size_on_disk, :integer
    field :pruned, :boolean
    field :pruneheight, :integer
    field :automatic_pruning, :boolean
    field :prune_target_size, :integer
    field :softforks, :map
    field :warnings, :string
  end

  @optional_fields ~w(chain blocks headers bestblockhash difficulty mediantime
                      verificationprogress initialblockdownload chainwork
                      size_on_disk pruned pruneheight automatic_pruning
                      prune_target_size softforks warnings)a

  ## API

  @doc """
  Creates a new `GetBlockchainInfoResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:getblockchaininfo_result)
  end

  @doc """
  Creates a new `GetBlockchainInfoResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:getblockchaininfo_result)
  end

  @doc """
  Creates a changeset for the `GetBlockchainInfoResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(attrs, @optional_fields, empty_values: [])
    |> validate_and_cast_softforks()
  end

  ## Private functions

  # Handle the complex softforks field which is a map of softfork name -> softfork data
  defp validate_and_cast_softforks(changeset) do
    case get_field(changeset, :softforks) do
      nil ->
        changeset

      softforks_map when is_map(softforks_map) ->
        case parse_softforks_map(softforks_map) do
          {:ok, parsed_softforks} ->
            put_change(changeset, :softforks, parsed_softforks)

          {:error, _reason} ->
            add_error(changeset, :softforks, "invalid softforks structure")
        end
    end
  end

  # Parse the softforks map, converting each softfork value to a Softfork struct
  defp parse_softforks_map(softforks_map) do
    softforks_map
    |> Enum.reduce_while({:ok, %{}}, fn {name, softfork_attrs}, {:ok, acc} ->
      case Softfork.changeset(%Softfork{}, softfork_attrs) do
        %Ecto.Changeset{valid?: true} = changeset ->
          {:cont, {:ok, Map.put(acc, name, apply_changes(changeset))}}

        %Ecto.Changeset{valid?: false} ->
          {:halt, {:error, "invalid softfork: #{name}"}}
      end
    end)
  end
end
